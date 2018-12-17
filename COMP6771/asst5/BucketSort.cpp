#include <algorithm>
#include <array>
#include <limits>
#include <type_traits>

#include <assert.h>

#include "BucketSort.h"

namespace {
    // Max bucket size that will be sorted in a single thread. Used to avoid
    // lock contention when bucket sizes get small
    constexpr const size_t SINGLE_THREAD_THRESHOLD = 1000;

    template <typename T>
    class PowersOf10 {
        static constexpr size_t _getSize() noexcept {
            T power = 1;
            size_t size = 1;
            while (std::numeric_limits<T>::max() / 10 > power) {
                power *= 10;
                ++size;
            }
            return size;
        }

        public:
            constexpr PowersOf10() noexcept: _powers() {
                T power = 1;
                for (size_t p = 0; p < size; ++p) {
                    _powers[p] = power;
                    power *= 10;
                }
            }

            constexpr T operator[](uint8_t place) const noexcept {
                return _powers[place];
            }

            static constexpr size_t size = _getSize();

        private:
            T _powers[size];
    };

    constexpr const PowersOf10<unsigned int> _powersOf10;

    constexpr uint8_t _countDigits(unsigned int number) noexcept {
        for (size_t digits = _powersOf10.size; digits > 0; --digits)
            if (number >= _powersOf10[digits - 1])
                return digits;

        // Only occurs for number == 0
        return 1;
    }

    constexpr int8_t _getDigit(unsigned int number, uint8_t place) noexcept {
        // Digit from the left, as per requirements of MSD radix sort

        // Example for 4-digit numbers:
        // 0 => number / 10^3 mod 10
        // 1 => number / 10^2 mod 10
        // 2 => number / 10^1 mod 10
        // 3 => number / 10^0 mod 10
        // 4 => -1

        uint8_t digits = _countDigits(number);
        if (place >= digits)
            return -1;

        number /= _powersOf10[digits - 1 - place];
        return number % 10;
    }
}

void BucketSort::sort(unsigned int numCores) {
    assert(_otherWorkers.empty());
    assert(_waitCount == 0);
    assert(_queue.empty());

    // Add the work to the queue
    _isDone = false;
    _exception = nullptr;
    _workingBuffer.resize(numbersToSort.size());
    _queue.push_back(Work{
        .begin = 0,
        .end = numbersToSort.size(),
        .digitPlace = 0
    });

    // Spawn the other workers
    _numCores = numCores;
    _otherWorkers.reserve(numCores - 1);
    while (_otherWorkers.size() < numCores - 1)
        _otherWorkers.emplace_back([this]() {this->_worker();});

    // Turn ourself into the final worker
    _worker();

    // Wait for all workers to exit
    assert(_isDone);
    assert(_exception || _queue.empty());
    for (auto& worker : _otherWorkers)
        worker.join();
    _otherWorkers.clear();
    assert(_waitCount == 0);

    // Rethrow the exception if it exists
    if (_exception) {
        _queue.clear();
        std::rethrow_exception(std::move(_exception));
    }
}

void BucketSort::_worker() noexcept try {
    // Keep a local queue to avoid contending for the "global" queue lock
    // when our bucket sizes get small. Scoped outside the loop to avoid
    // allocating/deallocating it often
    std::deque<Work> localQueue;

    while (true) {
        {
            std::unique_lock<std::mutex> queueLock(_queueMutex);

            if (_waitCount == _numCores - 1 && _queue.empty()) {
                // Every worker is waiting and there's no more work: we're done
                _isDone = true;
                queueLock.unlock();
                _waitChannel.notify_all();
                return;
            }

            // Wait for work to become available
            ++_waitCount;
            _waitChannel.wait(queueLock, [this]() {return _isDone || !_queue.empty();});
            --_waitCount;

            if (_isDone)
                return;

            localQueue.push_back(_queue.front());
            _queue.pop_front();
        }

        while (!localQueue.empty()) {
            Work work = localQueue.front();
            localQueue.pop_front();

            // We have 11 buckets: one for no digit, and one for each digit

            // Work out the start of each bucket
            std::array<size_t, 12> bucketStarts; // 12th "bucket" merely denotes end-of-buckets
            bucketStarts.fill(0);
            for (size_t n = work.begin; n < work.end; ++n)
                ++bucketStarts[_getDigit(numbersToSort[n], work.digitPlace) + 2];
            for (size_t b = 0; b < bucketStarts.size() - 1; ++b)
                bucketStarts[b + 1] += bucketStarts[b];
            assert(bucketStarts.back() == work.end - work.begin);

            // Copy the numbers to the correct buckets
            std::array<size_t, 12> bucketEnds = bucketStarts;
            for (size_t n = work.begin; n < work.end; ++n) {
                uint8_t digit = _getDigit(numbersToSort[n], work.digitPlace) + 1;
                _workingBuffer[work.begin + bucketEnds[digit]] = numbersToSort[n];
                ++bucketEnds[digit];
            }
            std::copy(
                _workingBuffer.cbegin() + work.begin, _workingBuffer.cbegin() + work.end,
                numbersToSort.begin() + work.begin
            );

            // Enqueue each non-empty-digit bucket as new work
            size_t enqueuedBuckets = 0;
            ++work.digitPlace;
            {
                std::unique_lock<std::mutex> queueLock(_queueMutex, std::defer_lock);
                for (size_t b = 1; b < bucketStarts.size() - 1; ++b) {
                    assert(bucketEnds[b] == bucketStarts[b + 1]);

                    // We can skip buckets that have 1 element or less, since
                    // in that case, it's already sorted
                    if (bucketEnds[b] - bucketStarts[b] <= 1)
                        continue;

                    Work newWork = {
                        .begin = work.begin + bucketStarts[b],
                        .end = work.begin + bucketEnds[b],
                        .digitPlace = work.digitPlace
                    };

                    if (localQueue.empty() || bucketEnds[b] - bucketStarts[b] <= SINGLE_THREAD_THRESHOLD) {
                        // If our local queue is empty, or the bucket size is
                        // below the threshold, queue the work for ourself
                        localQueue.push_back(newWork);
                    } else {
                        // Otherwise push it to the "global" queue
                        if (!queueLock.owns_lock())
                            queueLock.lock();

                        _queue.push_back(newWork);
                        ++enqueuedBuckets;
                    }
                }
            }
            for (size_t b = 0; b < enqueuedBuckets; ++b)
                _waitChannel.notify_one();
        }
    }
} catch (...) {
    // Eeek! Abort all workers
    {
        std::lock_guard<std::mutex> exceptionLock(_exceptionMutex);
        _exception = std::current_exception();
    }

    {
        std::lock_guard<std::mutex> queueLock(_queueMutex);
        _isDone = true;
    }
    _waitChannel.notify_all();
}

#pragma once

#include <atomic>
#include <condition_variable>
#include <exception>
#include <deque>
#include <mutex>
#include <thread>
#include <unordered_set>
#include <vector>

#include <stdint.h>

class BucketSort {
    public:
        std::vector<unsigned int> numbersToSort;
        void sort(unsigned int numCores);

    private:
        void _worker() noexcept;

        struct Work {
            size_t begin, end;
            uint8_t digitPlace;
        };

        std::vector<unsigned int> _workingBuffer;

        size_t _numCores;
        std::vector<std::thread> _otherWorkers;
        std::condition_variable _waitChannel;
        size_t _waitCount = 0;

        std::deque<Work> _queue;
        bool _isDone;
        std::mutex _queueMutex;

        std::exception_ptr _exception;
        std::mutex _exceptionMutex;
};

#pragma once

#include <functional>
#include <deque>

class ScopeGuard {
    public:
        template <typename FnR>
        explicit ScopeGuard(const FnR& revert):
            ScopeGuard([] {}, revert)
        {}

        template <typename FnC, typename FnR>
        ScopeGuard(const FnC& commit, const FnR& revert) try:
            _commit(commit), _revert(revert)
        {} catch (...) {
            revert();
        }

        ~ScopeGuard() {
            if (_revert)
                _revert();
        }

        ScopeGuard(const ScopeGuard&) = delete;
        ScopeGuard& operator=(const ScopeGuard&) = delete;

        ScopeGuard(ScopeGuard&&) = default;
        ScopeGuard& operator=(ScopeGuard&&) = default;

        void commit()  noexcept {
            _commit();

            _commit = [] {};
            _revert = [] {};
        }

    private:
        std::function<void ()> _commit, _revert;
};

class ScopeGuards {
    public:
        ~ScopeGuards()  {
            // Ensure reverse order of destruction
            while (_guards.size())
                _guards.pop_back();
        }

        template <typename FnR>
        void add(const FnR& revert) {
            ScopeGuard guard(revert);
            _guards.emplace_back(std::move(guard));
        }

        template <typename FnC, typename FnR>
        void add(const FnC& commit, const FnR& revert) {
            ScopeGuard guard(commit, revert);
            _guards.emplace_back(std::move(guard));
        }

        void commit() noexcept {
            for (auto& guard : _guards)
                guard.commit();
            _guards.clear();
        }

    private:
        std::deque<ScopeGuard> _guards;
};

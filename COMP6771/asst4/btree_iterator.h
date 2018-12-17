#pragma once

#include <iterator>
#include <type_traits>
#include <cstddef>

#include "btree.h"

template <typename T>
class btree_iterator {
    template <typename U>
    static constexpr bool is_noexcept_compare_v = noexcept(std::declval<U>() < std::declval<U>());

    using Container = btree<std::decay_t<T>>;
    using Node = std::conditional_t<std::is_const<T>::value, const typename Container::Node, typename Container::Node>;
    using Index = decltype(std::declval<Node>().others.begin());

    public:
        using difference_type = std::ptrdiff_t;
        using value_type = std::remove_const_t<T>;
        using pointer = T*;
        using reference = T&;
        using iterator_category = std::bidirectional_iterator_tag;

        btree_iterator() = default;

        btree_iterator(const btree_iterator<T>&) = default;
        btree_iterator(btree_iterator<T>&&) = default;
        btree_iterator<T>& operator=(const btree_iterator<T>&) = default;
        btree_iterator<T>& operator=(btree_iterator<T>&&) = default;

        T& operator*() const noexcept;
        T* operator->() const noexcept;

        template <typename U>
        bool operator==(const btree_iterator<U>& other) const noexcept;
        template <typename U>
        bool operator!=(const btree_iterator<U>& other) const noexcept;

        btree_iterator<T>& operator++() noexcept(is_noexcept_compare_v<typename Container::key_type>);
        btree_iterator<T>& operator--() noexcept(is_noexcept_compare_v<typename Container::key_type>);
        btree_iterator<T> operator++(int) noexcept(is_noexcept_compare_v<typename Container::key_type>);
        btree_iterator<T> operator--(int) noexcept(is_noexcept_compare_v<typename Container::key_type>);

        operator btree_iterator<std::add_const_t<T>>() const noexcept {
            return {_node, _index};
        }

    private:
        btree_iterator(Node* node, Index index) noexcept: _node(node), _index(index) {}

        Node* _node = nullptr;
        Index _index;

        friend Container;
        friend btree_iterator<std::add_const_t<T>>;
        friend btree_iterator<std::remove_const_t<T>>;
};

#include "btree_iterator.tem"

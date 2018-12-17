#pragma once

#include <iterator>
#include <memory>
#include <ostream>
#include <type_traits>
#include <utility>
#include <vector>

#include <cstddef>

template <typename T>
class btree;
template <typename T>
class btree_iterator;

template <typename T>
void swap(btree<T>& a, btree<T>& b) noexcept;

template <typename T>
std::ostream& operator<<(std::ostream& out, const btree<T>& tree);

template <typename T>
class btree {
    static constexpr const size_t DEFAULT_BUCKET_SIZE = 40;

    template <typename U>
    static constexpr bool is_noexcept_compare_v = noexcept(std::declval<U>() < std::declval<U>());

    public:
        using key_type = T;
        using value_type = T;

        using size_type = size_t;
        using difference_type = std::ptrdiff_t;

        using iterator = btree_iterator<T>;
        using const_iterator = btree_iterator<const T>;
        using reverse_iterator = std::reverse_iterator<iterator>;
        using const_reverse_iterator = std::reverse_iterator<const_iterator>;

        explicit btree(size_t bucketSize = DEFAULT_BUCKET_SIZE);

        btree(const btree<T>& other);
        btree<T>& operator=(const btree<T>& other);

        btree(btree<T>&& other) noexcept;
        btree<T>& operator=(btree<T>&& other) noexcept;

        size_t size() const noexcept;
        bool empty() const noexcept;

        iterator begin() noexcept;
        const_iterator begin() const noexcept;
        const_iterator cbegin() const noexcept;

        iterator end() noexcept;
        const_iterator end() const noexcept;
        const_iterator cend() const noexcept;

        reverse_iterator rbegin() noexcept;
        const_reverse_iterator rbegin() const noexcept;
        const_reverse_iterator crbegin() const noexcept;

        reverse_iterator rend() noexcept;
        const_reverse_iterator rend() const noexcept;
        const_reverse_iterator crend() const noexcept;

        iterator find(const key_type& key) noexcept(is_noexcept_compare_v<key_type>);
        const_iterator find(const key_type& key) const noexcept(is_noexcept_compare_v<key_type>);
        iterator lower_bound(const key_type& key) noexcept(is_noexcept_compare_v<key_type>);
        const_iterator lower_bound(const key_type& key) const noexcept(is_noexcept_compare_v<key_type>);

        std::pair<iterator, bool> insert(const key_type& key);

        friend void swap<>(btree<T>& a, btree<T>& b) noexcept;
        friend std::ostream& operator<<<>(std::ostream& out, const btree<T>& tree);

    private:
        std::pair<iterator, bool> _insert(iterator hint, const key_type& key);

        template <typename BTree>
        static auto _lower_bound(BTree& btree, const typename BTree::key_type& key) noexcept(is_noexcept_compare_v<key_type>) -> decltype(btree.lower_bound(key));

        static inline bool _isEqual(const key_type& a, const key_type& b) noexcept(is_noexcept_compare_v<key_type>) {return !(a < b) && !(b < a);}

        struct Node {
            Node* parent = nullptr;
            std::unique_ptr<Node> left;
            std::vector<std::pair<T, std::unique_ptr<Node>>> others;
        };

        std::unique_ptr<Node> _root = std::make_unique<Node>();
        size_t _bucketSize = DEFAULT_BUCKET_SIZE;
        size_t _size = 0;

        friend iterator;
        friend const_iterator;
};

#include "btree.tem"

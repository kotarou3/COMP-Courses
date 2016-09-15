#pragma once

#include <iostream>
#include <map>
#include <memory>
#include <type_traits>
#include <set>
#include <utility>
#include <unordered_map>
#include <unordered_set>

namespace gdwg {

template <typename ...T> using void_t = void;

template <typename T, typename = void>
struct is_hashable : std::false_type {};

template <typename T>
struct is_hashable<T, void_t<
    decltype(std::declval<std::hash<T>>()(std::declval<T>())),
    decltype(std::declval<T>() == std::declval<T>())
>> : std::true_type {};

template <typename T>
constexpr bool is_hashable_v = is_hashable<T>::value;

template <typename NodeLabel, typename EdgeValue>
class Graph {
    // Note: Horribly hacked together and of bad design. Please don't use in
    // production (use boost graphs or LEMON instead). Though graph creation
    // and querying should be fairly fast. Trasversal would be faster if we
    // didn't use smart pointers.

    static_assert(
        (std::is_nothrow_move_constructible<NodeLabel>::value &&
        std::is_nothrow_destructible<NodeLabel>::value) ||
        std::is_same<NodeLabel, std::string>::value, // Work around libstdc++ bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58265
        "gdwg::Graph is not exception safe if destructors or move constructors/assignments throw."
        " noexcept specifiers will also be wrong. Remove at your own peril"
    );
    static_assert(
        (std::is_nothrow_move_constructible<EdgeValue>::value &&
        std::is_nothrow_destructible<EdgeValue>::value) ||
        std::is_same<EdgeValue, std::string>::value, // Work around libstdc++ bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58265
        "gdwg::Graph is not exception safe if destructors or move constructors/assignments throw."
        " noexcept specifiers will also be wrong. Remove at your own peril"
    );

    private:
        // Support using a hashmap instead of an ordered map if the key is
        // hashable
        template <typename Key, typename Value, typename ...Other>
        using Map = std::conditional_t<
            is_hashable_v<Key>,
            std::unordered_map<Key, Value, Other...>,
            std::map<Key, Value, Other...>
        >;

        // Spec wants delete operations to be noexcept, but that's impossible
        // if comparisons aren't noexcept as well, so we need some way to work
        // that out
        template <typename T, bool = is_hashable_v<T>>
        struct is_noexcept_compare;
        template <typename T>
        struct is_noexcept_compare<T, true> {
            static constexpr bool value =
                noexcept(std::hash<T>()(std::declval<T>())) &&
                noexcept(std::declval<T>() == std::declval<T>());
        };
        template <typename T>
        struct is_noexcept_compare<T, false> {
            static constexpr bool value = noexcept(std::declval<T>() < std::declval<T>());
        };

        template <typename T>
        static constexpr bool is_noexcept_compare_v = is_noexcept_compare<T>::value;

        // Sanity check on comparison operators, since throwing comparisons are
        // almost always not intended
        static_assert(
            is_noexcept_compare_v<NodeLabel> ||
            std::is_same<NodeLabel, std::string>::value, // Work around libstdc++ bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58265
            "gdwg::Graph is not exception safe if comparison operators throw."
            " Feel free to remove this assert if that doesn't concern you"
        );
        static_assert(
            is_noexcept_compare_v<EdgeValue> ||
            std::is_same<EdgeValue, std::string>::value, // Work around libstdc++ bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58265
            "gdwg::Graph is not exception safe if comparison operators throw."
            " Feel free to remove this assert if that doesn't concern you"
        );

    public:
        Graph() = default;

        Graph(const Graph& other);
        Graph& operator=(const Graph& other);

        Graph(Graph&& other) = default;
        Graph& operator=(Graph&& other) = default;

        bool addNode(const NodeLabel& label);
        bool addEdge(const NodeLabel& from, const NodeLabel& to, const EdgeValue& value);

        bool replace(const NodeLabel& oldLabel, const NodeLabel& newLabel);
        void mergeReplace(const NodeLabel& oldLabel, const NodeLabel& newLabel);

        void deleteNode(const NodeLabel& node) noexcept(is_noexcept_compare_v<NodeLabel>);
        void deleteEdge(const NodeLabel& from, const NodeLabel& to, const EdgeValue& value) noexcept(is_noexcept_compare_v<NodeLabel> && is_noexcept_compare_v<EdgeValue>);
        void clear() noexcept;

        bool isNode(const NodeLabel& label) const noexcept;
        bool isConnected(const NodeLabel& from, const NodeLabel& to) const;

        void printNodes(std::ostream& out = std::cout) const;
        void printEdges(const NodeLabel& from, std::ostream& out = std::cout) const;

        void begin() const noexcept;
        bool end() const noexcept;
        void next() const noexcept;
        const NodeLabel& value() const noexcept;

    private:
        // Overview of internal graph structure
        // =====================================================================
        // Every node lives as a std::shared_ptr<Node>, and contains an adjacent
        // node list. This list is simply a map of adjacent node label to a set
        // of the edges that connect them, including both in and out edges. The
        // two adjacent nodes will each have an identical copy of the edge.
        //
        // The edge simply stores std::weak_ptr<Node>s of what nodes the edge
        // connects, as well as the value assigned to it.
        //
        // Determining the direction of an edge requires comparing its "from" or
        // "to" properties to the current node.
        //
        // Using pointers to represent nodes and edges is a bad idea IMO. Especially
        // bad are smart pointers, because none of the nodes and edges should "own"
        // each other - the class owns all of them!
        //
        // Graphically (with NodeLabel = std::string, EdgeValue = int)
        // -----------------------------------------------------------
        // ┌──────────┐◀──5──┬──────────┐
        // │ "Node A" │      │ "Node B" │
        // └──────────┴──3──▶└────┬─────┘
        //      ┌───┬──────────┐  2
        //      4   │ "Node C" │◀─┘
        //      └──▶└──────────┘
        //
        // Is represented by:
        // ------------------
        //
        // On the heap somewhere:
        // ╔═════════════════ struct Node ═════════════════╗ ◀─┐
        // ║ Map<NodeLabel, std::set<Edge>> adjacentNodes: ║   │
        // ║      ╔══════════ "Node B" ═══════════╗        ║   │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┤
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┼───┐
        // ║      ║ ║ EdgeValue value: 3        ║ ║        ║   │   │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │   │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │   │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┼───┤
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┤   │
        // ║      ║ ║ EdgeValue value: 5        ║ ║        ║   │   │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │   │
        // ║      ╚═══════════════════════════════╝        ║   │   │
        // ╚═══════════════════════════════════════════════╝   │   │
        //                                                     │   │
        // ╔═════════════════ struct Node ═════════════════╗ ◀─┼───┴┐
        // ║ Map<NodeLabel, std::set<Edge>> adjacentNodes: ║   │    │
        // ║      ╔══════════ "Node A" ═══════════╗        ║   │    │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │    │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┤    │
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┼────┤
        // ║      ║ ║ EdgeValue value: 3        ║ ║        ║   │    │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │    │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │    │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┼────┤
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┤    │
        // ║      ║ ║ EdgeValue value: 5        ║ ║        ║   │    │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │    │
        // ║      ╚═══════════════════════════════╝        ║   │    │
        // ║      ╔══════════ "Node C" ═══════════╗        ║   │    │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │    │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┼────┤
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┼────┼───┐
        // ║      ║ ║ EdgeValue value: 2        ║ ║        ║   │    │   │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │    │   │
        // ║      ╚═══════════════════════════════╝        ║   │    │   │
        // ╚═══════════════════════════════════════════════╝   │    │   │
        //                                                     │    │   │
        // ╔═════════════════ struct Node ═════════════════╗ ◀─┼────┼───┴┐
        // ║ Map<NodeLabel, std::set<Edge>> adjacentNodes: ║   │    │    │
        // ║      ╔══════════ "Node B" ═══════════╗        ║   │    │    │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │    │    │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┼────┤    │
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┼────┼────┤
        // ║      ║ ║ EdgeValue value: 2        ║ ║        ║   │    │    │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │    │    │
        // ║      ╚═══════════════════════════════╝        ║   │    │    │
        // ║      ╔══════════ "Node C" ═══════════╗        ║   │    │    │
        // ║      ║ ╔═══════ struct Edge ═══════╗ ║        ║   │    │    │
        // ║      ║ ║ std::weak_ptr<Node> from: ╫─╫────────╫───┼────┼────┤
        // ║      ║ ║ std::weak_ptr<Node> to: ──╫─╫────────╫───┼────┼────┤
        // ║      ║ ║ EdgeValue value: 4        ║ ║        ║   │    │    │
        // ║      ║ ╚═══════════════════════════╝ ║        ║   │    │    │
        // ║      ╚═══════════════════════════════╝        ║   │    │    │
        // ╚═══════════════════════════════════════════════╝   │    │    │
        //                                                     │    │    │
        // Map<NodeLabel, std::shared_ptr<Node>> _nodes:       │    │    │
        //     "Node A" ───────────────────────────────────────┘    │    │
        //     "Node B" ────────────────────────────────────────────┘    │
        //     "Node C" ─────────────────────────────────────────────────┘
        // =====================================================================

        struct Node;
        struct Edge;

        // Works out what's on the other side of the edge. Takes a set because
        // our internal structure makes it easier that way, and isn't a problem
        // since all the edges in the set will have the same nodes (but possibly
        // different directionality)
        std::shared_ptr<Node> _findOtherNode(const std::shared_ptr<Node>& node, std::set<Edge>& edges) const noexcept;

        // The simple way to delete an edge would be to construct a Edge struct
        // with the (from, to, value) tuple and call std::set::erase() with
        // that, but that involves copying an EdgeValue, which might throw. This
        // helper function avoids that problem, and returns whether it actually
        // deleted something
        bool _deleteEdge(
            std::set<Edge>& edges,
            const std::shared_ptr<Node>& from,
            const std::shared_ptr<Node>& to,
            const EdgeValue& value
        ) noexcept(is_noexcept_compare_v<EdgeValue>);

        struct Edge {
            std::weak_ptr<Node> from, to;
            EdgeValue value;
        };

        // In noexcept() specifiers, we assume it's not hashable
        static_assert(!is_hashable_v<Edge>, "Edge shouldn't be hashable");

        // Would implement hashing as opposed to comparisons, but std::weak_ptr's
        // comparison operators are lacking and we don't want the overhead of
        // converting them to std::shared_ptrs for every comparison
        friend inline bool operator<(const std::weak_ptr<Node>& a, const std::weak_ptr<Node>& b) noexcept {
            return a.owner_before(b);
        }
        friend inline bool operator<(const std::weak_ptr<Node>& a, const std::shared_ptr<Node>& b) noexcept {
            return a.owner_before(b);
        }
        friend inline bool operator<(const Edge& a, const Edge& b) noexcept {
            return std::tie(a.from, a.to, a.value) < std::tie(b.from, b.to, b.value);
        }

        struct Node {
            // Note: Will never contain an empty std::set<Edge>. When deleting
            // the last edge between the two nodes, the entire mapping between
            // the two is also deleted
            Map<NodeLabel, std::set<Edge>> adjacentNodes;
        };

        Map<NodeLabel, std::shared_ptr<Node>> _nodes;

        // For the "fake" iteration functions
        mutable typename decltype(_nodes)::const_iterator _nodesIterator;
};

}

#include "Graph.tem"

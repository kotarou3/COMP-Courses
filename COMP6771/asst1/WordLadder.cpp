#include <exception>
#include <fstream>
#include <iostream>
#include <memory>
#include <queue>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include <boost/algorithm/string.hpp>

#include <cstdio>
#include <cstring>
#include <assert.h>
#include <errno.h>
#include <stdint.h>

#include "gsl/gsl.h"

// Note: Partially reimplemented the (provided) Lexicon class to allow for a
// more efficient implementation of the word ladder. Didn't just modify the
// original implementation because it's some horrible old C++ (pre-C++11) and
// I just didn't want to touch it

// Only implemented the minimal required for this single-purpose program (and
// not create an entire new class) since I doubt it will be used again for
// future projects/assignments (and is not part of the spec)

struct Node {
	char letter;
	bool isEow;
	gsl::span<const Node> children;
};

namespace std {
    // Disallow copying of std::vector<Node> (see bottom of readDawg() for why)

    template<>
    std::vector<Node>::vector(const std::vector<Node>&) = delete;
    template<>
    std::vector<Node>& std::vector<Node>::operator=(const std::vector<Node>&) = delete;
}

std::pair<gsl::span<const Node>, std::vector<Node>> readDawg(const std::string& file) {
    std::unique_ptr<std::FILE, decltype(&std::fclose)> in(std::fopen(file.c_str(), "rb"), std::fclose);
    if (!in)
        throw std::runtime_error("Failed to open " + file + ": " + std::string(std::strerror(errno)));

    size_t startIndex, numBytes;
    uint32_t padding;
    if (std::fscanf(in.get(), "DAWG:%zu:%zu:", &startIndex, &numBytes) != 2 || !startIndex || numBytes < sizeof(padding))
        throw std::runtime_error("Failed to parse " + file + ": Wrong format");
    if (std::fread(&padding, sizeof(padding), 1, in.get()) != 1 || padding != 0)
        throw std::runtime_error("Failed to parse " + file + ": Missing padding");
    --startIndex; // Convert one-indexed to zero-indexed
    numBytes -= sizeof(padding);

    std::vector<uint8_t> buffer(numBytes);
    if (std::fread(buffer.data(), 1, numBytes, in.get()) != numBytes)
        throw std::runtime_error("Failed to read " + file + ": Data truncated");

    // Following is some ugly code to convert the following packed format:
    //
    //     struct PackedNode {
    //         uint32_t childrenIndex:24; // Big Endian; one-indexed into node array
    //                                    // of where this node's children start
    //         uint8_t padding:1;
    //         bool isEow:1;              // End Of Word marker
    //         bool isLastChild:1;        // Last child of the parent nodes
    //         uint8_t ord:5;             // Character ordinal (1 = 'a', 26 = 'z')
    //     };
    //     static_assert(sizeof(PackedNode) == 4);
    //
    // in to something easier to use in C++, though not as space efficient
    //
    // We take advantage of the fact that the graph is topologically sorted
    // such that all children nodes come before their parents' to "load" the
    // following children structure:
    //
    //     // `childrenIndex` is one directly extracted from the parent node
    //     // The following `nodes[...]` are the children of the parent node
    //     assert(nodes[childrenIndex - 1].isLastChild == false);
    //     assert(nodes[childrenIndex    ].isLastChild == false);
    //     assert(nodes[childrenIndex + 1].isLastChild == false);
    //     // ...
    //     assert(nodes[childrenIndex + N].isLastChild == true); // Last child
    //
    // of all the nodes in a single pass into a `gsl::span<const Node>` that can
    // be placed in the parent node for easy access into its children. `const`
    // is used because modifying a DAWG is usually a bad idea

    constexpr const size_t elemSize = 4;
    size_t numNodes = numBytes / elemSize;

    std::vector<Node> nodes;
    nodes.reserve(numNodes);
    std::unordered_map<size_t, size_t> childrenLengths; // children index -> length
    for (size_t n = 0, childrenIndex = 0, childrenLength = 1; n < numNodes; ++n, ++childrenLength) {
        gsl::span<const uint8_t> elemBytes = {&buffer[elemSize * n], 4};

        // Original format has the nodes array as one-indexed, where a zero
        // children index meant the node had no children. For convenience, we
        // make it zero indexed here with the "no children" being (size_t)-1
        size_t thisChildrenIndex = ((elemBytes[0] << 16) | (elemBytes[1] << 8) | elemBytes[2]) - 1;
        gsl::span<const Node> children = {nullptr, 0};
        if (thisChildrenIndex != static_cast<size_t>(-1)) {
            if (childrenLengths.count(thisChildrenIndex) == 0)
                throw std::runtime_error("Failed to parse " + file + ": Invalid node ordering or children index");
            children = {&nodes[thisChildrenIndex], static_cast<ptrdiff_t>(childrenLengths[thisChildrenIndex])};
        }

        nodes.push_back({
            .letter = static_cast<char>((elemBytes[3] & 0b11111) - 1 + 'a'),
            .isEow = static_cast<bool>((elemBytes[3] >> 6) & 1),
            .children = std::move(children)
        });

        bool isLastChild = static_cast<bool>((elemBytes[3] >> 5) & 1);
        if (isLastChild) {
            childrenLengths[childrenIndex] = childrenLength;
            childrenIndex = n + 1;
            childrenLength = 0;
        }
    }

    if (childrenLengths.count(startIndex) == 0)
        throw std::runtime_error("Failed to parse " + file + ": Invalid start index");

    // Since all the `gsl::span<const Node>`s created so far have references
    // inside the `nodes` vector, we can't let it be copied/resized/destroyed
    // or anything else that would invalidate the references. We take advantage
    // of RVO to return it without copying. Copying has been disallowed by the
    // std::vector<Node> specialisation above, but one can still cause a
    // reference invalidation via resizing or deletion. This is where a proper
    // class encapsulating the DAWG would be better, since once can set the
    // member functions so they fix the references, or disallow modification
    // altogether

    return std::make_pair(
        gsl::span<const Node>{&nodes[startIndex], static_cast<ptrdiff_t>(childrenLengths[startIndex])},
        std::move(nodes)
    );
}

bool hasSuffix(const Node& from, const std::string& string) {
    if (string.empty())
        return from.isEow;

    for (const Node& child : from.children)
        if (child.letter == string[0])
            return hasSuffix(child, string.substr(1));
    return false;
}

std::vector<std::string> findAdjacent(const gsl::span<const Node>& dawg, const std::string& string) {
    // Find adjacent strings with the basic optimisation of saving the prefix
    // path in the DAWG between loop iterations. Could be improved further by
    // saving the suffix path as well, but that would require a lot more code
    // and not worth the effort unless we are using very long input strings (DNA?)

    std::vector<std::string> results;
    gsl::span<const Node> currentLayer = dawg;
    gsl::span<const Node> nextLayer = {nullptr, 0};
    size_t curStringIndex = 0;
    while (currentLayer.size() && curStringIndex < string.size()) {
        for (const Node& node : currentLayer) {
            if (node.letter == string[curStringIndex]) {
                nextLayer = node.children;
            } else if (hasSuffix(node, string.substr(curStringIndex + 1))) {
                std::string result = string;
                result[curStringIndex] = node.letter;
                results.push_back(std::move(result));
            }
        }

        currentLayer = nextLayer;
        nextLayer = {nullptr, 0};
        ++curStringIndex;
    }

    return results;
}

int main() try {
    std::string from;
    std::cout << "Enter start word (RETURN to quit): ";
    std::getline(std::cin, from);

    if (from.empty())
        return 0;

    std::string to;
    std::cout << "Enter destination word: ";
    std::getline(std::cin, to);

    // XXX: Hope that they only entered ASCII
    boost::algorithm::to_lower(from);
    boost::algorithm::to_lower(to);

    std::set<std::vector<std::string>> ladders;

    if (from == to) {
        ladders.insert({from, from});
    } else if (from.size() == to.size()) {
        gsl::span<const Node> dawg;
        std::vector<Node> dawgStore;
        std::tie(dawg, dawgStore) = readDawg("EnglishWords.dat");

        std::unordered_map<std::string, size_t> distances = {{from, 0}};
        std::queue<std::vector<std::string>> queue;
        queue.push({from});
        while (!queue.empty()) {
            std::vector<std::string> ladder = std::move(queue.front());
            queue.pop();

            // Don't bother searching more if a shorter ladder has already been found
            if (!ladders.empty() && ladder.size() >= ladders.cbegin()->size())
                continue;

            for (std::string& adjacent : findAdjacent(dawg, ladder.back())) {
                size_t distance;
                if (distances.count(adjacent))
                    distance = distances[adjacent];
                else
                    distance = distances[adjacent] = ladder.size();

                if (adjacent == to) {
                    ladder.emplace_back(std::move(adjacent));
                    ladders.insert(std::move(ladder));
                    break;
                }

                if (distance == ladder.size()) {
                    auto newLadder = ladder;
                    newLadder.emplace_back(std::move(adjacent));
                    queue.push(std::move(newLadder));
                } else if (distance < ladder.size()) {
                    // Already been here at a smaller distance - skip
                    continue;
                } else {
                    // BFS, so this should never happen
                    assert(false);
                }
            }
        }
    }

    if (ladders.empty()) {
        std::cout << "No ladder found.\n";
    } else {
        std::cout << "Found ladder: ";
        for (const auto& ladder : ladders)
            std::cout << boost::algorithm::join(ladder, " ") << "\n";
    }

    return 0;
} catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << "\n";
    return 1;
}

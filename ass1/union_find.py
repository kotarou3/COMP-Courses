import numpy

class UnionFind2D:
    """Union-Find on a 2D grid.
    
    Based on https://www.ics.uci.edu/~eppstein/PADS/UnionFind.py"""

    def __init__(self, shape):
        self.sizes = numpy.zeros(shape, dtype = int)
        self.parents = numpy.zeros(shape, dtype = tuple)

    def __getitem__(self, coord):
        """Find and return the root of the set containing the coordinate."""

        # check for previously unknown value
        if self.parents[coord] == 0:
            self.parents[coord] = coord
            self.sizes[coord] = 1
            return coord

        # find path of values leading to the root
        path = [coord]
        root = self.parents[coord]
        while root != self.parents[root]:
            path.append(root)
            root = self.parents[root]

        # compress the path and return
        for ancestor in path:
            self.parents[ancestor] = root
        return root

    def union(self, *coords):
        """Find the sets containing the coordinates and merge them all."""
        roots = [self[c] for c in coords]
        heaviest = sorted(roots, key = lambda r: self.sizes[r])[-1]

        for root in roots:
            if root != heaviest:
                self.sizes[heaviest] += self.sizes[root]
                self.parents[root] = heaviest

    def getSize(self, y, x):
        """Gets the number of elements in the set containing the coordinate."""

        return self.sizes[self[y, x]]

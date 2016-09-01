#pragma once

#include <initializer_list>
#include <iterator>
#include <ostream>
#include <type_traits>

namespace evec {

class EuclideanVector {
    public:
        using Scalar = double;

        explicit EuclideanVector(size_t dimensions = 1, Scalar initialValues = 0.0);

        template <typename T, typename = std::enable_if_t<std::is_arithmetic<T>::value>>
        EuclideanVector(std::initializer_list<T> list): EuclideanVector(list.begin(), list.end()) {}

        template <typename Iterator, typename = std::enable_if_t<
            std::is_arithmetic<typename std::iterator_traits<Iterator>::value_type>::value
        >>
        EuclideanVector(Iterator begin, Iterator end):
            _normCache(-1.0)
        {
            _dimensions = 0;
            for (auto cur = begin; cur != end; ++cur)
                ++_dimensions;

            _vector = new Scalar[_dimensions];
            auto cur = begin;
            for (size_t d = 0; d < _dimensions; ++d, ++cur)
                _vector[d] = *cur;
        }

        EuclideanVector(const EuclideanVector& other);
        EuclideanVector(EuclideanVector&& other) noexcept;

        ~EuclideanVector();

        EuclideanVector& operator=(const EuclideanVector& other);
        EuclideanVector& operator=(EuclideanVector&& other) noexcept;

        size_t getNumDimensions() const noexcept;
        Scalar getEuclideanNorm() const noexcept;
        EuclideanVector createUnitVector() const;

        // Does bounds checking
        const Scalar& get(size_t dimension) const;
        Scalar& get(size_t dimension);

        // No bounds checking
        const Scalar& operator[](size_t dimension) const noexcept;
        Scalar& operator[](size_t dimension) noexcept;

        EuclideanVector& operator+=(const EuclideanVector& other);
        EuclideanVector& operator-=(const EuclideanVector& other);
        EuclideanVector& operator*=(Scalar other) noexcept;
        EuclideanVector& operator/=(Scalar other) noexcept;

        friend Scalar operator*(const EuclideanVector& a, const EuclideanVector& b);
        friend bool operator==(const EuclideanVector& a, const EuclideanVector& b);
        friend std::ostream& operator<<(std::ostream& a, const EuclideanVector& b);

        // Allow implicit casting to any type that can be constructed with
        // [begin, end) pointers. There's the potential for false positives, but
        // such is the consequence of allowing implicit casting to containers
        template <typename T, typename = std::enable_if_t<std::is_constructible<T, const Scalar*, const Scalar*>::value>>
        operator T() const {
            return T(_vector, _vector + _dimensions);
        }
        template <typename T, typename = std::enable_if_t<std::is_constructible<T, Scalar*, Scalar*>::value>>
        operator T() {
            return T(_vector, _vector + _dimensions);
        }

    private:
        size_t _dimensions;
        Scalar* _vector;

        mutable Scalar _normCache;
};

EuclideanVector operator+(const EuclideanVector& a, const EuclideanVector& b);
EuclideanVector operator-(const EuclideanVector& a, const EuclideanVector& b);
EuclideanVector operator*(const EuclideanVector& a, EuclideanVector::Scalar b);
inline EuclideanVector operator*(EuclideanVector::Scalar a, const EuclideanVector& b) {return b * a;}
EuclideanVector operator/(const EuclideanVector& a, EuclideanVector::Scalar b);

EuclideanVector::Scalar operator*(const EuclideanVector& a, const EuclideanVector& b);

bool operator==(const EuclideanVector& a, const EuclideanVector& b);
inline bool operator!=(const EuclideanVector& a, const EuclideanVector& b) {return !(a == b);}

std::ostream& operator<<(std::ostream& a, const EuclideanVector& b);

}

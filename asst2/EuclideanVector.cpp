#include <stdexcept>
#include <string>
#include <cmath>

#include "EuclideanVector.h"

namespace evec {

EuclideanVector::EuclideanVector(size_t dimensions, Scalar initialValues):
    _dimensions(dimensions)
{
    _vector = new Scalar[_dimensions];
    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] = initialValues;
}

EuclideanVector::EuclideanVector(const EuclideanVector& other):
    _dimensions(other._dimensions)
{
    _vector = new Scalar[_dimensions];
    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] = other._vector[d];
}

EuclideanVector::EuclideanVector(EuclideanVector&& other) noexcept {
    *this = std::move(other);
}

EuclideanVector::~EuclideanVector() {
    delete[] _vector;
}

EuclideanVector& EuclideanVector::operator=(const EuclideanVector& other) {
    EuclideanVector copy(other);

    using std::swap;
    swap(*this, copy);

    return *this;
}

EuclideanVector& EuclideanVector::operator=(EuclideanVector&& other) noexcept {
    if (this != &other) {
        _dimensions = std::move(other._dimensions);
        other._dimensions = 0;

        _vector = std::move(other._vector);
        other._vector = nullptr;
    }


    return *this;
}

size_t EuclideanVector::getNumDimensions() const noexcept {
    return _dimensions;
}

EuclideanVector::Scalar EuclideanVector::getEuclideanNorm() const noexcept {
    return std::sqrt(*this * *this);
}

EuclideanVector EuclideanVector::createUnitVector() const {
    return *this / getEuclideanNorm();
}

const EuclideanVector::Scalar& EuclideanVector::get(size_t dimension) const {
    if (dimension >= _dimensions)
        throw std::out_of_range(std::to_string(dimension) + " is out of range");
    return (*this)[dimension];
}

EuclideanVector::Scalar& EuclideanVector::get(size_t dimension) {
    if (dimension >= _dimensions)
        throw std::out_of_range(std::to_string(dimension) + " is out of range");
    return (*this)[dimension];
}

const EuclideanVector::Scalar& EuclideanVector::operator[](size_t dimension) const noexcept {
    return _vector[dimension];
}

EuclideanVector::Scalar& EuclideanVector::operator[](size_t dimension) noexcept {
    return _vector[dimension];
}

EuclideanVector& EuclideanVector::operator+=(const EuclideanVector& other) {
    if (other._dimensions != _dimensions)
        throw std::domain_error("Addition between vectors of size " + std::to_string(_dimensions) + " and " + std::to_string(other._dimensions) + " is undefined");

    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] += other._vector[d];

    return *this;
}

EuclideanVector& EuclideanVector::operator-=(const EuclideanVector& other) {
    if (other._dimensions != _dimensions)
        throw std::domain_error("Subtraction between vectors of size " + std::to_string(_dimensions) + " and " + std::to_string(other._dimensions) + " is undefined");

    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] -= other._vector[d];

    return *this;
}

EuclideanVector& EuclideanVector::operator*=(Scalar other) noexcept {
    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] *= other;

    return *this;
}

EuclideanVector& EuclideanVector::operator/=(Scalar other) noexcept {
    for (size_t d = 0; d < _dimensions; ++d)
        _vector[d] /= other;

    return *this;
}

EuclideanVector operator+(const EuclideanVector& a, const EuclideanVector& b) {
    EuclideanVector copy(a);
    return copy += b;
}

EuclideanVector operator-(const EuclideanVector& a, const EuclideanVector& b) {
    EuclideanVector copy(a);
    return copy -= b;
}

EuclideanVector::Scalar operator*(const EuclideanVector& a, const EuclideanVector& b) {
    if (a._dimensions != b._dimensions)
        throw std::domain_error("Dot product between vectors of size " + std::to_string(a._dimensions) + " and " + std::to_string(b._dimensions) + " is undefined");

    EuclideanVector::Scalar result = 0;
    for (size_t d = 0; d < a._dimensions; ++d)
        result += a._vector[d] * b._vector[d];
    return result;
}

EuclideanVector operator*(const EuclideanVector& a, EuclideanVector::Scalar b) {
    EuclideanVector copy(a);
    return copy *= b;
}

EuclideanVector operator/(const EuclideanVector& a, EuclideanVector::Scalar b) {
    EuclideanVector copy(a);
    return copy /= b;
}

bool operator==(const EuclideanVector& a, const EuclideanVector& b) {
    if (a._dimensions != b._dimensions)
        return false;

    for (size_t d = 0; d < a._dimensions; ++d)
        if (a._vector[d] != b._vector[d])
            return false;

    return true;
}

std::ostream& operator<<(std::ostream& a, const EuclideanVector& b) {
    a << "[";
    for (size_t d = 0; d < b._dimensions; ++d) {
        a << b._vector[d];
        if (d + 1 < b._dimensions)
            a << " ";
    }
    a << "]";

    return a;
}

}

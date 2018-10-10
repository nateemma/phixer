//
//  Fractional.swift
//
//
// Based on:  https://github.com/JadenGeller/Fractional
//
//

/*The MIT License (MIT)

Copyright (c) 2015 Jaden Geller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */


/***
 
 Swift 3 version


public typealias Fraction = Fractional<Int64>


private func gcd<Number: Integer>(_ lhs: Number, _ rhs: Number) -> Number {
    var lhs = lhs, rhs = rhs
    while rhs != 0 { (lhs, rhs) = (rhs, lhs % rhs) }
    return lhs
}

private func lcm<Number: Integer>(_ lhs: Number, _ rhs: Number) -> Number {
    return lhs * rhs / gcd(lhs, rhs)
}

private func reduce<Number: Integer>(_ numerator: Number, denominator: Number) -> (numerator: Number, denominator: Number) {
    var divisor = gcd(numerator, denominator)
    if divisor < 0 { divisor *= -1 }
    guard divisor != 0 else { return (numerator: numerator, denominator: 0) }
    return (numerator: numerator / divisor, denominator: denominator / divisor)
}

public struct Fractional<Number: Integer> {
    /// The numerator of the fraction.
    public let numerator: Number
    
    /// The (always non-negative) denominator of the fraction.
    public let denominator: Number
    
    fileprivate init(numerator: Number, denominator: Number) {
        var (numerator, denominator) = reduce(numerator, denominator: denominator)
        if denominator < 0 { numerator *= -1; denominator *= -1 }
        
        self.numerator = numerator
        self.denominator = denominator
    }
    
    /// Create an instance initialized to `value`.
    public init(_ value: Number) {
        self.init(numerator: value, denominator: 1)
    }
}

extension Fractional: Equatable {}
public func ==<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Bool {
    return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}

extension Fractional: Comparable {}
public func <<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Bool {
    guard !lhs.isNaN && !rhs.isNaN else { return false }
    guard lhs.isFinite && rhs.isFinite else { return lhs.numerator < rhs.numerator }
    let (lhsNumerator, rhsNumerator, _) = Fractional.commonDenominator(lhs, rhs)
    return lhsNumerator < rhsNumerator
}

extension Fractional: Hashable {
    public var hashValue: Int {
        return numerator.hashValue ^ denominator.hashValue
    }
}

extension Fractional: Strideable {
    fileprivate static func commonDenominator(_ lhs: Fractional, _ rhs: Fractional) -> (lhsNumerator: Number, rhsNumberator: Number, denominator: Number) {
        let denominator = lcm(lhs.denominator, rhs.denominator)
        let lhsNumerator = lhs.numerator * (denominator / lhs.denominator)
        let rhsNumerator = rhs.numerator * (denominator / rhs.denominator)
        
        return (lhsNumerator, rhsNumerator, denominator)
    }
    
    public func advanced(by n: Fractional) -> Fractional {
        let (selfNumerator, nNumerator, commonDenominator) = Fractional.commonDenominator(self, n)
        return Fractional(numerator: selfNumerator + nNumerator, denominator: commonDenominator)
    }
    
    public func distance(to other: Fractional) -> Fractional {
        return other.advanced(by: -self)
    }
}

extension Fractional: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Number) {
        self.init(value)
    }
}

extension Fractional: SignedNumber {}
public prefix func -<Number: Integer>(value: Fractional<Number>) -> Fractional<Number> {
    return Fractional(numerator: -1 * value.numerator, denominator: value.denominator)
}

extension Fractional {
    /// The reciprocal of the fraction.
    public var reciprocal: Fractional {
        get {
            return Fractional(numerator: denominator, denominator: numerator)
        }
    }
    
    /// `true` iff `self` is neither infinite nor NaN
    public var isFinite: Bool {
        return denominator != 0
    }
    
    /// `true` iff the numerator is zero and the denominator is nonzero
    public var isInfinite: Bool {
        return denominator == 0 && numerator != 0
    }
    
    /// `true` iff both the numerator and the denominator are zero
    public var isNaN: Bool {
        return denominator == 0 && numerator == 0
    }
    
    /// The positive infinity.
    public static var infinity: Fractional {
        return 1 / 0
    }
    
    /// Not a number.
    public static var NaN: Fractional {
        return 0 / 0
    }
}

extension Fractional: CustomStringConvertible {
    public var description: String {
        guard !isNaN else { return "NaN" }
        guard !isInfinite else { return (self >= 0 ? "+" : "-") + "Inf" }
        
        switch denominator {
        case 1: return "\(numerator)"
        default: return "\(numerator)/\(denominator)"
        }
    }
}

/// Add `lhs` and `rhs`, returning a reduced result.
public func +<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    guard !lhs.isNaN && !rhs.isNaN else { return .NaN }
    guard lhs.isFinite && rhs.isFinite else {
        switch (lhs >= 0, rhs >= 0) {
        case (false, false): return -.infinity
        case (true, true):   return .infinity
        default:             return .NaN
        }
    }
    return lhs.advanced(by: rhs)
}
public func +=<Number: Integer>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs + rhs
}

/// Subtract `lhs` and `rhs`, returning a reduced result.
public func -<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    return lhs + -rhs
}
public func -=<Number: Integer>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs - rhs
}

/// Multiply `lhs` and `rhs`, returning a reduced result.
public func *<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    let swapped = (Fractional(numerator: lhs.numerator, denominator: rhs.denominator), Fractional(numerator: rhs.numerator, denominator: lhs.denominator))
    return Fractional(numerator: swapped.0.numerator * swapped.1.numerator, denominator: swapped.0.denominator * swapped.1.denominator)
}
public func *=<Number: Integer>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs * rhs
}

/// Divide `lhs` and `rhs`, returning a reduced result.
public func /<Number: Integer>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    return lhs * rhs.reciprocal
}
public func /=<Number: Integer>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs / rhs
}

extension Double {
    /// Create an instance initialized to `value`.
    init<Number: Integer>(_ value: Fractional<Number>) {
        self.init(Double(value.numerator.toIntMax()) / Double(value.denominator.toIntMax()))
    }
}

extension Float {
    /// Create an instance initialized to `value`.
    init<Number: Integer>(_ value: Fractional<Number>) {
        self.init(Float(value.numerator.toIntMax()) / Float(value.denominator.toIntMax()))
    }
}
***/

/************************
 ** Swift 4 version:
 ************************/

//public typealias Fraction = Fractional<Int64>



private func gcd<Number: BinaryInteger>(_ lhs: Number, _ rhs: Number) -> Number {
    var lhs = lhs, rhs = rhs
    while rhs != 0 { (lhs, rhs) = (rhs, lhs % rhs) }
    return lhs
}

private func lcm<Number: BinaryInteger>(_ lhs: Number, _ rhs: Number) -> Number {
    return lhs * rhs / gcd(lhs, rhs)
}

private func reduce<Number: BinaryInteger>(_ numerator: Number, denominator: Number) -> (numerator: Number, denominator: Number) {
    var divisor = gcd(numerator, denominator)
    if divisor < 0 { divisor *= -1 }
    guard divisor != 0 else { return (numerator: numerator, denominator: 0) }
    return (numerator: numerator / divisor, denominator: denominator / divisor)
}



struct Fractional<Number: BinaryInteger>: Comparable {
    /// The numerator of the fraction.
    public let numerator: Number
    
    /// The (always non-negative) denominator of the fraction.
    public let denominator: Number
    
    fileprivate init(numerator: Number, denominator: Number) {
        var (numerator, denominator) = reduce(numerator, denominator: denominator)
        if denominator < 0 { numerator *= -1; denominator *= -1 }
        
        self.numerator = numerator
        self.denominator = denominator
    }
    
    /// Create an instance initialized to `value`.
    public init(_ value: Number) {
        self.init(numerator: value, denominator: 1)
    }
}


extension Double {
    /// Create an instance initialized to `value`.
    init<Number: BinaryInteger>(_ value: Fractional<Number>) {
        self.init(Double(value.numerator) / Double(value.denominator))
    }
}

extension Float {
    /// Create an instance initialized to `value`.
    init<Number: BinaryInteger>(_ value: Fractional<Number>) {
        self.init(Float(value.numerator) / Float(value.denominator))
    }
}


extension Fractional {
    /// The reciprocal of the fraction.
    public var reciprocal: Fractional {
        get {
            return Fractional(numerator: denominator, denominator: numerator)
        }
    }
    
    /// `true` iff `self` is neither infinite nor NaN
    public var isFinite: Bool {
        return denominator != 0
    }
    
    /// `true` iff the numerator is zero and the denominator is nonzero
    public var isInfinite: Bool {
        return denominator == 0 && numerator != 0
    }
    
    /// `true` iff both the numerator and the denominator are zero
    public var isNaN: Bool {
        return denominator == 0 && numerator == 0
    }
    
    /// The positive infinity.
    public static var infinity: Fractional {
        return 1 / 0
    }
    
    /// Not a number.
    public static var NaN: Fractional {
        return 0 / 0
    }
}


    /** Mathematical Operations using fractions **/


/// Add `lhs` and `rhs`, returning a reduced result.
public func +<Number: BinaryInteger>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    guard !lhs.isNaN && !rhs.isNaN else { return .NaN }
    guard lhs.isFinite && rhs.isFinite else {
        switch (lhs >= 0, rhs >= 0) {
        case (false, false): return -.infinity
        case (true, true):   return .infinity
        default:             return .NaN
        }
    }
    return lhs.advanced(by: rhs)
}

public func +=<Number: BinaryInteger>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs + rhs
}

/// Subtract `lhs` and `rhs`, returning a reduced result.
public func -<Number: BinaryInteger>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    return lhs + -rhs
}

public func -=<Number: BinaryInteger>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs - rhs
}

/// Multiply `lhs` and `rhs`, returning a reduced result.
public func *<Number: BinaryInteger>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    let swapped = (Fractional(numerator: lhs.numerator, denominator: rhs.denominator), Fractional(numerator: rhs.numerator, denominator: lhs.denominator))
    return Fractional(numerator: swapped.0.numerator * swapped.1.numerator, denominator: swapped.0.denominator * swapped.1.denominator)
}

public func *=<Number: BinaryInteger>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs * rhs
}

/// Divide `lhs` and `rhs`, returning a reduced result.
public func /<Number: BinaryInteger>(lhs: Fractional<Number>, rhs: Fractional<Number>) -> Fractional<Number> {
    return lhs * rhs.reciprocal
}

public func /=<Number: BinaryInteger>(lhs: inout Fractional<Number>, rhs: Fractional<Number>) {
    lhs = lhs / rhs
}



/** Other protocols **/


extension Fractional: CustomStringConvertible {
    public var description: String {
        guard !isNaN else { return "NaN" }
        guard !isInfinite else { return (self >= 0 ? "+" : "-") + "Inf" }
        
        switch denominator {
        case 1: return "\(numerator)"
        default: return "\(numerator)/\(denominator)"
        }
    }
}



extension Fractional :Printable {
    var description: String { get {
        return value.description
        }
    }
}

extension Fractional :Hashable {
    var hashValue: Int { get {
        return ~Int(value._toBitPattern())
        }
    }
}


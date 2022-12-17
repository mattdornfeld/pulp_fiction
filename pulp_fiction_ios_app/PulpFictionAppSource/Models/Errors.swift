//
//  Errors.swift
//  _idx_build_source_21C0F9E3_ios_min15.0
//
//  Created by Matthew Dornfeld on 9/5/22.
//
import Bow
import Foundation

private extension Error {
    private func baseErrorEquals(_ that: Error) -> Bool {
        let this = self
        return (type(of: this) == type(of: that)) &&
            (this.localizedDescription == that.localizedDescription)
    }

    func equals(_ that: Error) -> Bool {
        let this = self
        switch (this, that) {
        case let (this as PulpFictionError, that as PulpFictionError):
            return this.causeMaybe.equals(that.causeMaybe) &&
                this.baseErrorEquals(that)
        default:
            return this.baseErrorEquals(that)
        }
    }
}

private extension Option where A: Error {
    func equals<B: Error>(_ that: Option<B>) -> Bool {
        let thisCauseMaybe = Option<A>.var()
        let thatCauseMaybe = Option<B>.var()
        return binding(
            thisCauseMaybe <- self,
            thatCauseMaybe <- that,
            yield: thisCauseMaybe.get.equals(thatCauseMaybe.get)
        )^.getOrElse(false)
    }
}

open class PulpFictionError: Error {
    let messageMaybe: Option<String>
    let causeMaybe: Option<Error>

    public init() {
        messageMaybe = Option.none()
        causeMaybe = Option.none()
    }

    public init(_ cause: Error) {
        messageMaybe = Option.none()
        causeMaybe = Option.some(cause)
    }

    public init(_ message: String) {
        messageMaybe = Option.some(message)
        causeMaybe = Option.none()
    }

    public init(_ message: String, _ cause: Error) {
        messageMaybe = Option.some(message)
        causeMaybe = Option.some(cause)
    }

    public static func == (lhs: PulpFictionError, rhs: PulpFictionError) -> Bool {
        lhs.equals(rhs)
    }
}

extension PulpFictionError: LocalizedError {
    public var errorDescription: String? {
        String(describing: self)
            + messageMaybe.map { message in ": " + message }^.getOrElse("")
            + causeMaybe.map { cause in "\ncause: " + cause.localizedDescription }^.getOrElse("")
    }
}

open class PulpFictionStartupError: PulpFictionError, Equatable {
    public static func == (lhs: PulpFictionStartupError, rhs: PulpFictionStartupError) -> Bool {
        lhs.equals(rhs)
    }
}

open class PulpFictionRequestError: PulpFictionError, Equatable {
    public static func == (lhs: PulpFictionRequestError, rhs: PulpFictionRequestError) -> Bool {
        lhs.equals(rhs)
    }
}

class RequestParsingError: PulpFictionRequestError {}

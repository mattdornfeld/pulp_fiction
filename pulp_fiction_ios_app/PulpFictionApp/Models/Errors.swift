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

public class PulpFictionError: Error {
    let causeMaybe: Option<Error>

    init() {
        causeMaybe = Option.none()
    }

    init(_ cause: Error) {
        causeMaybe = Option.some(cause)
    }

    public static func == (lhs: PulpFictionError, rhs: PulpFictionError) -> Bool {
        lhs.equals(rhs)
    }
}

public class PulpFictionStartupError: PulpFictionError {}
public class PulpFictionRequestError: PulpFictionError {}

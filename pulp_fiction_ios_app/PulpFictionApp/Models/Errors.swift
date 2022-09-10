//
//  Errors.swift
//  _idx_build_source_21C0F9E3_ios_min15.0
//
//  Created by Matthew Dornfeld on 9/5/22.
//
import Bow
import Foundation

public class PulpFictionError: Error {
    let cause: Option<Error>

    init() {
        cause = Option.none()
    }

    init(_: Error) {
        cause = Option.none()
    }
}

public class PulpFictionStartupError: PulpFictionError {}

public class PulpFictionRequestError: PulpFictionError {}

public class ErrorConnectingToBackendServer: PulpFictionStartupError {}

public class ErrorInitializingPostCache: PulpFictionStartupError {}

public class ErrorClearingPostCache: PulpFictionStartupError {}

public class ErrorAddingItemToPostCache: PulpFictionRequestError {}

public class ErrorRetrievingPostFromCache: PulpFictionRequestError {}

public class UnrecognizedPostType: PulpFictionRequestError {}

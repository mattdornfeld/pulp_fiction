//
//  PulpFictionClient.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 8/28/22.
//

import Bow
import BowEffects
import Foundation
import GRPC
import NIOCore
import NIOPosix
import protos_pulp_fiction_grpc_swift

public struct BackendMessenger {
    let pulpFictionClientProtocol: PulpFictionClientProtocol
    
    static func create() -> IO<PulpFictionStartupError, BackendMessenger> {
        GrpcUtils.buildTestPulpFictionClientProtocol().mapRight{pulpFictionClientProtocol in
            BackendMessenger(pulpFictionClientProtocol: pulpFictionClientProtocol)
        }
    }
}

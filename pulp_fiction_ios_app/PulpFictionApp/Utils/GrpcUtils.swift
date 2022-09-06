//
//  GrpcUtils.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/5/22.
//

import BowEffects
import Foundation
import GRPC
import NIOCore
import NIOPosix

public enum GrpcUtils {
    private static func buildGrpcChannel() -> IO<PulpFictionStartupError, GRPCChannel> {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        return IO.invoke {
            do {
                return try GRPCChannelPool.with(
                    target: .host("localhost", port: 9000),
                    transportSecurity: .plaintext,
                    eventLoopGroup: group
                )
            } catch {
                throw PulpFictionStartupError.errorConnectingToBackendServer
            }
        }
    }

    static func buildTestPulpFictionClientProtocol() -> IO<PulpFictionStartupError, PulpFictionClientProtocol> {
        return IO.invoke { PulpFictionTestClient() }
    }

    static func buildPulpFictionClientProtocol() -> IO<PulpFictionStartupError, PulpFictionClientProtocol> {
        return buildGrpcChannel()
            .mapRight { grpcChannel in PulpFictionServiceClient(channel: grpcChannel) }
    }
}

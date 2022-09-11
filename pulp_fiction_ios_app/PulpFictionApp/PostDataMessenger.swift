//
//  PostDataMessenger.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/8/22.
//
import Bow
import BowEffects
import Foundation

struct PostDataMessenger {
    let postDataCache: PostDataCache

    static func create() -> IO<PulpFictionStartupError, PostDataMessenger> {
        let postDataCacheIO = IO<PulpFictionStartupError, PostDataCache>.var()

        return binding(
            postDataCacheIO <- PostDataCache.create(),
            yield: PostDataMessenger(
                postDataCache: postDataCacheIO.get
            )
        )^
    }
}

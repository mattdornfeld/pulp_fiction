//
//  PostStore.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/7/22.
//
import Bow
import BowEffects
import Cache
import Foundation

public struct PostDataCache {
    private let cache: Storage<UUID, PostDataOneOf>

    public static func create() -> IO<PulpFictionStartupError, PostDataCache> {
        IO<PulpFictionStartupError, PostDataCache>.invokeAndConvertError({cause in ErrorInitializingPostCache(cause)}) {
            let cache = try Storage<UUID, PostDataOneOf>(
                diskConfig: CacheConfigs.diskConfig,
                memoryConfig: CacheConfigs.memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: PostDataOneOf.self)
            )
            return PostDataCache(cache: cache)
        }
    }
    
    private func getUnsafe(_ postId: UUID) throws -> Option<PostDataOneOf> {
        let postInCache = try cache.existsObject(forKey: postId)
        if !postInCache {
            return Option.none()
        }

        let postDataOneOf = try cache.object(forKey: postId)
        return Option.some(postDataOneOf)
    }
    
    private func putUnsafe(_ postId: UUID, _ postDataOneOf: PostDataOneOf) throws -> Void {
        try cache.setObject(postDataOneOf, forKey: postId)
    }
    
    public func clearCache() -> IO<PulpFictionStartupError, Void> {
        IO<PulpFictionStartupError, Void>.invokeAndConvertError({cause in ErrorClearingPostCache(cause)}) {
            try cache.removeAll()
        }
    }

    public func get(_ postId: UUID) -> IO<PulpFictionRequestError, Option<PostDataOneOf>> {
        IO<PulpFictionRequestError, Option<PostDataOneOf>>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> Option<PostDataOneOf> in
            try getUnsafe(postId)
        }
    }

    public func bulkGet(_ postIds: [UUID]) -> IO<PulpFictionRequestError, [Option<PostDataOneOf>]> {
        IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> [Option<PostDataOneOf>] in
            try postIds.map { postId in
                try getUnsafe(postId)
            }
        }
    }

    private func put(_ postId: UUID, _ postDataOneOf: PostDataOneOf) -> IO<PulpFictionRequestError, Void> {
        IO<PulpFictionRequestError, Void>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try putUnsafe(postId, postDataOneOf)
        }
    }
    
    public func put(_ postId: UUID, _ postData: PostData) -> IO<PulpFictionRequestError, Void> {
        put(postId, postData.toPostDataOneOf())
    }
    
    public func putAll(_ items: [(UUID, PostDataOneOf)]) -> IO<PulpFictionRequestError, Void> {
        IO<PulpFictionRequestError, Void>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try items.forEach { item in
                try putUnsafe(item.0, item.1)
            }
        }
    }
    
    public func putAll(_ items: [(UUID, PostData)]) -> IO<PulpFictionRequestError, Void> {
        putAll(items.map{item in (item.0, item.1.toPostDataOneOf())})
    }
}

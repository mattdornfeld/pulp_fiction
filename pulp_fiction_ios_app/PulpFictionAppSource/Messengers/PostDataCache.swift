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

public class PostDataCache {
    private let cache: Storage<PostUpdateIdentifier, PostDataOneOf>
    private var postIds: Set<PostUpdateIdentifier> = Set()

    public class StartupError: PulpFictionStartupError {}
    public class ErrorInitializingPostCache: StartupError {}
    public class ErrorClearingPostCache: StartupError {}

    public class RequestError: PulpFictionRequestError {}
    public class ErrorListingPostIds: RequestError {}
    public class ErrorRetrievingPostFromCache: RequestError {}
    public class ErrorAddingItemToPostCache: RequestError {}

    init(cache: Storage<PostUpdateIdentifier, PostDataOneOf>) {
        self.cache = cache
        cache.addStorageObserver(self) { _, _, change in
            switch change {
            case let .add(key):
                self.postIds.insert(key)
            case let .remove(key):
                self.postIds.remove(key)
            case .removeAll:
                self.postIds.removeAll()
            case .removeExpired:
                break
            }
        }
    }

    public static func create() -> IO<PulpFictionStartupError, PostDataCache> {
        IO<PulpFictionStartupError, PostDataCache>.invokeAndConvertError({ cause in ErrorInitializingPostCache(cause) }) {
            let cache = try Storage<PostUpdateIdentifier, PostDataOneOf>(
                diskConfig: CacheConfigs.diskConfig,
                memoryConfig: CacheConfigs.memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: PostDataOneOf.self)
            )

            return PostDataCache(cache: cache)
        }
    }

    private func getUnsafe(_ PostUpdateIdentifier: PostUpdateIdentifier) throws -> Option<PostDataOneOf> {
        let postInCache = try cache.existsObject(forKey: PostUpdateIdentifier)
        if !postInCache {
            return Option.none()
        }

        let postDataOneOf = try cache.object(forKey: PostUpdateIdentifier)
        return Option.some(postDataOneOf)
    }

    private func putUnsafe(_ PostUpdateIdentifier: PostUpdateIdentifier, _ postDataOneOf: PostDataOneOf) throws {
        try cache.setObject(postDataOneOf, forKey: PostUpdateIdentifier)
    }

    public func clearCache() -> IO<PulpFictionStartupError, Void> {
        IO<PulpFictionStartupError, Void>.invokeAndConvertError({ cause in ErrorClearingPostCache(cause) }) {
            try self.cache.removeAll()
        }
    }

    public func listPostIdsInCache() -> IO<PulpFictionRequestError, [PostUpdateIdentifier]> {
        IO<PulpFictionRequestError, Set<PostUpdateIdentifier>>.invokeAndConvertError({ cause in ErrorListingPostIds(cause) }) { () -> [PostUpdateIdentifier] in
            Array(self.postIds)
        }
    }

    public func get(_ PostUpdateIdentifier: PostUpdateIdentifier) -> IO<PulpFictionRequestError, Option<PostDataOneOf>> {
        IO<PulpFictionRequestError, Option<PostDataOneOf>>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> Option<PostDataOneOf> in
            try self.getUnsafe(PostUpdateIdentifier)
        }
    }

    public func bulkGet(_ PostUpdateIdentifiers: [PostUpdateIdentifier]) -> IO<PulpFictionRequestError, [Option<PostDataOneOf>]> {
        IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> [Option<PostDataOneOf>] in
            try PostUpdateIdentifiers.map { postId in
                try self.getUnsafe(postId)
            }
        }
    }

    private func put(_ PostUpdateIdentifier: PostUpdateIdentifier, _ postDataOneOf: PostDataOneOf) -> IO<PulpFictionRequestError, Void> {
        IO<PulpFictionRequestError, Void>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try self.putUnsafe(PostUpdateIdentifier, postDataOneOf)
        }
    }

    public func put(_ PostUpdateIdentifier: PostUpdateIdentifier, _ postData: PostData) -> IO<PulpFictionRequestError, PostMetadata> {
        put(PostUpdateIdentifier, postData.toPostDataOneOf())
            .mapRight { () in postData.postMetadata }
    }

    public func put(_ postData: PostData) -> IO<PulpFictionRequestError, PostMetadata> {
        put(postData.postMetadata.postUpdateIdentifier, postData)
    }

    public func putAll(_ items: [(PostUpdateIdentifier, PostData)]) -> IO<PulpFictionRequestError, [PostMetadata]> {
        IO<PulpFictionRequestError, [PostMetadata]>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try items.map { item in
                try self.putUnsafe(item.0, item.1.toPostDataOneOf())
                return item.1.postMetadata
            }
        }
    }
}
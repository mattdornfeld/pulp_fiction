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
    private let cache: Storage<UUID, PostDataOneOf>
    private var postIds: Set<UUID> = Set()
    
    public class StartupError: PulpFictionStartupError {}
    public class ErrorInitializingPostCache: StartupError {}
    public class ErrorClearingPostCache: StartupError {}
    
    public class RequestError: PulpFictionRequestError {}
    public class ErrorListingPostIds: RequestError {}
    public class ErrorRetrievingPostFromCache: RequestError {}
    public class ErrorAddingItemToPostCache: RequestError {}
    
    init(cache: Storage<UUID, PostDataOneOf>) {
        self.cache = cache
        cache.addStorageObserver(self) { observer, storage, change in
          switch change {
          case .add(let key):
              self.postIds.insert(key)
          case .remove(let key):
              self.postIds.remove(key)
          case .removeAll:
              self.postIds.removeAll()
          case .removeExpired:
            break
          }
        }
    }

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
            try self.cache.removeAll()
        }
    }
    
    public func listPostIdsInCache() -> IO<PulpFictionRequestError, [UUID]> {
        IO<PulpFictionRequestError, Set<UUID>>.invokeAndConvertError({ cause in ErrorListingPostIds(cause) }) { () -> [UUID] in
            Array(self.postIds)
        }
    }

    public func get(_ postId: UUID) -> IO<PulpFictionRequestError, Option<PostDataOneOf>> {
        IO<PulpFictionRequestError, Option<PostDataOneOf>>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> Option<PostDataOneOf> in
            try self.getUnsafe(postId)
        }
    }

    public func bulkGet(_ postIds: [UUID]) -> IO<PulpFictionRequestError, [Option<PostDataOneOf>]> {
        IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.invokeAndConvertError({ cause in ErrorRetrievingPostFromCache(cause) }) { () -> [Option<PostDataOneOf>] in
            try postIds.map { postId in
                try self.getUnsafe(postId)
            }
        }
    }

    private func put(_ postId: UUID, _ postDataOneOf: PostDataOneOf) -> IO<PulpFictionRequestError, Void> {
        IO<PulpFictionRequestError, Void>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try self.putUnsafe(postId, postDataOneOf)
        }
    }
    
    public func put(_ postId: UUID, _ postData: PostData) -> IO<PulpFictionRequestError, PostMetadata> {
        put(postId, postData.toPostDataOneOf())
            .mapRight{() in postData.postMetadata}
    }
    
    public func put(_ postData: PostData) -> IO<PulpFictionRequestError, PostMetadata> {
        put(postData.postMetadata.postId, postData)
    }
    
    public func putAll(_ items: [(UUID, PostData)]) -> IO<PulpFictionRequestError, [PostMetadata]> {
        IO<PulpFictionRequestError, [PostMetadata]>.invokeAndConvertError({ cause in ErrorAddingItemToPostCache(cause) }) {
            try items.map{item in
                try self.putUnsafe(item.0, item.1.toPostDataOneOf())
                return item.1.postMetadata
            }
        }
    }
}

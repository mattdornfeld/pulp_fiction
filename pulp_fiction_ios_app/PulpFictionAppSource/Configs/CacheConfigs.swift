//
//  CacheConfigs.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/7/22.
//
import Cache
import Foundation

struct CacheConfigs {
    public static let diskConfig = DiskConfig(
        name: "pulp-fiction-posts",
        expiry: Expiry.seconds(60 * 60 * 24 * 3),
        maxSize: 1000 * 1000 * 500
    )

    public static let memoryConfig = MemoryConfig(
        expiry: Expiry.seconds(60 * 60 * 24),
        totalCostLimit: 1000 * 1000 * 300
    )
}

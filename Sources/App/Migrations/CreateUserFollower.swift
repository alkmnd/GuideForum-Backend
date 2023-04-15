//
//  File.swift
//  
//
//  Created by 1234 on 15.04.2023.
//

import Foundation
import Fluent

struct CreateUserFollower: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserFollower.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("follower_id", .uuid, .required, .references(User.schema, "id"))
            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(UserFollower.schema).delete()
    }
}


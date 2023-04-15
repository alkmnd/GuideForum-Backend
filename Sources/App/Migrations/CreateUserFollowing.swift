//
//  File.swift
//  
//
//  Created by 1234 on 14.04.2023.
//

import Foundation
import Fluent

struct CreateUserFollowing: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserFollowing.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("following_id", .uuid, .required, .references(User.schema, "id"))
            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(UserFollowing.schema).delete()
    }
}

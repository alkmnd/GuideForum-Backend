//
//  File.swift
//  
//
//  Created by 1234 on 12.04.2023.
//

import Foundation
import Fluent

struct CreatePostUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PostUser.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("post_id", .uuid, .required, .references(Post.schema, "id"))
            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(PostUser.schema).delete()
    }
}

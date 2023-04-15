//
//  File.swift
//  
//
//  Created by 1234 on 12.04.2023.
//

import Foundation
import Fluent

struct CreatePost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Post.schema)
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("content", .string, .required)
            .field("creator_id", .uuid, .required, .references(User.schema, "id"))
            .create()
    }
    func revert(on database: Database) async throws {
           try await database.schema(Post.schema).delete()
       }
}

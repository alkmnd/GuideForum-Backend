//
//  File.swift
//  
//
//  Created by 1234 on 10.04.2023.
//

import Foundation
import Fluent
import Vapor

final class Post: Model, Content {
    static let schema = "tutorial_posts"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "content")
    var content: String
    
    @Parent(key: "creator_id")
    var creator: User
    
    init() {}
    
    init(id: UUID? = nil,
         title: String,
         description: String,
         content: String,
         creatorID: UUID) {
        self.id = id
        self.title = title
        self.description = description
        self.$creator.id = creatorID
        self.content = content
    }
    
}

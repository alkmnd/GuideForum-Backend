//
//  File.swift
//  
//
//  Created by 1234 on 12.04.2023.
//

import Foundation
import Fluent
import Vapor

final class PostUser: Model, Content {
    static let schema = "post_users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "post_id")
    var post: Post
    
    init() {
        
    }
    
    init(id: UUID? = nil, userID: UUID, postID: UUID) {
            self.id = id
            self.$user.id = userID
            self.$post.id = postID
        }
}

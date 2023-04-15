//
//  File.swift
//  
//
//  Created by 1234 on 15.04.2023.
//

import Foundation
import Vapor
import Fluent

final class UserFollower: Model, Content {
    static let schema = "user_followers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "follower_id")
    var follower: User
    
    init() {
        
    }
    
    init(id: UUID? = nil, userID: UUID, followerID: UUID) {
            self.id = id
            self.$user.id = userID
            self.$follower.id = followerID
        }
}

//
//  File.swift
//  
//
//  Created by 1234 on 14.04.2023.
//

import Foundation
import Fluent
import Vapor

final class UserFollowing: Model, Content {
    static let schema = "user_followings"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "following_id")
    var following: User
    
    init() {
        
    }
    
    init(id: UUID? = nil, userID: UUID, followingID: UUID) {
            self.id = id
            self.$user.id = userID
            self.$following.id = followingID
        }
}

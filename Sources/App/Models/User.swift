//
//  File.swift
//  
//
//  Created by 1234 on 10.04.2023.
//

import Foundation
import Fluent
import Vapor
import Crypto

final class User: Model, Content, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    init() { }
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
    
    struct Create: Content {
        var name: String
        var email: String
        var password: String
    }
    
    struct Login: Content {
        var email: String
        var password: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(3...))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension User.Login: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

final class UserToken: Model, Content {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "value")
    var value: String
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, value: String) {
        self.id = id
        self.$user.id = userID
        self.value = value
    }
}

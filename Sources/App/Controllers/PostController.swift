//
//  File.swift
//  
//
//  Created by 1234 on 12.04.2023.
//

import Foundation
import Fluent
import Vapor


struct PostController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let posts = routes.grouped("tutorial-posts")
        let protectedPosts = posts.grouped(UserTokenAuthenticator())
        protectedPosts.post("create", use: create)
    }
    
    func create(req: Request) throws -> EventLoopFuture<Post> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(Post.Create.self)
        let post = Post(title: input.title, description: input.description, content: input.content, creatorID: user.id!)
        
        return post.save(on: req.db).map {
            post
        }
    }
}

extension Post {
    struct Create: Content {
        var title: String
        var description: String
        var content: String
    }
    
}

//
//  File.swift
//  
//
//  Created by 1234 on 12.04.2023.
//

import Foundation
import Fluent
import Vapor
import Crypto


struct PostController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let posts = routes.grouped("tutorial-posts")
        let protectedPosts = posts.grouped(UserTokenAuthenticator())
        
        protectedPosts.post("create", use: create)
        protectedPosts.post("add-favourite", use: addPostToFavorite)
        protectedPosts.get("list-favorites", use: listOfFavoritePost)
        protectedPosts.get("list-all", use: listAll)
        protectedPosts.get("list-user-posts", use: listUserPosts)
        protectedPosts.get("list-by-user-id", use: listPostsByUserId)
        protectedPosts.post("delete-from-favorites", use: deletePostFromFavorite)
        protectedPosts.post("delete", use: deletePost)
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
    
    func addPostToFavorite(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(Post.Add.self)
        let post = Post.query(on: req.db)
            .filter(\.$id == input.id)
            .all()
            .flatMapThrowing {
                posts -> Post in
                guard let post = posts.first else {
                    throw Abort(.notFound)
                }
                guard posts.count == 1 else {
                    throw Abort(.notFound)
                }
                return post
            }
        return post.flatMap {
            favoritePost in
            let postUser = PostUser(userID: user.id!, postID: favoritePost.id!)
            return postUser.save(on: req.db)
        }.transform(to: .ok)
        
        
    }
    
    func listOfFavoritePost(req: Request) throws -> EventLoopFuture<[Post.PublicData]> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        return PostUser.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$post)
            .all()
            .flatMapThrowing { posts in
                posts.map { postUser
                    in
                    return Post.PublicData(id: postUser.post.id!, title: postUser.post.title, description: postUser.post.description, content: postUser.post.content)
                }
                
            }
    }
    
    func listAll(req: Request) throws -> EventLoopFuture<[Post.PublicData]> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        return Post.query(on: req.db)
            .filter(\.$creator.$id != user.id!)
            .all().flatMapThrowing { posts in posts.map {
                post in
                return Post.PublicData(id:post.id!,
                                       title: post.title,
                                       description: post.description,
                                       content: post.content) }
                
            }
    }
    
    func listPostsByUserId(req: Request) throws -> EventLoopFuture<[Post.PublicData]> {
        //        guard let user = req.auth.get(User.self) else {
        //            throw Abort(.unauthorized)
        //        }
        
        
        let input = try req.content.decode(User.Add.self)
        
        return Post.query(on: req.db)
            .filter(\.$creator.$id == input.id)
            .all().flatMapThrowing { posts in posts.map {
                post in
                return Post.PublicData(id:post.id!,
                                       title: post.title,
                                       description: post.description,
                                       content: post.content) }
                
            }
    }
    
    func listUserPosts(req: Request) throws -> EventLoopFuture<[Post.PublicData]>{
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        return Post.query(on: req.db)
            .filter(\.$creator.$id == user.id!)
            .all().flatMapThrowing { posts in posts.map {
                post in
                return Post.PublicData(id:post.id!,
                                       title: post.title,
                                       description: post.description,
                                       content: post.content) }
                
            }
    }
    
    func deletePostFromFavorite(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(Post.PostToDelete.self)
        
        return Post.query(on: req.db)
            .filter(\.$id == input.id)
            .filter(\.$creator.$id == user.id!)
            .first()
            .flatMap {
                post in
                if let post = post {
                    return PostUser.query(on: req.db)
                        .filter(\.$user.$id == user.id!)
                        .filter(\.$post.$id == post.id!)
                        .delete()
                        .transform(to: .ok)
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "No such post"))
                }
            }
        
        
        
        
        
    }
    
    func deletePost(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(Post.PostToDelete.self)
        
        return Post.find(input.id, on: req.db)
            .flatMap { foundPost in
                if let post = foundPost, post.$creator.id == user.id {
                    return PostUser.query(on: req.db)
                        .filter(\.$post.$id == post.id!)
                        .delete()
                        .flatMap {
                            return post.delete(on: req.db).transform(to: .ok)
                        }
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "Error: Only the creator can delete post or post not found"))
                }
                
            }
    }
    
}

extension Post {
    
    struct Add: Content {
        var id: UUID
    }
    
    struct Create: Content {
        var title: String
        var description: String
        var content: String
    }
    
    struct PublicData: Content {
        var id: UUID?
        var title: String
        var description: String
        var content: String
    }
    
    struct PostToDelete: Content {
        var id: UUID
    }
    
}

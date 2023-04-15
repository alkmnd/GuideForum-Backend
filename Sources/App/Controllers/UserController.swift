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

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("register", use: register)
        users.post("login", use: login)
        
        let protectedUsers = users.grouped(UserTokenAuthenticator())
        protectedUsers.get("profile", use: getProfile)
        protectedUsers.post("logout", use: logout)
        protectedUsers.get("list", use: listAll)
        protectedUsers.post("add-favorite", use: addFavorite)
        protectedUsers.get("get-by-id", use: getUserInfoById)
        protectedUsers.get("list-favorites", use: listFavorites)
        protectedUsers.get("list-followers", use: listFollowers)
        protectedUsers.post("add-follower", use: addFollower)
    }
    func listFollowers(req: Request) throws -> EventLoopFuture<[User.PublicData]> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        return UserFollower.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$follower)
            .all()
            .flatMapThrowing { followers in
                followers.map { userFollower in
                    print(userFollower.follower.id!)
                    return User.PublicData(id: userFollower.follower.id!, name: userFollower.follower.name, email: userFollower.follower.email)

                }

            }
    }
    
    func addFollower(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(User.Add.self)
        let follower = User.query(on: req.db)
            .filter(\.$id == input.id)
            .all()
            .flatMapThrowing {
                users -> User in
                guard let follower = users.first else {
                    throw Abort(.notFound)
                }
                guard users.count == 1 else {
                    throw Abort(.notFound)
                }
                return follower
            }
        return follower.flatMap {
            follower in
            let newFollower = UserFollower(userID: user.id!, followerID: follower.id!)
            return newFollower.save(on: req.db)
        }.transform(to: .ok)
        
    }
    
        func listFavorites(req: Request) throws -> EventLoopFuture<[User.PublicData]> {
            guard let user = req.auth.get(User.self) else {
                throw Abort(.unauthorized)
            }
            return UserFollowing.query(on: req.db)
                .filter(\.$user.$id == user.id!)
                .with(\.$following)
                .all()
                .flatMapThrowing { favoriteUsers in
                    favoriteUsers.map { favoriteUser in
                        print(favoriteUser.following.id!)
                        return User.PublicData(id: favoriteUser.following.id!, name: favoriteUser.following.name, email: favoriteUser.following.email)
    
                    }
    
                }
    
        }
    
    func getUserInfoById(req: Request) throws -> EventLoopFuture<User.PublicData> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let input = try req.content.decode(User.GetById.self)
        
        return User.query(on: req.db)
            .filter(\.$id == input.id)
            .first().flatMapThrowing { users in users.map {
                userSearch in
                return User.PublicData(id: user.id,
                                       name: user.name,
                                       email: user.email) }!
            }
    }
    
    func addFavorite(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        let input = try req.content.decode(User.Add.self)
        let favoriteUser = User.query(on: req.db)
            .filter(\.$id == input.id)
            .all()
            .flatMapThrowing {
                users -> User in
                guard let favoriteUser = users.first else {
                    throw Abort(.notFound)
                }
                guard users.count == 1 else {
                    throw Abort(.notFound)
                }
                return favoriteUser
            }
        return favoriteUser.flatMap {
            favoriteUser in
            let userFavorite = UserFollowing(userID: user.id!, followingID: favoriteUser.id!)
            return userFavorite.save(on: req.db)
        }.transform(to: .ok)
    }
    
    func listAll(req: Request) throws -> EventLoopFuture<[User.PublicData]> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        return User.query(on: req.db)
            .filter(\.$id != user.id!)
            .all().flatMapThrowing { users in users.map {
                user in
                return User.PublicData(id: user.id,
                                       name: user.name,
                                       email: user.email) }
                
            }
    }
    
    func register(req: Request) throws -> EventLoopFuture<User> {
        try User.Create.validate(content: req)
        let input = try req.content.decode(User.Create.self)
        
        let passwordHash = try Bcrypt.hash(input.password)
        let user = User(name: input.name, email: input.email, passwordHash: passwordHash)
        return user.save(on: req.db).map { user }
    }
    
    func login(req: Request) throws -> EventLoopFuture<UserToken> {
        try User.Login.validate(content: req)
        let input = try req.content.decode(User.Login.self)
        
        return User.query(on: req.db)
            .filter(\.$email == input.email)
            .first()
            .flatMap { user in
                guard let user = user else {
                    return req.eventLoop.future(error: Abort(.unauthorized))
                }
                
                do {
                    if try Bcrypt.verify(input.password, created: user.passwordHash) {
                        let token = try self.generateToken()
                        let userToken = UserToken(userID: user.id!, value: token)
                        return userToken.save(on: req.db).transform(to: userToken)
                    } else {
                        return req.eventLoop.future(error: Abort(.unauthorized))
                    }
                } catch {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }
            }
    }
    
    //     Add the getProfile function in the UsersController
    func getProfile(req: Request) throws -> EventLoopFuture<String> {
        // You can safely access the authenticated user since the middleware has already checked for the token.
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        return req.eventLoop.future(user.name)
    }
    
    // Handler that let user logout (revoke tokens)
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        
        return UserToken.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .delete()
            .transform(to: .ok)
    }
    
    
    // MARK: Private section.
    
    private func generateToken() throws -> String {
        let token = SymmetricKey(size: .bits256)
        let tokenString = token.withUnsafeBytes { body in
            Data(body).base64EncodedString()
        }
        return tokenString
    }
}
    
    
    extension User {
        struct PublicData: Content {
            var id: UUID?
            var name: String
            var email: String
        }
        
        struct ListFavorites: Content {
            
        }
        
        struct Add: Content {
            var id: UUID
        }
        
        struct GetById: Content {
            var id: UUID
        }
        //    struct Profile: Content {
        //
        //    }
    }
    

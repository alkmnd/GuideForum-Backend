//
//  File.swift
//  
//
//  Created by 1234 on 10.04.2023.
//

import Foundation
import Vapor
import Fluent

struct UserTokenAuthenticator: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        UserToken.query(on: request.db)
            .filter(\.$value == bearer.token)
            .with(\.$user)
            .first()
            .map { userToken in
                if let user = userToken?.user {
                    request.auth.login(user)
                }
            }
    }
}

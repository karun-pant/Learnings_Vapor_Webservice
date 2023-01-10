//
//  ImperialController.swift
//
//
//  Created by Karun Pant on 09/01/23.
//

import Vapor
import Fluent
import ImperialGoogle

struct ImperialController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
            fatalError("Google callback URL not set")
        }
        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["profile", "email"],
            completion: processGoogleLogin)
    }
    
    func processGoogleLogin(_ req: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        /// In a real world application, you may want to consider using a flag to separate out users registered on your site vs. logging in with OAuth.
        try Google.getUser(req)
            .flatMap { userInfo in
                User.query(on: req.db)
                    .filter(\.$uName == userInfo.userName)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name,
                                uName: userInfo.userName,
                                password: UUID().uuidString,
                                email: userInfo.email)
                            return user
                                .save(on: req.db)
                                .map {
                                    req.session.authenticate(user)
                                    return req.redirect(to: "/")
                                }
                        }
                        req.session.authenticate(existingUser)
                        return req.eventLoop.future(req.redirect(to: "/"))
                    }
            }
    }
}


extension Google {
    static func getUser(_ req: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: req.accessToken())
        let googleAPI: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return req
            .client
            .get(googleAPI, headers: headers).flatMapThrowing { res in
                guard res.status == .ok else {
                    if res.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try res.content.decode(GoogleUserInfo.self)
        }
    }
}

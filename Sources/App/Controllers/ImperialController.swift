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
    
    func processGoogleLogin(_ request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        /// In a real world application, you may want to consider using a flag to separate out users registered on your site vs. logging in with OAuth.
        try Google.getUser(request)
            .flatMap { userInfo in
                User.query(on: request.db)
                    .filter(\.$uName == userInfo.email)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name,
                                uName: userInfo.email,
                                password: UUID().uuidString)
                            return user
                                .save(on: request.db)
                                .map {
                                    request.session.authenticate(user)
                                    return request.redirect(to: "/")
                                }
                        }
                        request.session.authenticate(existingUser)
                        return request.eventLoop
                            .future(request.redirect(to: "/"))
                    }
            }
    }
}


extension Google {
    static func getUser(_ request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization =
        try BearerAuthorization(token: request.accessToken())
        let googleAPIURL: URI =
        "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return request
            .client
            .get(googleAPIURL, headers: headers)
            .flatMapThrowing { response in
                // 5
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try response.content
                    .decode(GoogleUserInfo.self)
            }
    }
}

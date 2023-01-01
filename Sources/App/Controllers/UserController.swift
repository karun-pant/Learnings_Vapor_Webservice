//
//  UserController.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userReqGroup = routes.grouped("api", "v1", "user")
        userReqGroup.post(use: create)
        userReqGroup.get("all", use: getAll)
        userReqGroup.get("by", ":userID", use: getByID)
    }
    
    func create(_ req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db)
            .map { user }
    }
    func getAll(_ req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db)
            .with(\.$acronyms)
            .all()
    }
    func getByID(_ req: Request) throws -> EventLoopFuture<User> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.badRequest))
    }
}

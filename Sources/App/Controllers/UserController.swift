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
    
    func create(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db)
            .map { user.publicUser }
    }
    func getAll(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db)
            .with(\.$acronyms)
            .all()
            .map { User.publicUsers($0) }
    }
    func getByID(_ req: Request) throws -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.badRequest))
            .map { $0.publicUser }
    }
}

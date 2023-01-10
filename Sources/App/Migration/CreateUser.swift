//
//  CreateUser.swift
//
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit
import Vapor

struct CreateUser: Migration {
    func prepare(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("userName", .string, .required)
            .field("password", .string, .required)
            .field("email", .string)
            .unique(on: "userName")
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

struct CreateAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let pass: String
        do {
            pass = try Bcrypt.hash("password")
        }
        catch {
            return database.eventLoop.future(error: error)
        }
        let user = User(name: "Admin User", uName: "admin", password: pass)
        return user.save(on: database)
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\.$uName == "admin")
            .delete()
    }
}

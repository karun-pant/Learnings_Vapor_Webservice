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
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

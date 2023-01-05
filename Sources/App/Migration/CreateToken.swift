//
//  CreateToken.swift
//
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit
import Vapor

struct CreateToken: Migration {
    func prepare(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field("value", .string, .required)
            .field("userID",
                   .uuid,
                   .required,
                   .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}

//
//  CreateAcronym.swift
//  
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit
import Vapor

struct CreateAcronym: Migration {
    func prepare(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.schema)
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.schema).delete()
    }
}

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
        database.schema(Acronym.v1.schema)
            .id()
            .field(Acronym.v1.short, .string, .required)
            .field(Acronym.v1.long, .string, .required)
            .field(Acronym.v1.userID, .uuid, .required, .references("users", "id"))
            .unique(on: Acronym.v1.short, Acronym.v1.long)
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.schema).delete()
    }
}

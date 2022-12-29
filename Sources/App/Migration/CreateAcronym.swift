//
//  File.swift
//  
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit

struct CreateAcronym: Migration {
    func prepare(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(Acronym.schema)
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(Acronym.schema).delete()
    }
}

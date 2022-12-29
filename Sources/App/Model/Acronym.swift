//
//  Acronym.swift
//  
//
//  Created by Karun Pant on 29/12/22.
//

import Vapor
import FluentKit

final class Acronym: Model, Content {
    
    static let schema: String = "acronyms"
    
    @ID
    var id: UUID?
    
    @Field(key: "short")
    var short: String
    
    @Field(key: "long")
    var long: String
    
    //“An empty initializer as required by Model. Fluent uses this to initialize models returned from database queries.”
    init() {}
    
    // Memberwise init
    init(id: UUID? = nil, short: String, long: String) {
        self.id = id
        self.short = short
        self.long = long
    }
    
}

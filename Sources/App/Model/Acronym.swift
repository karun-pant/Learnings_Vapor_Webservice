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
    
    // Parent child  relationship similar to Foreign key
    @Parent(key: "userID")
    var user: User
    
    //“An empty initializer as required by Model. Fluent uses this to initialize models returned from database queries.”
    init() {}
    
    // Memberwise init
    init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
        self.id = id
        self.short = short
        self.long = long
        self.$user.id = userID
    }
    
}

struct AcronymDTO: Content {
    let short: String
    let long: String
    let userID: UUID
}

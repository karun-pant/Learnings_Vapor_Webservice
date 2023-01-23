//
//  Acronym.swift
//  
//
//  Created by Karun Pant on 29/12/22.
//

import Vapor
import FluentKit

final class Acronym: Model, Content {
    
    enum v1 {
        static let schema = "acronyms"
        static let short = FieldKey(stringLiteral: "short")
        static let long = FieldKey(stringLiteral: "long")
        static let userID = FieldKey(stringLiteral: "userID")
    }
    
    static let schema: String = v1.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v1.short)
    var short: String
    
    @Field(key: v1.long)
    var long: String
    
    // Parent child  relationship similar to Foreign key
    @Parent(key: v1.userID)
    var user: User
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \.$acronym,
              to: \.$category)
    var categories: [Category]
    
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
    let categories: [String]?
    let csrf: String?
    init(short: String,
         long: String,
         categories: [String]? = nil,
         csrf: String? = nil) {
        self.short = short
        self.long = long
        self.categories = categories
        self.csrf = csrf
    }
}

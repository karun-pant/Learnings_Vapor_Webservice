//
//  User.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Vapor
import Fluent

final class User: Model, Content {
    static let schema: String = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "userName")
    var uName: String
    
    @Children(for: \.$user)
    var acronyms: [Acronym]
    
    init() { }
    
    init(id: UUID? = nil, name: String, uName: String) {
        self.id = id
        self.name = name
        self.uName = uName
    }
}

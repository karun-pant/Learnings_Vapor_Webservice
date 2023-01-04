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
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var acronyms: [Acronym]
    
    init() { }
    
    init(id: UUID? = nil,
         name: String,
         uName: String,
         password: String) {
        self.id = id
        self.name = name
        self.uName = uName
        self.password = password
    }
    
    final class Public: Content {
        let name: String
        let uName: String
        let id: UUID?
        init(name: String, uName: String, id: UUID?) {
            self.name = name
            self.uName = uName
            self.id = id
        }
        init(_ user: User) {
            self.name = user.name
            self.uName = user.uName
            self.id = user.id
        }
    }
    
    var publicUser: Public {
        Public(self)
    }
    
    static func publicUsers(_ users: [User]) -> [Public] {
        users.map { Public($0) }
    }
}

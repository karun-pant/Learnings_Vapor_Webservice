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
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "profilePicURL")
    var profilePicURL: String?
    
    @Children(for: \.$user)
    var acronyms: [Acronym]
    
    init() { }
    
    init(id: UUID? = nil,
         name: String,
         uName: String,
         password: String,
         email: String,
         profilePicURL: String? = nil) {
        self.id = id
        self.name = name
        self.uName = uName
        self.password = password
        self.email = email
        self.profilePicURL = profilePicURL
    }
    
    final class Public: Content {
        let name: String
        let uName: String
        let id: UUID?
        let profilePicURL: String?
        init(name: String,
             uName: String,
             id: UUID?,
             profilePicURL: String? = nil) {
            self.name = name
            self.uName = uName
            self.id = id
            self.profilePicURL = profilePicURL
        }
        init(_ user: User) {
            self.name = user.name
            self.uName = user.uName
            self.id = user.id
            self.profilePicURL = user.profilePicURL
        }
    }
    
    var publicUser: Public {
        Public(self)
    }
    
    static func publicUsers(_ users: [User]) -> [Public] {
        users.map { Public($0) }
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey = \User.$uName
    
    static var passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension User: ModelSessionAuthenticatable, ModelCredentialsAuthenticatable {
}

//
//  File.swift
//  
//
//  Created by Karun Pant on 04/01/23.
//

import Vapor
import Fluent

final class Token: Model, Content {
    
    static let schema = "tokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "userID")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil,
         value: String,
         userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
    
    final class Public: Content {
        let value: String
        init(value: String) {
            self.value = value
        }
    }
    var publicToken: Public {
        Public(value: value)
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let value = [UInt8].random(count: 16).base64
        return try Token(value: value, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    typealias User = App.User
    static var valueKey = \Token.$value
    static var userKey = \Token.$user
    
    /// Determines if the token is valid.
    /// Returning true for now, but you might add an expiry date or a revoked property to check in the future.
    var isValid: Bool {
        true
    }
    

}

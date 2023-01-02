//
//  Models+Testable.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

@testable import App
import XCTVapor
import Fluent

extension Application {
    static func configureForTest() throws -> Application {
        let app = Application(.testing)
        try configure(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        return app
    }
}

extension User {
    static let apiBase = "api/v1/user"
    static func createAndSave(name: String = "Test User",
                  userName: String = "TUser",
                  on db: Database) throws -> User {
        let user = User(name: name, uName: userName)
        try user.save(on: db).wait()
        return user
    }
}

extension Acronym {
    enum SampleAcronym: CaseIterable {
        case lol
        case rofl
        case asap
        case ascii
        var short: String {
            switch self {
            case .lol:
                return "LOL"
            case .rofl:
                return "ROFL"
            case .asap:
                return "ASAP"
            case .ascii:
                return "ASCII"
            }
        }
        var long: String {
            switch self {
            case .lol:
                return "Lough out loud"
            case .rofl:
                return "Rolling on the floor lough"
            case .asap:
                return "As soon as possible"
            case .ascii:
                return "American Standard Code for Information Interchange"
            }
        }
        var category: App.Category.SampleCategory {
            switch self {
            case .lol:
                return .slang
            case .rofl:
                return .slang
            case .asap:
                return .office
            case .ascii:
                return .gk
            }
        }
    }
    
    static let apiBase = "api/v1/acronym"
    static func createAndSave(_ sample: SampleAcronym,
                              user: User? = nil,
                              on db: Database) throws -> Acronym {
        let acronymUser: User = try {
            if let user {
                return user
            }
            return try User.createAndSave(on: db)
        }()
        
        let acronym = Acronym(short: sample.short,
                              long: sample.long,
                              userID: acronymUser.id!)
        try acronym.save(on: db).wait()
        return acronym
    }
}

extension App.Category {
    enum SampleCategory: String, CaseIterable {
        case office
        case slang
        case gk
    }
    
    static let apiBase = "api/v1/category"
    static func saveAllSamples(on db: Database) throws {
        let allCategorySamples = App.Category.SampleCategory.allCases
        try allCategorySamples.forEach { sample in
            _ = try App.Category.createAndSave(sample, on: db)
        }
    }
    static func createAndSave(_ sample: SampleCategory,
                              on db: Database) throws -> App.Category {
        let category = Category(name: sample.rawValue)
        try category.save(on: db).wait()
        return category
    }
}

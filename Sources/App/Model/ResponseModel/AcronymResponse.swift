//
//  AcronymResponse.swift
//  
//
//  Created by Karun Pant on 30/12/22.
//

import Vapor

struct AcronymResponse: Content {
    let errorDescription: String?
    let acronyms: [AcronymItem]
    init(errorDescription: String? = nil,
         acronymItems: [AcronymItem] = []) {
        self.errorDescription = errorDescription
        self.acronyms = acronymItems
    }
    init(acronyms: [Acronym]) {
        errorDescription = nil
        var acronymItems: [AcronymItem] = []
        for acronym in acronyms {
            acronymItems.append(AcronymItem(acronym: acronym, eagerLoadedUser: acronym.user))
        }
        self.acronyms = acronymItems
    }
}

struct AcronymItem: Content {
    let id: UUID?
    let short: String
    let long: String
    let displayText: String
    let user: User.Public?
    
    init(acronym: Acronym,
         eagerLoadedUser user: User? = nil) {
        short = acronym.short
        long = acronym.long
        displayText = "'\(acronym.short)' stands for '\(acronym.long)'"
        self.user = user?.publicUser
        id = acronym.id
    }
}

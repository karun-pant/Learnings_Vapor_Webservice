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
         accronyms: [AcronymItem] = []) {
        self.errorDescription = errorDescription
        self.acronyms = accronyms
    }
}

struct AcronymItem: Content {
    let short: String
    let long: String
    let displayText: String
    let user: User?
    
    init(acronym: Acronym,
         eagerLoadedUser user: User? = nil) {
        short = acronym.short
        long = acronym.long
        displayText = "'\(acronym.short)' stands for '\(acronym.long)'"
        self.user = user
    }
}

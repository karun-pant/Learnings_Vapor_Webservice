//
//  AcronymResponse.swift
//  
//
//  Created by Karun Pant on 30/12/22.
//

import Vapor

struct AcronymResponse: Content {
    let errorDescription: String?
    let accronyms: [AcronymItem]
    init(errorDescription: String? = nil,
         accronyms: [AcronymItem] = []) {
        self.errorDescription = errorDescription
        self.accronyms = accronyms
    }
}

struct AcronymItem: Content {
    let short: String
    let long: String
    let displayText: String
    let user: User?
    
    init(acronym: Acronym) {
        short = acronym.short
        long = acronym.long
        displayText = "'\(acronym.short)' stands for '\(acronym.long)'"
        self.user = acronym.user
    }
}

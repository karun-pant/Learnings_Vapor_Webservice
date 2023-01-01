//
//  AcronymCategoryPivot.swift
//  
//
//  Created by Karun Pant on 01/01/23.
//

import Vapor
import Fluent

final class AcronymCategoryPivot: Model {
    static let schema: String = "acronym-category-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "acronymID")
    var acronym: Acronym
    
    @Parent(key: "categoryID")
    var category: Category
    
    init() { }
    
    init(id: UUID? = nil,
         acronym: Acronym,
         category: Category) {
        self.id = id
        self.acronym = acronym
        self.category = category
    }
}

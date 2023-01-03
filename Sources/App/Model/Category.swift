//
//  Category.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Vapor
import Fluent

final class Category: Model, Content {
    static let schema = "categories"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \.$category,
              to: \.$acronym)
    var acronyms: [Acronym]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Category {
    static func attachCategory(name: String,
                               to acronym: Acronym,
                               on req: Request) -> EventLoopFuture<Void> {
        return Category.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { category in
                if let existingCategory = category {
                    return acronym.$categories.attach(existingCategory, on: req.db)
                } else {
                    // make a category then attach
                    let category = Category(name: name)
                    return category.save(on: req.db).flatMap {
                        acronym.$categories.attach(category, on: req.db)
                    }
                }
            }
    }
}

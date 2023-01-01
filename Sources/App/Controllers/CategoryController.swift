//
//  CategoryController.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Vapor
import Fluent

struct CategoryController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "v1", "category")
        categoriesRoute.post(use: createHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.delete(":categoryID", use: delete)
        categoriesRoute.get("by", ":categoryID", use: getHandler)
        categoriesRoute.get("acronyms", use: getAcronymsForCategory)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let category = try req.content.decode(Category.self)
        return category.save(on: req.db).map { category }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }
    
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return getHandler(req)
            .flatMap { category in
                category.delete(on: req.db)
                    .transform(to: .accepted)
            }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Category> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    func getAcronymsForCategory(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        guard let categoryID = try? req.query.get(UUID.self, at: "categoryID") else {
            throw Abort(.badRequest)
        }
        return Category.find(categoryID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
            }
    }
}

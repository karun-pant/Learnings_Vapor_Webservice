//
//  AcronymController.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Foundation
import Vapor
import Fluent

struct AcronymController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let acronymRoute = routes.grouped("api", "v1", "acronym")
        // CRUD Operations
        acronymRoute.post(use: create)
        acronymRoute.get("base_typed", use: getAllAsAcronym)
        acronymRoute.get("by", ":id", use: getSpecificByID)
        acronymRoute.put(":id", use: updateByID)
        acronymRoute.delete(":id", use: delete)
        // Fluent Operations
        acronymRoute.get("search", use: search)
        acronymRoute.get("first", use: getFirst)
        acronymRoute.get("all", use: getAll)
        acronymRoute.post("attach", "category", use: attachCategory)
        acronymRoute.get("categories", use: getCategoriesForAcronym)
    }
}

// MARK: - CRUD

private extension AcronymController {
    func create(_ req: Request) throws -> EventLoopFuture<Acronym> {
        // Instead of acronym since now it has userID, we will use DTO(Data transfer object)
//        let acronym = try req.content.decode(Acronym.self)
        let acronymDTO = try req.content.decode(AcronymDTO.self)
        // Transpose DTO object to acronym.
        let acronym = Acronym(short: acronymDTO.short,
                              long: acronymDTO.long,
                              userID: acronymDTO.userID)
        return acronym.save(on: req.db).map {
            acronym
        }
    }
    
    func getAllAsAcronym(_ req: Request) -> EventLoopFuture<[Acronym]> {
        // [R]etrieve all as Acronym
        Acronym.query(on: req.db).all()
    }
    
    func getSpecificByID(_ req: Request) -> EventLoopFuture<Acronym> {
        Acronym.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.badRequest))
    }
    
    func updateByID(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let updatedAcronym = try req.content.decode(Acronym.self)
        return Acronym.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.badRequest))
            .flatMap { acronym in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                return acronym.save(on: req.db).map {
                    acronym
                }
            }
    }
    
    func delete(_ req: Request) -> EventLoopFuture<String> {
        Acronym.find(req.parameters.get("id"),
                     on: req.db)
        .unwrap(or: Abort(.badRequest))
        .flatMap { acronym in
            acronym.delete(on: req.db)
                .transform(to: "{\"success\": \"'\(acronym.short)' is successfully deleted\"}")
        }
    }
}

// MARK: - Fluent Operations

private extension AcronymController {
    
    func search(_ req: Request) throws -> EventLoopFuture<AcronymResponse> {
        guard let searchTerm = req.query[String.self, at: "short"] else {
            throw Abort(.badRequest)
        }
        // eager load a relation, pass a key path to the relation to the with method on query builder.
        return Acronym.query(on: req.db)
            .with(\.$user)
            .filter(\.$short == searchTerm)
            .all()
            .map { acronyms in
                var accronymItems: [AcronymItem] = []
                for acronym in acronyms {
                    // passing user seperately so we don't have to add unnecessary code when eager loading is not needed.
                    accronymItems.append(AcronymItem(acronym: acronym,
                                                     eagerLoadedUser: acronym.user))
                }
                return AcronymResponse(accronyms: accronymItems)
            }
    }
    
    func getFirst(_ req: Request) -> EventLoopFuture<Acronym> {
        Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.noContent))
    }
    
    /// "desc" -> Descending else Ascending
    /// If sort param is not found return all anyway unsorted
    func getAll(_ req: Request) throws -> EventLoopFuture<AcronymResponse> {
        if let sort = req.query[String.self ,at: "sort"] {
            let sortType: DatabaseQuery.Sort.Direction = sort.lowercased() == "desc"
            ? .descending
            : .ascending
            return Acronym.query(on: req.db)
                .sort(\.$short, sortType)
                .all()
                .map({ acronyms in
                    var acroymItems: [AcronymItem] = []
                    for acronym in acronyms {
                        acroymItems.append(AcronymItem(acronym: acronym))
                    }
                    return AcronymResponse(accronyms: acroymItems)
                })
        } else {
            return Acronym.query(on: req.db)
                .with(\.$user)
                .all()
                .map({ acronyms in
                var acroymItems: [AcronymItem] = []
                for acronym in acronyms {
                    acroymItems.append(AcronymItem(acronym: acronym,
                                                   eagerLoadedUser: acronym.user))
                }
                return AcronymResponse(accronyms: acroymItems)
            })
        }
    }
}

// Pivot setup
private extension AcronymController {
    /// adding a category to acronym
    func attachCategory(_ req: Request) throws -> EventLoopFuture<String> {
        guard let acronymID = try? req.query.get(UUID.self ,at: "acronymID"),
              let categoryID = try? req.query.get(UUID.self, at: "categoryID") else {
            return req.eventLoop.future("Missed Sending acronymID and/or categoryID")
        }
        let acronymQuery = Acronym
            .find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category
            .find(categoryID, on: req.db)
            .unwrap(or: Abort(.notFound))
        return acronymQuery
            .and(categoryQuery)
            .flatMap { acronym, category in
            acronym
                .$categories
                .attach(category, on: req.db)
                .transform(to: "\(category.name) attached to \(acronym.short)")
        }
    }
    
    /// fetch all categories of acronym
    func getCategoriesForAcronym(_ req: Request) throws -> EventLoopFuture<[Category]> {
        guard let acronymID = try? req.query.get(UUID.self ,at: "acronymID")else {
            throw Abort(.badRequest)
        }
        return Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.badRequest))
            .flatMap { acronym in
                acronym.$categories.get(on: req.db)
            }
    }
    
    /// Detach category from acronym
    func detachCategory(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let acronymID = try? req.query.get(UUID.self ,at: "acronymID"),
              let categoryID = try? req.query.get(UUID.self, at: "categoryID") else {
            return req.eventLoop.future(.badRequest)
        }
        let acronymQuery = Acronym
            .find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category
            .find(categoryID, on: req.db)
            .unwrap(or: Abort(.notFound))
        return acronymQuery
            .and(categoryQuery)
            .flatMap { acronym, category in
                acronym
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: .created)
            }
    }
}

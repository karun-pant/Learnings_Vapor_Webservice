//
//  AcronymController.swift
//  
//
//  Created by Karun Pant on 31/12/22.
//

import Vapor
import Fluent

struct AcronymController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let acronymRoute = routes.grouped("api", "v1", "acronym")
        // CRUD Operations
        acronymRoute.post("add", use: create)
        acronymRoute.get("base_typed", use: getAllAsAcronym)
        acronymRoute.get("by", ":id", use: getSpecificByID)
        acronymRoute.put(":id", use: updateByID)
        acronymRoute.delete(":id", use: delete)
        // Fluent Operations
        acronymRoute.get("search", use: search)
        acronymRoute.get("first", use: getFirst)
        acronymRoute.get("all", use: getAll)
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
        return Acronym.query(on: req.db)
            .filter(\.$short == searchTerm)
            .all()
            .map { acronyms in
                var accronymItems: [AcronymItem] = []
                for acronym in acronyms {
                    accronymItems.append(AcronymItem(acronym: acronym))
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
            return Acronym.query(on: req.db).all().map({ acronyms in
                var acroymItems: [AcronymItem] = []
                for acronym in acronyms {
                    acroymItems.append(AcronymItem(acronym: acronym))
                }
                return AcronymResponse(accronyms: acroymItems)
            })
        }
    }
}

import Fluent
import Vapor

func routes(_ app: Application) throws {
    setupCRUDRoutes(app)
    setupFluentQueryRoutes(app)
}

// MARK: - Fluent Queries
private func setupFluentQueryRoutes(_ app: Application) {
    // Filter
    app.get("api", "v1", "acronym", "search") { req -> EventLoopFuture<AcronymResponse> in
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
    // First Result
    app.get("api", "v1", "acronyms", "first") { req -> EventLoopFuture<Acronym> in
        Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.noContent))
    }
    
    // All Sort by
    app.get("api", "v1", "acronyms") { req -> EventLoopFuture<AcronymResponse> in
        guard let sort = req.query[String.self ,at: "sort"] else {
            throw Abort(.badRequest)
        }
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
    }
    
}

// MARK: - CRUD Operations

private func setupCRUDRoutes(_ app: Application) {
    // [C]reate
    app.post("api", "v1", "acronym", "add") { req -> EventLoopFuture<Acronym> in
        let acronym = try req.content.decode(Acronym.self)
        return acronym.save(on: req.db).map {
            acronym
        }
    }
    
    // [R]etrieve all as Acronym
    app.get("api", "v1", "acronym_base") { req -> [Acronym] in
        try await Acronym.query(on: req.db).all().map { acronyms in
            acronyms
        }
    }
    
    // [R]etrieve all
    app.get("api", "v1", "acronyms") { req -> EventLoopFuture<AcronymResponse> in
        Acronym.query(on: req.db).all().map({ acronyms in
            var acroymItems: [AcronymItem] = []
            for acronym in acronyms {
                acroymItems.append(AcronymItem(acronym: acronym))
            }
            return AcronymResponse(accronyms: acroymItems)
        })
    }
    
    // [R]etrieve single/specific by id
    app.get("api", "v1", "acronym", ":id") { req -> EventLoopFuture<Acronym> in
        Acronym.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.badRequest))
    }
    
    // [U]pdate find by id since by name you might get multiple items.
    app.put("api", "v1", "acronym", ":id") { req -> EventLoopFuture<Acronym> in
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
    
    // [D]elete by finding id
    app.delete("api", "v1", "acronym", ":id") { req -> EventLoopFuture<String> in
        Acronym.find(req.parameters.get("id"),
                     on: req.db)
        .unwrap(or: Abort(.badRequest))
        .flatMap { acronym in
            acronym.delete(on: req.db)
                .transform(to: "{\"success\": \"'\(acronym.short)' is successfully deleted\"}")
        }
    }
}

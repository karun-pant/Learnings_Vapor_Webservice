import Fluent
import Vapor

func routes(_ app: Application) throws {
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
    // [R]etrieve single/specific
    app.get("api", "v1", "acronym", ":short") { req -> EventLoopFuture<AcronymResponse> in
        let shortName = req.parameters.get("short") ?? ""
        return Acronym.query(on: req.db)
            .filter(\.$short == shortName)
            .sort(\.$short)
            .all().map({ acronyms in
                guard !acronyms.isEmpty else {
                    return AcronymResponse(errorDescription: "Cannot find any acronym for '\(shortName)', You may want to send name all uppercased or all lowercased.")
                }
                var acroymItems: [AcronymItem] = []
                for acronym in acronyms {
                    acroymItems.append(AcronymItem(acronym: acronym))
                }
                return AcronymResponse(accronyms: acroymItems)
            })
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
                .transform(to: "Data has been deleted successfully.")
        }
    }
    
}

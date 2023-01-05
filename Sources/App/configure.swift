import Fluent
import FluentPostgresDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)
    if app.environment == .testing {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            // USING A DIFFERENT POST FOR TESTS.
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5433,
            username: Environment.get("DATABASE_USERNAME") ?? "learning_tests",
            password: Environment.get("DATABASE_PASSWORD") ?? "nurak",
            database: Environment.get("DATABASE_NAME") ?? "learning_test_db"
        ), as: .psql)
    } else {
         /*
          Using Docker DB created by Following command:
          
          docker run --name postgres -e POSTGRES_DB=learnings_database \
           -e POSTGRES_USER=karun_learning \
           -e POSTGRES_PASSWORD=nurak \
           -p 5432:5432 -d postgres
          */
        let port = app.environment.name == "website" ? PostgresConfiguration.ianaPortNumber : 5434
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? port,
            username: Environment.get("DATABASE_USERNAME") ?? "karun_learning",
            password: Environment.get("DATABASE_PASSWORD") ?? "nurak",
            database: Environment.get("DATABASE_NAME") ?? "learnings_database"
        ), as: .psql)
    }
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateAcroCatPivot())
    app.migrations.add(CreateToken())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}

import Fluent
import FluentPostgresDriver
import Vapor
import Leaf
import SendGrid

// configures your application
public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    app.views.use(.leaf)
    if app.environment == .testing {
        /*
         Using Docker DB created by Following command:
         
         docker run --name postgres-test -e POSTGRES_DB=learnings_database \
          -e POSTGRES_USER=karun_learning \
          -e POSTGRES_PASSWORD=nurak \
          -p 5433:5432 -d postgres
         */
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            // USING A DIFFERENT POST FOR TESTS.
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5433,
            username: Environment.get("DATABASE_USERNAME") ?? "karun_learning",
            password: Environment.get("DATABASE_PASSWORD") ?? "nurak",
            database: Environment.get("DATABASE_NAME") ?? "learnings_database"
        ), as: .psql)
    } else {
         /*
          Using Docker DB created by Following command:
          
          docker run --name postgres -e POSTGRES_DB=learnings_database \
           -e POSTGRES_USER=karun_learning \
           -e POSTGRES_PASSWORD=nurak \
           -p 5432:5432 -d postgres
          */
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "karun_learning",
            password: Environment.get("DATABASE_PASSWORD") ?? "nurak",
            database: Environment.get("DATABASE_NAME") ?? "learnings_database"
        ), as: .psql)
    }
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAdminUser())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateAcroCatPivot())
    app.migrations.add(CreateToken())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
    app.sendgrid.initialize()
}

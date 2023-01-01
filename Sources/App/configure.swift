import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    /// Using Docker DB created by Following command
    /// ```
    /// “docker run --name postgres -e POSTGRES_DB=learnings_database \
    ///  -e POSTGRES_USER=karun_learning \
    ///  -e POSTGRES_PASSWORD=nurak \
    ///  -p 5432:5432 -d postgres”
    ///  ```
//    app.databases.use(.postgres(
//        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
//        username: Environment.get("DATABASE_USERNAME") ?? "karun_learning",
//        password: Environment.get("DATABASE_PASSWORD") ?? "nurak",
//        database: Environment.get("DATABASE_NAME") ?? "learnings_database"
//    ), as: .psql)
    
    /// Using Docker DB by connection string
    app.databases.use(try .postgres(url: "postgres://postgres:postgrespw@localhost:55000"), as: .psql)

    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateUser())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}

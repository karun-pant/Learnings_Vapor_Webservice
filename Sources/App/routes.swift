import Fluent
import Vapor

func routes(_ app: Application) throws {
    let acronymController = AcronymController()
    try app.register(collection: acronymController)
    let userController = UserController()
    try app.register(collection: userController)
    let categoryController = CategoryController()
    try app.register(collection: categoryController)
    let website = WebsiteController()
    try app.register(collection: website)
    let imperialController = ImperialController()
    try app.register(collection: imperialController)
}

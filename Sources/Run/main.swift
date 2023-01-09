import App
import Vapor

var env = Environment(name: "prod") // "website" "auth"
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()

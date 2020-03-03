# JWT3PA (JWT Third Party Authentication)

This package wraps the boilerplate that's required when implementing Sign in with Apple and Google to your application.  


## Token Table

Your token model should conform to `JWT3PAUserToken` and the corresponding table should contain at least these two properties:

- value - text column that stores the Bearer Authorization header for this user.
- user - Reference column to the *user* table

This is the table that will store the Bearer token that you want to associate to the user.  Upon registration of a new
user a token will be automatically created for you.  It's up to you to handle any expiration, rotation, etc...

For example, you might have this:

```swift
final class ProducerToken: Model, Content, JWT3PAUserToken {
    static let schema = "producer_tokens"

    @ID(custom: "id")
    var id: Int?

    @Field(key: "value")
    var value: String

    @Parent(key: "producer_id")
    var user: Producer

    init() { }

    init(id: Int? = nil, value: String, producerID: Producer.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = producerID
    }
}
```

## User Table

Your user model should conform to `JWT3PAUser` and `Authenticatable`, which requires these three properties:

- google - text column that stores Google's unique ID
- apple - text column that stores Apple's unique ID
- active - boolean column that identifies whether the user is active or not

You'll also need a method to generate the appropriate *token* that you wish to use for the Bearer header.  Here's an
example of a full user:

```swift
final class Producer: Model, Content, JWT3PAUser, Authenticatable {
    static let schema = "producers"

    @ID(custom: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "apple")
    var apple: String?

    @Field(key: "google")
    var google: String?

    @Field(key: "active")
    var active: Bool

    @Field(key: "admin")
    var admin: Bool

    init() {
    }

    static func registerUser(req: Request, dto: RegisterUserDTO, email: String?, apple: String?, google: String?) -> EventLoopFuture<Producer> {
        guard let email = email else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        // Not everyone can register.  Valid users will already have an email
        // in the database so we're just associating their apple/google identifier.
        return Producer.query(on: req.db)
            .filter(\.$email == email)
            .first()
            .unwrap(or: Abort(.badRequest))
            .map { producer in
                producer.apple = apple ?? producer.apple
                producer.google = google ?? producer.google

                return producer
        }
    }

    func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        fatalError("Never return a Producer in the response.")
    }

    func encodeResponse(status: HTTPStatus, headers: HTTPHeaders = [:], for request: Request) -> EventLoopFuture<Response> {
        fatalError("Never return a Producer in the response.")
    }

    func generateToken(req: Request) -> EventLoopFuture<ProducerToken> {
        do {
            return req.eventLoop.makeSucceededFuture(try .init(value: [UInt8].random(count: 16).base64, producerID: self.requireID()))
        } catch {
            return req.eventLoop.makeFailedFuture(error)
        }
    }
}
```

### Registration

You'll need to define the DTO that you'll use to pass in all the data you want during new user registration.  Simply conform to
`JWT3PAUserDTO`.  Note you don't need to include the email address because that's provided in the JWT that Apple and Google give you.

```swift
struct RegisterUserDTO: JWT3PAUserDTO, Content {
    var name: String?
}
```

## Routes

Register your routes by calling `JWT3PAUserRoutes<T>.register(routeGroup:)`, where `T` is your user type, from `routes.swift`.  These routes will be generated:

- /login/apple
- /login/google
- /register/apple
- /register/google

All four routes return a `String` which contains the value to use in subsequent API calls for the Bearer header.  For example:

```swift
func routes(_ app: Application) throws {
    let users = app.grouped("users");
    JWT3PAUserRoutes<Producer>.register(routeGroup: users)
}
```

### Route Protection

You can get a guarded middleware to use on all your routes that will check against the Bearer token stored in your token table
by calling this method:

```swift
let tokenProtected = JWT3PATokenAuthenticator<ProducerToken>.guardMiddleware(app: app)
```

If used it will prevent any route from being hit without the Bearer token being valid.  You can get the authenticated user via
normal Vapor authentication query:

```swift
let user = try req.auth.require(Producer.self)
```



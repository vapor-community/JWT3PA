import Vapor
import Fluent
import JWTKit

public protocol JWT3PAUser: Model & Authenticatable {
    associatedtype Token: JWT3PAUserToken where Token.IDValue == Self.IDValue
    associatedtype UserDTO: JWT3PAUserDTO

    var google: String? { get set }
    var apple: String? { get set }
    var active: Bool { get set }

    init?(dto: UserDTO, email: String?, apple: String?, google: String?)

    func generateToken(req: Request) -> EventLoopFuture<Token>
}

internal extension JWT3PAUser {
    var _$id: ID<Self.IDValue> {
        guard let mirror = Mirror(reflecting: self).descendant("_id"),
            let id = mirror as? ID<Self.IDValue> else {
                fatalError("id property must be declared using @ID")
        }

        return id
    }

    var _$google: Field<String?> {
        guard let mirror = Mirror(reflecting: self).descendant("_google"),
            let field = mirror as? Field<String?> else {
                fatalError("google property must be declared using @Field")
        }

        return field
    }

    var _$apple: Field<String?> {
        guard let mirror = Mirror(reflecting: self).descendant("_apple"),
            let field = mirror as? Field<String?> else {
                fatalError("apple property must be declared using @Field")
        }

        return field
    }

    var _$active: Field<Bool> {
        guard let mirror = Mirror(reflecting: self).descendant("_active"),
            let field = mirror as? Field<Bool> else {
                fatalError("active property must be declared using @Field")
        }

        return field
    }

    /// Gets the token which the already registered user should use for subsequent API calls.
    /// - Parameters:
    ///   - filter: The filter for which column in the user table to query for the user identifier
    ///   - req: The Vapor `Request` object
    /// - Returns: The new Bearer token to use.
    static func apiTokenForUser(filter: ModelValueFilter<Self>, req: Request) -> EventLoopFuture<String> {
        Token.query(on: req.db)
            .join(Self.self, on: \Token._$user.$id == \Self._$id)
            .with(\Token._$user)
            .filter(Self.self, filter)
            .filter(Self.self, \._$active == true)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .map { $0.value }
    }

    /// Creates a user and their associated token in the database.
    /// - Parameters:
    ///   - req: The Vapor `Request`
    ///   - email: The email address of the new user, if available.
    ///   - vendor: Which vendor authenticated the new user.
    ///   - subject: The `sub` claim from the JWT Bearer header
    /// - Returns: The authentication token to use for subsequent API calls.
    static func createUserAndToken(req: Request,
                                   email: String?,
                                   vendor: JWT3PAVendor,
                                   subject: SubjectClaim) -> EventLoopFuture<String> {
        do {
            guard let email = email else {
                throw Abort(.badRequest)
            }

            let dto = try req.content.decode(UserDTO.self)

            var apple: String? = nil
            var google: String? = nil
            let filter: ModelValueFilter<Self>

            switch vendor {
            case .apple:
                apple = subject.value
                filter = \._$apple == apple
            case .google:
                google = subject.value
                filter = \._$google == google
            }

            return Self.query(on: req.db)
                .filter(filter)
                .first()
                .flatMap {
                    guard $0 == nil else {
                        // The person is already a registered user.
                        return req.eventLoop.makeFailedFuture(Abort(.badRequest))
                    }

                    guard let user = Self(dto: dto, email: email, apple: apple, google: google) else {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                    }

                    return user.save(on: req.db).flatMap {
                        user.generateToken(req: req).flatMap { token in
                            token.save(on: req.db).map {
                                token.value
                            }
                        }
                    }
            }
        } catch {
            return req.eventLoop.makeFailedFuture(error)
        }
    }
}

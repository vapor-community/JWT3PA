import Vapor
import Fluent
import JWTKit

public protocol ThirdPartyJWTAuthenticatedUser: Model {
    associatedtype Token: ThirdPartyJWTUserAuthenticationToken

    var google: String? { get set }
    var apple: String? { get set }

    init?(name: String?, email: String?, apple: String?, google: String?)

    func generateToken(req: Request) -> EventLoopFuture<Token>
}

public extension ThirdPartyJWTAuthenticatedUser {
    static func apiTokenForUser(filter: ModelValueFilter<Self>, req: Request) -> EventLoopFuture<Self.Token> {
        Self.query(on: req.db)
            .filter(filter)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap { $0.generateToken(req: req) }
    }

    static func createUserAndToken(req: Request,
                                   email: String?,
                                   vendor: ThirdPartyAuthenticationVendor,
                                   subject: SubjectClaim) -> EventLoopFuture<String> {
        do {
            guard let email = email else {
                throw Abort(.badRequest)
            }

            let dto = try req.content.decode(RegisterUserDTO.self)

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

                    guard let user = Self(name: dto.name, email: email, apple: apple, google: google) else {
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

internal extension ThirdPartyJWTAuthenticatedUser {
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
}

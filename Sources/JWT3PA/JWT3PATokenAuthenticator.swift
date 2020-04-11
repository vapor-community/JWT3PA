import Vapor
import Fluent

final public class JWT3PATokenAuthenticator<T>: BearerAuthenticator where T: JWT3PAUserToken {
    public func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        return T.query(on: request.db)
            .filter(\._$value == bearer.token)
            .first()
            .unwrap(or: Abort(.forbidden))
            .map { request.auth.login($0.user) }
    }

    /// Creates a guard middleware which will ensure an authenticated user is present on the route.
    /// - Parameter group: Either the `Application` or a `RoutesBuilder` group.
    /// - Returns:A new `RoutesBuilder` group which is protected.
    public static func guardMiddleware(for group: RoutesBuilder) -> RoutesBuilder {
        return group.grouped(JWT3PATokenAuthenticator<T>(), T.User.guardMiddleware())
    }
}



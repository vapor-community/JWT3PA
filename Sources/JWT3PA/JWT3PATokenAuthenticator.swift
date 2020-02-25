import Vapor
import Fluent

final public class JWT3PATokenAuthenticator<T>: BearerAuthenticator where T: JWT3PAUserToken {
    public typealias User = T.User
    
    public func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<T.User?> {
        let db = request.db

        return T.query(on: db)
            .filter(\._$value == bearer.token)
            .first()
            .flatMap { token -> EventLoopFuture<T.User?> in
                guard let token = token else {
                    return request.eventLoop.makeSucceededFuture(nil)
                }

                return token._$user.get(on: db).map { $0 }
        }
    }

    /// Creates a guard middleware which will ensure an authenticated user is present on the route.
    /// - Parameter group: Either the `Application` or a `RoutesBuilder` group.
    /// - Returns:A new `RoutesBuilder` group which is protected.
    public static func guardMiddleware(for group: RoutesBuilder) -> RoutesBuilder {
        return group.grouped(JWT3PATokenAuthenticator<T>().middleware())
            .grouped(T.User.guardMiddleware())
    }
}



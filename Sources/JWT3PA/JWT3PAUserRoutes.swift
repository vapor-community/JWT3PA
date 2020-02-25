import Vapor
import Fluent
import JWT

public class JWT3PAUserRoutes<T> where T: JWT3PAUser {
    func appleLogin(req: Request) throws -> EventLoopFuture<String> {
        req.jwt.apple.verify().flatMap { (token: AppleIdentityToken) in
            T.apiTokenForUser(filter: \._$apple == token.subject.value, req: req)
        }
    }

    func googleLogin(req: Request) throws -> EventLoopFuture<String> {
        req.jwt.google.verify().flatMap { (token: GoogleIdentityToken) in
            T.apiTokenForUser(filter: \._$google == token.subject.value, req: req)
        }
    }

    func appleRegister(req: Request) throws -> EventLoopFuture<String> {
        return req.jwt.apple.verify().flatMap { (token: AppleIdentityToken) in
            T.createUserAndToken(req: req, email: token.email, vendor: .apple, subject: token.subject)
        }
    }

    func googleRegister(req: Request) throws -> EventLoopFuture<String> {
        return req.jwt.google.verify().flatMap { (token: GoogleIdentityToken) in
            T.createUserAndToken(req: req, email: token.email, vendor: .google, subject: token.subject)
        }
    }

    public static func register(routeGroup: RoutesBuilder) {
        let me = JWT3PAUserRoutes<T>()

        routeGroup.post("register", "apple", use: me.appleRegister)
        routeGroup.post("register", "google", use: me.googleRegister)

        routeGroup.post("login", "apple", use: me.appleLogin)
        routeGroup.post("login", "google", use: me.googleLogin)
    }

    private init() {}
}

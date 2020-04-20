import Vapor
import Fluent
import JWT

public struct Routes: OptionSet {
    public let rawValue: Int

    public static let apple = Routes(rawValue: 1 << 0)
    public static let google = Routes(rawValue: 1 << 1)
    public static let all: Routes = [.apple, .google]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public class JWT3PAUserRoutes<T> where T: JWT3PAUser {
    let redirect: String?
    let fragmentKey: String?

    private static func generateCrossSiteForgeryCookies(for response: Response) {
        let token = [UInt8].random(count: 16).base64

        response.headers.setCookie = HTTPCookies(dictionaryLiteral:
            ("XSRF-TOKEN", HTTPCookies.Value(string: token, isSecure: false)),
            ("CSRF-TOKEN", HTTPCookies.Value(string: token, isSecure: false))
        )
    }

    func response(for token: String) throws -> Response {
        let response = Response(status: .ok)

        if var redirect = self.redirect {
            if let fragmentKey = self.fragmentKey {
                redirect += "?\(fragmentKey)=\(token)"
            }

            response.headers.add(name: .location, value: redirect)
            response.status = .seeOther
        } else {
            response.headers.add(name: .contentType, value: HTTPMediaType.plainText.serialize())
            try response.content.encode(token)
        }

        Self.generateCrossSiteForgeryCookies(for: response)

        print("Headers are this")
        print(response.headers)
        return response
    }

    func appleLogin(req: Request) throws -> EventLoopFuture<Response> {
        let future: EventLoopFuture<AppleIdentityToken>
        
        if let contentType = req.headers.contentType, contentType == .urlEncodedForm {
            // It's from a webpage or Android where the body has the details
            let data = try req.content.decode(AppleWebPayload.self)

            if let error = data.error {
                throw Abort(.badRequest, reason: error)
            }

            guard let idToken = data.idToken else {
                throw Abort(.badRequest )
            }

            future = req.jwt.apple.verify(idToken, applicationIdentifier: nil)
        } else {
            future = req.jwt.apple.verify()
        }

        return future.flatMap { (token: AppleIdentityToken) in
            T.apiTokenForUser(filter: \._$apple == token.subject.value, req: req)
                .flatMapThrowing { return try self.response(for: $0) }
        }
    }

    func googleLogin(req: Request) throws -> EventLoopFuture<Response> {
        req.jwt.google.verify().flatMap { (token: GoogleIdentityToken) in
            T.apiTokenForUser(filter: \._$google == token.subject.value, req: req)
                .flatMapThrowing { try self.response(for: $0) }
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

    private init(_ redirect: String? = nil, _ fragmentKey: String?) {
        self.redirect = redirect
        self.fragmentKey = fragmentKey
    }

    public static func register(
        routeGroup: RoutesBuilder,
        routes: Routes = .all,
        redirect: String? = nil,
        fragmentKey: String? = nil
    ) {
        let me = JWT3PAUserRoutes<T>(redirect, fragmentKey)

        if routes.contains(.apple) {
            routeGroup.post("login", "apple", use: me.appleLogin)
            routeGroup.post("register", "apple", use: me.appleRegister)
        }

        if routes.contains(.google) {
            routeGroup.post("login", "google", use: me.googleLogin)
            routeGroup.post("register", "google", use: me.googleRegister)
        }
    }
}


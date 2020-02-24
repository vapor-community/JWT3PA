import Vapor
import Fluent

public protocol ThirdPartyJWTUserAuthenticationToken: Model {
    var value: String { get set }
}



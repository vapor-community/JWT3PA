import Vapor
import Fluent

public protocol JWT3PAUserToken: Model {
    associatedtype User: Model & Authenticatable where User.IDValue == Self.IDValue

    var value: String { get set }
    var user: User { get set }
}

extension JWT3PAUserToken {
    var _$value: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_value"),
            let field = mirror as? Field<String> else {
                fatalError("value property must be declared using @Field")
        }

        return field
    }

    var _$user: Parent<User> {
        guard let mirror = Mirror(reflecting: self).descendant("_user"),
            let field = mirror as? Parent<User> else {
                fatalError("user property must be declared using @Parent")
        }

        return field
    }
}



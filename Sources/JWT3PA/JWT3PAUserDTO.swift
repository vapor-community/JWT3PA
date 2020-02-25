import Vapor

public protocol JWT3PAUserDTO: Content {
    var name: String? { get set }
}

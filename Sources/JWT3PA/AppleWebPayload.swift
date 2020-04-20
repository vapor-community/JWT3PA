import Vapor

struct AppleWebUserNamePayload: Content {
    let firstName: String?
    let lastName: String?
}

struct AppleWebUserPayload: Content {
    let name: String?
    let email: String?
}

struct AppleWebPayload: Content {
    enum CodingKeys: String, CodingKey {
        case state, code, user, error
        case idToken = "id_token"
    }

    /// The state passed by the init function.
    let state: String?

    /// A single-use authentication code that is valid for five minutes.
    let code: String?

    /// A JSON web token containing the user’s identify information.
    let idToken: String?

    /// The data requested in the scope property.
    let user: AppleWebUserPayload

    /// The returned error code. Currently, the only error is user_cancelled_authorize.
    let error: String?
}

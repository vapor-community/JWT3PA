import Vapor

public struct JWT3PAAppleWebResponse {
    /// A single-user authorization code that is valid for five minutes.
    let code: String

    /// A JSON web token containing the user's identity information.
    let idToken: String

    /// The state contained in the Authorize URL
    let state: String

    let user: String
}

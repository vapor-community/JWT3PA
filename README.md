# ThirdPartyJWTAuthentication

A description of this package.

Your 'user' model should conform to ThirdPartyJWTAuthenticatedUser
Your 'token' model should conform to ThirdPartyJWTUserAuthenticationToken
Your generateToken would look something like so:

 func generateToken(req: Request) -> EventLoopFuture<ProducerToken> {
   do {
       return req.eventLoop.makeSucceededFuture(try .init(value: [UInt8].random(count: 16).base64, producerID: self.requireID()))
   } catch {
       return req.eventLoop.makeFailedFuture(error)
   }
 }

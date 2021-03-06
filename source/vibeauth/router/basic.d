module vibeauth.router.basic;

import vibe.http.router;
import vibe.data.json;
import vibeauth.users;
import std.algorithm.searching, std.base64, std.string, std.stdio;
import vibeauth.router.baseAuthRouter;

/// Basic auth credential pair
struct BasicAuthCredentials {
  ///
  string username;
  
  ///
  string password;
}

/// Basic auth handler. It's not safe to use it without https.
class BasicAuth(string realm): BaseAuthRouter {

  ///
  this(UserCollection collection) {
    super(collection);
  }

  override {
    /// Auth handler that will fail if a successfull auth was not performed.
    /// This handler is usefull for routes that want to hide information to the
    /// public.
    void mandatoryAuth(HTTPServerRequest req, HTTPServerResponse res) {
      auto pauth = "Authorization" in req.headers;

      setAccessControl(res);

      if(pauth && (*pauth).startsWith("Basic ")) {
        auto auth = parseBasicAuth((*pauth)[6 .. $]);

        if(auth.username in collection && collection[auth.username].isValidPassword(auth.password)) {
          req.username = auth.username;
          return;
        } else {
          respondUnauthorized(res);
        }
      } else {
        respondUnauthorized(res);
      }
    }

    /// Auth handler that fails only if the auth fields are present and are not valid.
    /// This handler is usefull when a route should return different data when the user is 
    /// logged in
    void permisiveAuth(HTTPServerRequest req, HTTPServerResponse res) {
      auto pauth = "Authorization" in req.headers;

      setAccessControl(res);

      if(pauth && (*pauth).startsWith("Basic ")) {
        auto auth = parseBasicAuth((*pauth)[6 .. $]);

        if(auth.username in collection && collection[auth.username].isValidPassword(auth.password)) {
          req.username = auth.username;
          return;
        } else {
          respondUnauthorized(res);
        }
      }
    }
  }

  private {
    /// Parse user input
    BasicAuthCredentials parseBasicAuth(string data) {
      string decodedData = cast(string)Base64.decode(data);
      auto idx = decodedData.indexOf(":");
      enforceBadRequest(idx >= 0, "Invalid auth string format!");

      return BasicAuthCredentials(decodedData[0 .. idx], decodedData[idx+1 .. $]);
    }

    /// Respond with auth error
    void respondUnauthorized(HTTPServerResponse res, string message = "Authorization required") {
      res.statusCode = HTTPStatus.unauthorized;
      res.contentType = "text/plain";
      res.headers["WWW-Authenticate"] = "Basic realm=\""~realm~"\"";
      res.bodyWriter.write(message);
    }
  }
}

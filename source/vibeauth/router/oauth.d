module vibeauth.router.oauth;

import vibe.http.router;
import vibe.data.json;
import vibeauth.users;
import std.algorithm.searching, std.base64, std.string, std.stdio;
import vibeauth.router.baseAuthRouter;
import vibeauth.client;

struct OAuth2Configuration {
  string tokenPath = "/auth/token";
  string authorizePath = "/auth/authorize";
  string authenticatePath = "/auth/authenticate";

  string style = "";
}

class OAuth2: BaseAuthRouter {
  protected {
    const OAuth2Configuration configuration;
    ClientCollection clientCollection;
  }

  this(UserCollection userCollection, ClientCollection clientCollection, const OAuth2Configuration configuration = OAuth2Configuration()) {
    super(userCollection);

    this.configuration = configuration;
    this.clientCollection = clientCollection;
  }

  override {
    void checkLogin(scope HTTPServerRequest req, scope HTTPServerResponse res) {
      setAccessControl(res);

      if(req.method == HTTPMethod.OPTIONS) {
        return;
      }

      if(req.path == configuration.tokenPath) {
        createToken(req, res);
      } else if (req.path == configuration.authorizePath) {
        authorize(req, res);
      } else if(req.path == configuration.authenticatePath) {
        authenticate(req, res);
      } else if(req.path != configuration.style && !isValidBearer(req)) {
        respondUnauthorized(res);
      }
    }
  }

  void setAccessControl(ref HTTPServerResponse res) {
    res.headers["Access-Control-Allow-Origin"] = "*";
    res.headers["Access-Control-Allow-Headers"] = "Authorization, ";
  }

  private {
    bool isValidBearer(HTTPServerRequest req) {
      auto pauth = "Authorization" in req.headers;

      if(pauth && (*pauth).startsWith("Bearer ")) {
        auto token = (*pauth)[7 .. $];

        try {
          auto const user = collection.byToken(token);
          req.username = user.email;
        } catch(UserNotFoundException exception) {
          return false;
        }

        return true;
      }

      return false;
    }

    void authorize(scope HTTPServerRequest req, scope HTTPServerResponse res) {
      if("redirect_uri" !in req.query) {
        showError(res, "Missing `redirect_uri` parameter");
        return;
      }

      if("client_id" !in req.query) {
        showError(res, "Missing `client_id` parameter");
        return;
      }

      auto const redirectUri = req.query["redirect_uri"];
      auto const clientId = req.query["client_id"];
      auto const style = configuration.style;

      if(clientId !in clientCollection) {
        showError(res, "Invalid `client_id` parameter");
        return;
      }

      /*
      ([Field("client_id", "consumerKey"),
      Field("redirect_uri", "oauth-swift://oauth-callback/kangal"),
      Field("response_type", "token"),
      Field("scope", "user-library-modify"),
      Field("state", "qQXwwzv9LErOnZHRCzkd")
      */

      string appTitle = clientCollection[clientId].name;

      res.render!("loginForm.dt", appTitle, redirectUri, style);
    }

    void showError(scope HTTPServerResponse res, const string error) {
      auto const style = configuration.style;
      res.statusCode = 400;
      res.render!("error.dt", error, style);
    }

    void authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res) {
      auto redirectUri = req.form["redirect_uri"];

      res.render!("redirect.dt", redirectUri);
    }

    void createToken(scope HTTPServerRequest req, scope HTTPServerResponse res) {
      auto const grantType = req.form["grant_type"];
      auto const username = req.form["username"];
      auto const password = req.form["password"];

      if(grantType == "password") {
        if(collection.contains(username) && collection[username].isValidPassword(password)) {
          Json response = Json.emptyObject;

          response.access_token = collection[username].createToken;
          response.token_type = "Bearer";
          response.expires_in = 3600;
          response.refresh_token = "";

          res.writeJsonBody(response);
        } else {
          respondUnauthorized(res, "Invalid password or username");
        }
      } else {
        respondUnauthorized(res, "Invalid `grant_type` value");
      }
    }

    void respondUnauthorized(scope HTTPServerResponse res, string message = "Authorization required") {
      res.statusCode = HTTPStatus.unauthorized;
      res.contentType = "text/plain";
      res.bodyWriter.write(message);
    }
  }
}

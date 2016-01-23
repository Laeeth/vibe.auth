module uac.router.baseAuthRouter;

import vibe.http.router;
import vibe.data.json;
import uac.users;
import std.algorithm.searching, std.base64, std.string, std.stdio;


abstract class BaseAuthRouter {

  protected UserCollection collection;

  this(UserCollection collection) {
    this.collection = collection;
  }

  abstract void checkLogin(scope HTTPServerRequest req, scope HTTPServerResponse res);
}

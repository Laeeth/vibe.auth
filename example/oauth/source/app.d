import std.stdio;

import vibeauth.client;
import vibeauth.users;
import vibeauth.router.oauth;
import vibe.d;


shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8888;
	settings.options = HTTPServerOption.parseFormBody | HTTPServerOption.parseQueryString | HTTPServerOption.parseJsonBody;

	auto router = new URLRouter();

	auto collection = new UserMemmoryCollection(["doStuff"]);
	auto user = new User("user@gmail.com", "password");
	user.name = "John Doe";
	user.username = "test";
	user.id = 1;

	collection.add(user);

	auto clientCollection = ClientCollection.FromFile("oauth.clients.json");

	auto auth = new OAuth2(collection, clientCollection);
	router.any("*", &auth.checkLogin);
	router.get("*", &handleRequest);

	listenHTTP(settings, router);

	writeln("Go to http://localhost:8888/auth/authorize?redirect_uri=&client_id=CLIENT_ID&state= to check the auth");
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody("Hello, World!", "text/plain");
}

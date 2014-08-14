import std.conv : to;
import std.string : format;

import vibe.d;

static immutable string HOST = "localhost:8080/";
RedisClient redisClient;

void getUrl(HTTPServerRequest req, HTTPServerResponse res)
{
  auto db = redisClient.getDatabase(0);
  auto key = req.params["key"];

  auto url = db.get(format("url\\%s\\key", key));
  res.redirect(url);
}

void createUrl(HTTPServerRequest req, HTTPServerResponse res)
{
  enforceHTTP("url" in req.form, HTTPStatus.badRequest, "Missing URL.");

  auto db = redisClient.getDatabase(0);
  auto url = req.form["url"];

  auto key = db.incr("url_count");
  db.set(format("url\\%s\\key", key), url);
  auto short_url = format(HOST ~ "%s", key);

  res.render!("url.dt", short_url);
}

shared static this()
{
  redisClient = connectRedis("localhost");

  auto router = new URLRouter;

  router.get("/", staticTemplate!"index.dt");
  router.get("/public/*", serveStaticFiles("./public/", new HTTPFileServerSettings("/public/")));
  router.post("/urls", &createUrl);
  router.get("/:key", &getUrl);

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["127.0.0.1"];

  listenHTTP(settings, router);
}
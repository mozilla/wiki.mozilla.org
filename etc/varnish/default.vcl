vcl 4.0;
import std;

backend default {
  .host = "web";
  .port = "80";
  .probe = {
    .initial = 3;
  	.interval = 5s;
    .timeout = 15s;
    .threshold = 3;
    .window = 8;
    .expected_response = 200;
    .url = "/Special%3AVersion";
  }
}

acl purge {
    "127.0.0.1";
    "varnish";
}

#sub vcl_init {
#  #Import file with director definitions;
#  include "includes/directors.vcl";
#}

sub vcl_recv {
  if (req.http.X-Forwarded-For) {
     std.log("RealIP:" + req.http.X-Forwarded-For);
  } else {
     std.log("RealIP:" + client.ip);
  }


  # cookie sanitization
  if (req.http.Cookie) {
    set req.http.Cookie = ";"+req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(wiki_session|wikiUserID)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
    if (req.http.Cookie == "") {
      unset req.http.Cookie;
    }
  }

  if (

    # Static file cache
    req.url ~ "^/(assets|extensions|images|skins|resources)/" ||
    req.url ~ "^/load.php(\?.*)?$"

    ) {
    unset req.http.Cookie;
  }



  # backend selection logic
  #include "includes/backendselection.vcl";

  # Allows purge for the IPs in purge ACL
  if (req.method == "PURGE") {
    if (!(client.ip ~ purge)) {
      return (synth(405, "Not allowed."));
    }
    ban(" req.url == " + req.url);
    set req.url = regsuball(req.url,"80","443");
    set req.url = regsuball(req.url,"http","https");
    ban(" req.url == " + req.url);
    # Throw a synthetic page so the
    # request won't go to the backend.
    return (synth(200, "Added ban."));
  }
  /* Pipe chunked or multipart uploads to avoid timeout */
  if ((req.method == "POST" || req.method == "PUT") && (req.http.transfer-encoding ~ "chunked" || req.http.Content-Type ~ "multipart/form-data")) {
    return(pipe);
  }


  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
    /* Non-RFC2616 or CONNECT which is weird. */
    return (pipe);
  }
}

sub vcl_hash {
}

sub vcl_pipe {
  set req.http.Connection = "close";
  return (pipe);
}

sub vcl_hit {
  std.log( "CACHE-DEBUG URL:"+req.url+" COOKIE:"+req.http.Cookie+" AVISO:HIT IP:"+client.ip);
}

sub vcl_miss {
  std.log( "CACHE-DEBUG URL:"+req.url+" COOKIE:"+req.http.Cookie+" AVISO:MISS IP:"+client.ip);
}

sub vcl_pass {
  std.log( "CACHE-DEBUG URL:"+req.url+" COOKIE:"+req.http.Cookie+" AVISO:PASS IP:"+client.ip);
}

sub vcl_backend_response {

  if (beresp.http.content-type ~ "^text/|^application/xml|^application/rss|^application/xhtml|^application/javascript|^application/x-javascript") {
    set beresp.do_gzip = true;
  }

  # Remove I18N_LANGUAGE Set-Cookie
  if (beresp.http.Set-Cookie ~ "I18N_LANGUAGE") {
    unset beresp.http.Set-Cookie;
  }
  # If no explicit TTL was set by the backend
  if (beresp.ttl < 0s) {

  # Default minimum cache period
  if(!(bereq.http.Cookie)&&!(beresp.http.Set-Cookie)&&(bereq.method == "GET")) {
    set beresp.ttl = 60s;
  }

  if (
    # Static file cache
    (bereq.url ~ "(?i)\.(jpg|jpeg|gif|png|tiff|tif|svg|swf|ico|css|kss|js|vsd|doc|ppt|pps|xls|pdf|mp3|mp4|m4a|ogg|mov|avi|wmv|sxw|zip|gz|bz2|tar|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm|jar|class|flv|exe)$")||
    # Plone images cache
    (bereq.url ~ "(?i)(image|imagem_large|image_preview|image_mini|image_thumb|image_tile|image_icon|imagem_listing)$")
  ) {
    set beresp.ttl = 5m;
    unset beresp.http.Set-Cookie;
  }

  # Avoid cache of objects > 100M
  if ( beresp.http.Content-Length ~ "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" ) {
    set beresp.uncacheable = true;
    set beresp.ttl = 5m;
    return (deliver);
  }
  }
}

sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
}

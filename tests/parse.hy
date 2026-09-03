// Parse, round-trip, and error tests for url::parse.
use url::{parse, Url, UrlError};

fn must_parse(string s) -> Url {
    return match parse(s) {
        Result::Ok(u) => u,
        Result::Err(_) => panic "parse failed",
    };
}

fn is_invalid(Result<Url, UrlError> r) -> bool {
    return match r {
        Result::Ok(_) => false,
        Result::Err(e) => match e {
            UrlError::Invalid { message } => message != "",
            default => false,
        },
    };
}

test("http host path query fragment") {
    let u = must_parse("http://example.com/a/b?x=1#f");
    assert(u.scheme == "http", "scheme")?;
    assert(u.host == "example.com", "host")?;
    assert(u.port == 0, "port omitted")?;
    assert(u.path == "/a/b", "path")?;
    assert(u.query == "x=1", "query")?;
    assert(u.fragment == "f", "fragment")?;
    assert(u.to_string() == "http://example.com/a/b?x=1#f", "roundtrip")?;
    assert(u.string() == u.to_string(), "string alias")?;
}

test("https port userinfo") {
    let u = must_parse("https://u:p@Example.COM:8443/x");
    assert(u.scheme == "https", "scheme")?;
    assert(u.userinfo == "u:p", "userinfo")?;
    assert(u.host == "example.com", "host lower")?;
    assert(u.port == 8443, "port")?;
    assert(u.to_string() == "https://u:p@example.com:8443/x", "roundtrip")?;
}

test("file empty host") {
    let u = must_parse("file:///tmp/x");
    assert(u.scheme == "file", "scheme")?;
    assert(u.host == "", "empty host")?;
    assert(u.has_authority, "authority")?;
    assert(u.path == "/tmp/x", "path")?;
    assert(u.to_string() == "file:///tmp/x", "roundtrip")?;
}

test("ws wss and generic scheme") {
    let ws = must_parse("ws://localhost/chat");
    assert(ws.scheme == "ws" && ws.host == "localhost", "ws")?;
    let wss = must_parse("wss://localhost/chat");
    assert(wss.scheme == "wss", "wss")?;
    let git = must_parse("git://github.com/ardax-corp/coil-url.git");
    assert(git.scheme == "git" && git.host == "github.com", "git")?;
    assert(git.path == "/ardax-corp/coil-url.git", "git path")?;
}

test("ipv6 host") {
    let u = must_parse("http://[::1]:8080/x");
    assert(u.host == "::1", "host")?;
    assert(u.port == 8080, "port")?;
    assert(u.to_string() == "http://[::1]:8080/x", "brackets")?;
}

test("relative reference") {
    let u = must_parse("../c");
    assert(u.scheme == "", "no scheme")?;
    assert(u.path == "../c", "path")?;
    assert(u.to_string() == "../c", "roundtrip")?;
}

test("empty input is relative") {
    let u = must_parse("");
    assert(u.scheme == "" && u.path == "", "empty")?;
    assert(u.to_string() == "", "empty string")?;
}

test("http empty host is invalid") {
    assert(is_invalid(parse("http://")), "http://")?;
    assert(is_invalid(parse("https:///path")), "https empty host")?;
    assert(is_invalid(parse("ws://")), "ws")?;
}

test("whitespace is invalid") {
    assert(is_invalid(parse("http://example.com/a b")), "space")?;
    assert(is_invalid(parse(" http://example.com")), "leading")?;
}

test("bad percent and port") {
    assert(is_invalid(parse("http://example.com/%zz")), "bad pct")?;
    assert(is_invalid(parse("http://example.com/%a")), "trunc pct")?;
    assert(is_invalid(parse("http://example.com:99999/")), "port")?;
    assert(is_invalid(parse("http://[::1")), "unclosed ipv6")?;
}

test("scheme foo:bar is absolute") {
    let u = must_parse("foo:bar");
    assert(u.scheme == "foo" && u.path == "bar", "generic")?;
}

test("colon-only relative is invalid") {
    assert(is_invalid(parse(":bar")), ":bar")?;
}

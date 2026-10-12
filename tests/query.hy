// Query map get/set and percent-encode/decode.
use tests::assert;
use url::{parse, percent_encode, percent_decode, Url, UrlError};

fn must_parse(string s) -> Url {
    return match parse(s) {
        Result::Ok(u) => u,
        Result::Err(_) => panic "parse failed",
    };
}

fn must_decode(string s) -> string {
    return match percent_decode(s) {
        Result::Ok(t) => t,
        Result::Err(_) => panic "decode failed",
    };
}

test("query get first key") {
    let u = must_parse("https://example.com/x?a=1&b=two&a=3");
    assert!(u.query_get("a") == "1", "first a");
    assert!(u.query_get("b") == "two", "b");
    assert!(u.query_get("z") == "", "missing");
}

test("query get percent-decodes") {
    let u = must_parse("http://example.com/?q=hello%20world");
    assert!(u.query_get("q") == "hello world", "decoded");
}

test("query set replaces and appends") {
    let u = must_parse("http://example.com/p?a=1&b=2");
    let u2 = u.query_set("a", "x");
    assert!(u2.to_string() == "http://example.com/p?a=x&b=2", "replace");
    assert!(u.to_string() == "http://example.com/p?a=1&b=2", "original");
    let u3 = u.query_set("c", "3");
    assert!(u3.query_get("c") == "3", "append");
}

test("query set on url without query") {
    let u = must_parse("http://example.com/p");
    let u2 = u.query_set("q", "1");
    assert!(u2.to_string() == "http://example.com/p?q=1", "new query");
}

test("percent encode unreserved stays") {
    assert!(percent_encode("abc-._~XYZ012") == "abc-._~XYZ012", "unreserved");
}

test("percent encode space and slash") {
    assert!(percent_encode("a b/c") == "a%20b%2Fc", "space slash");
}

test("percent decode roundtrip") {
    let s = "hello world?";
    let enc = percent_encode(s);
    assert!(must_decode(enc) == s, "roundtrip");
    assert!(must_decode("a%20b") == "a b", "space");
}

test("percent decode bad input") {
    let r = percent_decode("%zz");
    assert!(match r {
        Result::Ok(_) => false,
        Result::Err(e) => match e {
            UrlError::Invalid { message } => message != "",
            default => false,
        },
    }, "bad pct");
    let t = percent_decode("%a");
    assert!(match t {
        Result::Ok(_) => false,
        Result::Err(e) => match e {
            UrlError::Invalid { message } => message != "",
            default => false,
        },
    }, "trunc");
}

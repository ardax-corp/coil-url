// RFC 3986 §5.4 relative resolution tests.
use tests::assert;
use url::{parse, join, Url};

fn must_parse(string s) -> Url {
    return match parse(s) {
        Result::Ok(u) => u,
        Result::Err(_) => panic "parse failed",
    };
}

fn must_join(Url base, string r) -> string {
    return match join(base, r) {
        Result::Ok(u) => u.to_string(),
        Result::Err(_) => panic "join failed",
    };
}

fn base() -> Url {
    return must_parse("http://a/b/c/d;p?q");
}

test("rfc 5.4 normal examples") {
    let b = base();
    assert!(must_join(b, "g:h") == "g:h", "g:h");
    assert!(must_join(b, "g") == "http://a/b/c/g", "g");
    assert!(must_join(b, "./g") == "http://a/b/c/g", "./g");
    assert!(must_join(b, "g/") == "http://a/b/c/g/", "g/");
    assert!(must_join(b, "/g") == "http://a/g", "/g");
    assert!(must_join(b, "//g") == "http://g", "//g");
    assert!(must_join(b, "?y") == "http://a/b/c/d;p?y", "?y");
    assert!(must_join(b, "g?y") == "http://a/b/c/g?y", "g?y");
    assert!(must_join(b, "#s") == "http://a/b/c/d;p?q#s", "#s");
    assert!(must_join(b, "g#s") == "http://a/b/c/g#s", "g#s");
    assert!(must_join(b, "g?y#s") == "http://a/b/c/g?y#s", "g?y#s");
    assert!(must_join(b, ";x") == "http://a/b/c/;x", ";x");
    assert!(must_join(b, "g;x") == "http://a/b/c/g;x", "g;x");
    assert!(must_join(b, "g;x?y#s") == "http://a/b/c/g;x?y#s", "g;x?y#s");
    assert!(must_join(b, "") == "http://a/b/c/d;p?q", "empty");
    assert!(must_join(b, ".") == "http://a/b/c/", ".");
    assert!(must_join(b, "./") == "http://a/b/c/", "./");
    assert!(must_join(b, "..") == "http://a/b/", "..");
    assert!(must_join(b, "../") == "http://a/b/", "../");
    assert!(must_join(b, "../g") == "http://a/b/g", "../g");
    assert!(must_join(b, "../..") == "http://a/", "../..");
    assert!(must_join(b, "../../") == "http://a/", "../../");
    assert!(must_join(b, "../../g") == "http://a/g", "../../g");
}

test("file join") {
    let b = must_parse("file:///tmp/a/b");
    assert!(must_join(b, "c") == "file:///tmp/a/c", "file rel");
    assert!(must_join(b, "/etc/passwd") == "file:///etc/passwd", "file abs");
}

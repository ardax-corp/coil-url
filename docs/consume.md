# Consuming coil-url

This package is `url`. `use url::{parse, join, Url, UrlError}` resolves from `src/url.hy`. This repo is **private** (`https://github.com/ardax-corp/coil-url.git`); clone with credentials that can read it. There is no native/FFI dep.

Coil-to-Coil deps will be spool-owned once a public `spool` CLI exists. Until then `{ git }` parses and the pin is `coil.lock` `rev` + `content_hash`.

## Sibling checkout

Clone this repo next to your project. In the consumer `coil.toml`:

```toml
[module]
roots = ["./src", "../coil-url/src"]
```

`roots` is what loads `src/url.hy`. The compiler does not follow path deps for discovery.

## Git dep and coil.lock

`{ git }` is the parseable form. `version` is optional schema, not a tag. `rev` on the dep is stored only. Do not run `spool add`. There is no public spool CLI.

```toml
[dependencies]
url = { git = "https://github.com/ardax-corp/coil-url.git" }

[module]
roots = ["./src", "./.spool/deps/url/src"]
```

This repo has no tags. The pin is `coil.lock` `rev` + `content_hash`. Omit `tag`. Use sibling checkout until spool materializes `.spool/deps`. The compiler does not read `coil.lock` and does not inject roots.

```
# spool lockfile v1
[[package]]
name = 'url'
git = 'https://github.com/ardax-corp/coil-url.git'
rev = '<commit SHA>'
content_hash = '<tree SHA>'
```

`rev` is the commit. `content_hash` is that commit's git tree (`git rev-parse 'HEAD^{tree}'`). Replace both when you move the pin.

## Call parse / join

Signatures are in [`src/url.hy`](../src/url.hy). Call patterns are in [`tests/parse.hy`](../tests/parse.hy) and [`tests/join.hy`](../tests/join.hy).

```coil
use url::{parse, join, percent_encode, percent_decode, Url, UrlError};

let u = parse("https://user@example.com:443/a/b?x=1#f")?;
let href = u.to_string();
let next = join(u, "../c?y=2")?;
let x = u.query_get("x");
let u2 = u.query_set("x", "two");
```

`parse` takes `string` and returns `Result<Url, UrlError>`. Relative references parse with an empty `scheme`. `join` takes a base `Url` and a reference string.

`to_string` / `string` rebuild the URI. Port `0` means omitted. IPv6 hosts are written in brackets.

### Url

Public fields: `scheme`, `userinfo`, `host`, `port`, `path`, `query`, `fragment`. Flags `has_authority`, `has_query`, `has_fragment` distinguish missing vs empty (`http://host?` vs no query).

```coil
let u = parse("http://example.com/path")?;
let http = u.scheme == "http" && u.host == "example.com" && u.path == "/path";
```

`query_get` returns the first matching value, percent-decoded, or `""`. `query_set` returns a new `Url`.

### UrlError

```coil
enum UrlError {
    Invalid { message: string },
}
```

Malformed input returns `UrlError::Invalid`, not a panic.

```coil
match parse("http://") {
    Result::Ok(_) => false,
    Result::Err(e) => match e {
        UrlError::Invalid { message } => message != "",
        default => false,
    },
}
```

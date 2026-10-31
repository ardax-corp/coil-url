# Consuming coil-url

This package is `url`. `use url::{parse, join, Url, UrlError}` resolves from `src/url.hy`. The repo is `https://github.com/ardax-corp/coil-url.git`. There is no native/FFI dependency.

## Depend on it

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add url --git https://github.com/ardax-corp/coil-url.git --rev <commit SHA>
```

This repo has no tags, so pin a commit with `--rev`. spool records the dep in `coil.toml`, writes `coil.lock` (`rev` + `content_hash`), links `.spool/deps/url`, and passes `--root` for it and coil-stdlib to `coil` on `spool build` / `run` / `test`.

Without spool, clone this repo next to your project and pass the roots yourself. coil reads no `coil.toml` and no `coil.lock`.

```bash
git clone https://github.com/ardax-corp/coil-url.git ../coil-url
coil --root ../coil-stdlib/src --root ../coil-url/src main.hy
```

## Call parse / join

Signatures and `///` docs with examples are in [`src/url.hy`](../src/url.hy). Call patterns are in [`tests/parse.hy`](../tests/parse.hy) and [`tests/join.hy`](../tests/join.hy).

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

`query_get` returns the first matching value, percent-decoded, or `""`. `query_set` returns a new `Url` with every pair for that key replaced, or the pair appended.

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

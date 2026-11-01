# coil-url

RFC 3986 URLs for [coil](https://github.com/ardax-corp/coil-lang), written in plain Coil (no native library, no FFI): parse, write back, resolve relative references, read and set query parameters, percent-encode and decode. The package name is `url`: `use url::{parse, join, Url, UrlError}`.

## Example

```coil
use url::{parse, percent_encode, percent_decode, UrlError};
use io::sync::{println};
use string::{format};

fn main() {
    let u = match parse("https://example.com:8443/docs/guide?q=hello%20world#top") {
        Result::Ok(u) => u,
        Result::Err(e) => match e {
            UrlError::Invalid { message } => panic "bad url: " + message,
        },
    };
    println(format("%s %s %i %s", u.scheme, u.host, u.port, u.path))?;
    println(u.query_get("q"))?;
    println(u.query_set("page", "2").to_string())?;

    match u.join("../api?v=1") {
        Result::Ok(next) => println(next.to_string())?,
        Result::Err(_) => println("bad reference")?,
    };

    println(percent_encode("a b&c"))?;
    println(percent_decode("a%20b").unwrap_or("?"))?;
}
```

```bash
coil --root ../coil-stdlib/src --root ../coil-url/src main.coil
```

## API

| Item | Role |
|------|------|
| `parse(string)` / `Url::parse` | Parse an absolute URI or a relative reference. Returns `Result<Url, UrlError>` |
| `Url` | Public fields `scheme`, `userinfo`, `host`, `port`, `path`, `query`, `fragment`, plus `has_authority` / `has_query` / `has_fragment` |
| `u.to_string()` / `u.string()` | Write the URL back out (port `0` omitted, IPv6 hosts bracketed) |
| `join(base, ref)` / `base.join(ref)` | RFC 3986 §5.2 relative resolution |
| `u.query_get(key)` | First value for `key`, percent-decoded, or `""` |
| `u.query_set(key, value)` | New `Url` with `key` set (encoded) |
| `percent_encode` / `percent_decode` | Encode every byte that is not unreserved; decode `%HH` |
| `UrlError` | `Invalid { message }` |

Missing components are `""` and port `0`; the `has_*` flags tell `http://host?` (empty query) from `http://host` (no query). Components stay percent-encoded as written; the scheme is lowercased, and the host too for `http`, `https`, `ws` and `wss`, which also require a non-empty host. Any other scheme parses as generic (`mailto:`, `git://…`), and `file:///path` has an empty host. Bad input returns `UrlError::Invalid`, never a panic.

Every public item has `///` docs with examples in [`src/url.coil`](src/url.coil).

## Layout

| Path | Role |
|------|------|
| `src/url.coil` | The whole package: `Url`, `UrlError`, parse, join, query get/set, percent coding |
| `tests/` | `coil test` suites (parse, join, query) |
| `coil.toml` | spool manifest (`[package] name = "url"`); coil itself does not read it |

## Use it

```bash
spool add url --git https://github.com/ardax-corp/coil-url.git --rev <commit SHA>
```

There are no tags yet, so pin a commit with `--rev`. Without spool, clone this repo next to your project and pass `--root ../coil-url/src` to `coil`. See [docs/consume.md](docs/consume.md).

## Test

```bash
coil test --root ../coil-stdlib/src          # tests/
coil test --root ../coil-stdlib/src src      # doc examples
```

## License

MIT. See [LICENSE](LICENSE).

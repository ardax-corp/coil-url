# coil-url

Userland RFC 3986 URLs for [coil](https://github.com/ardax-corp/coil-lang). Package name is `url`, so `use url::{parse, join, Url, UrlError}` resolves here.

This repo is **private**. There is no native library and no `[ffi] allow`.

## API

```coil
use url::{parse, join, percent_encode, percent_decode, Url, UrlError};

let u = parse("https://example.com:8443/a/b?q=1#f")?;
let s = u.to_string();
let v = join(u, "../c")?;
let q = u.query_get("q");
let u2 = u.query_set("q", "two");
let enc = percent_encode("a b");
let dec = percent_decode("a%20b")?;
```

`parse` accepts an absolute URI or a relative reference. Missing optional pieces are empty string / port `0`. Bad input returns `UrlError::Invalid`, not a panic.

| Piece | Missing |
|-------|---------|
| scheme, userinfo, host, path, query, fragment | `""` |
| port | `0` (omitted on `to_string`) |

Recognized schemes: `http`, `https`, `file`, `ws`, `wss`. Other schemes parse as generic (`git://…`). `http`/`https`/`ws`/`wss` reject an empty host. `file` allows `file:///path`.

`join(base, ref)` is RFC 3986 §5 relative resolution. Query get/set is first-key, `&`/`=` map; values are percent-decoded on get and encoded on set.

## Layout

| Path | Role |
|------|------|
| `src/url.hy` | `Url`, `UrlError`, parse/join/query/percent |
| `coil.toml` | spool manifest (`[package] name = "url"`); coil does not read it |

## Consume

```bash
spool add url --git https://github.com/ardax-corp/coil-url.git --rev <commit SHA>
```

No tags yet, so pin a commit. Without spool, pass `--root ../coil-url/src` to `coil`. See [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).

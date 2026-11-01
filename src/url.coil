// Package root. RFC 3986 URI parse, join, query, and percent-coding.
// Missing optional pieces are empty string / port 0. No native / FFI.
use string::{from_bytes, to_bytes, format};

/// Why `parse`, `join` or `percent_decode` rejected its input.
///
/// Bad input is always reported this way, never with a panic.
///
/// # Examples
///
/// ```
/// use url::{parse, UrlError};
/// # use tests::assert;
/// let why = match parse("http://example.com:99999/") {
///     Result::Ok(_) => "",
///     Result::Err(e) => match e {
///         UrlError::Invalid { message } => message,
///     },
/// };
/// assert!(why == "port range");
/// ```
enum UrlError {
    /// The input is not a valid URI reference. `message` is a short reason
    /// such as `"empty host"`, `"bad port"`, `"bad percent"` or `"whitespace"`.
    Invalid { message: string },
}

/// A parsed RFC 3986 URI or relative reference.
///
/// Each component is kept as written, still percent-encoded, except that the
/// scheme is lowercased and so is the host for `http`, `https`, `ws` and
/// `wss`. A missing component is `""` (port `0`); the `has_*` flags tell a
/// missing query, fragment or authority apart from an empty one. Methods that
/// change a `Url` return a new one and leave the original as it was.
///
/// # Examples
///
/// ```
/// use url::{parse};
/// # use tests::assert;
/// let u = match parse("HTTPS://ada@Example.com:8443/a/b?x=1#top") {
///     Result::Ok(u) => u,
///     Result::Err(_) => panic "bad url",
/// };
/// assert!(u.scheme == "https" && u.userinfo == "ada" && u.host == "example.com");
/// assert!(u.port == 8443 && u.path == "/a/b" && u.query == "x=1" && u.fragment == "top");
/// assert!(u.to_string() == "https://ada@example.com:8443/a/b?x=1#top");
/// ```
class Url {
    /// The scheme, lowercased (`"https"`), or `""` for a relative reference.
    pub scheme: string,
    /// The part before `@` in the authority (`"user:pass"`), or `""`.
    pub userinfo: string,
    /// The host, without brackets for an IPv6 literal (`"::1"`), or `""`.
    pub host: string,
    /// The port, or `0` when none is given. An explicit `:0` also reads as `0`.
    pub port: int,
    /// The path as written, still percent-encoded. May be `""`.
    pub path: string,
    /// The text after `?`, without the `?`, still percent-encoded.
    pub query: string,
    /// The text after `#`, without the `#`, still percent-encoded.
    pub fragment: string,
    /// `true` when the input had `//` and an authority (even an empty one, as in `file:///x`).
    pub has_authority: bool,
    /// `true` when the input had a `?`, even with nothing after it.
    pub has_query: bool,
    /// `true` when the input had a `#`, even with nothing after it.
    pub has_fragment: bool,
}

class Parser {
    bytes: Vec<byte>,
    i: int,
}

fn invalid(string message) -> UrlError {
    return UrlError::Invalid { message: message };
}

fn bytes_to_str(Vec<byte> b) -> Result<string, UrlError> {
    return match from_bytes(b) {
        Result::Ok(s) => s,
        Result::Err(_) => raise invalid("utf8"),
    };
}

fn slice_str(Vec<byte> b, int start, int end) -> Result<string, UrlError> {
    let out: Vec<byte> = Vec::new();
    let i = start;
    while i < end {
        out.push(b[i]);
        i = i + 1;
    }
    return bytes_to_str(out)?;
}

fn is_alpha(byte c) -> bool {
    if c >= "A" && c <= "Z" {
        return true;
    }
    return c >= "a" && c <= "z";
}

fn is_digit(byte c) -> bool {
    return c >= "0" && c <= "9";
}

fn is_hex(byte c) -> bool {
    if is_digit(c) {
        return true;
    }
    if c >= "A" && c <= "F" {
        return true;
    }
    return c >= "a" && c <= "f";
}

fn is_unreserved(byte c) -> bool {
    if is_alpha(c) {
        return true;
    }
    if is_digit(c) {
        return true;
    }
    if c == "-" || c == "." || c == "_" || c == "~" {
        return true;
    }
    return false;
}

fn is_scheme_char(byte c) -> bool {
    if is_alpha(c) {
        return true;
    }
    if is_digit(c) {
        return true;
    }
    return c == "+" || c == "-" || c == ".";
}

fn ascii_lower_byte(byte c) -> byte {
    if c >= "A" && c <= "Z" {
        let n = (c as int) + 32;
        return n as byte;
    }
    return c;
}

fn ascii_lower(string s) -> Result<string, UrlError> {
    let b = to_bytes(s);
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < b.len() {
        out.push(ascii_lower_byte(b[i]));
        i = i + 1;
    }
    return bytes_to_str(out)?;
}

fn hex_val(byte c) -> int {
    if c >= "0" && c <= "9" {
        return (c as int) - ("0" as byte as int);
    }
    if c >= "a" && c <= "f" {
        return (c as int) - ("a" as byte as int) + 10;
    }
    if c >= "A" && c <= "F" {
        return (c as int) - ("A" as byte as int) + 10;
    }
    return -1;
}

fn hex_digit(int n) -> byte {
    let ten: int = 10;
    if n < ten {
        let d = ("0" as byte as int) + n;
        return d as byte;
    }
    let d = ("A" as byte as int) + (n - ten);
    return d as byte;
}

fn host_needs_brackets(string host) -> bool {
    let b = to_bytes(host);
    let i = 0;
    while i < b.len() {
        if b[i] == ":" {
            return true;
        }
        i = i + 1;
    }
    return false;
}

fn is_http_family(string scheme) -> bool {
    return scheme == "http" || scheme == "https" || scheme == "ws" || scheme == "wss";
}

/// Percent-encodes every byte of `s` that is not an RFC 3986 unreserved character.
///
/// Letters, digits and `-` `.` `_` `~` are kept; every other byte, including
/// each byte of a multi-byte UTF-8 character, becomes `%HH` with uppercase hex.
/// A space becomes `%20`, never `+`.
///
/// # Examples
///
/// ```
/// use url::{percent_encode};
/// # use tests::assert;
/// assert!(percent_encode("a b/c") == "a%20b%2Fc");
/// assert!(percent_encode("caf\u{e9}") == "caf%C3%A9");
/// assert!(percent_encode("safe-._~") == "safe-._~");
/// ```
fn percent_encode(string s) -> string {
    let b = to_bytes(s);
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < b.len() {
        let c = b[i];
        if is_unreserved(c) {
            out.push(c);
        } else {
            let n = c as int;
            out.push("%" as byte);
            out.push(hex_digit(n / 16));
            out.push(hex_digit(n % 16));
        }
        i = i + 1;
    }
    return match from_bytes(out) {
        Result::Ok(t) => t,
        Result::Err(_) => "",
    };
}

/// Decodes the `%HH` sequences in `s`; other bytes are kept as they are.
///
/// `+` is not turned into a space. Returns `UrlError::Invalid` when a `%` is
/// not followed by two hex digits (`"truncated percent"`, `"bad percent"`) or
/// when the decoded bytes are not valid UTF-8 (`"utf8"`).
///
/// # Examples
///
/// ```
/// use url::{percent_decode, percent_encode};
/// # use tests::assert;
/// assert!(percent_decode("a%20b").unwrap_or("") == "a b");
/// assert!(percent_decode("caf%C3%A9").unwrap_or("") == "caf\u{e9}");
/// assert!(percent_decode("100%").is_err());
/// assert!(percent_decode(percent_encode("x=1&y")).unwrap_or("") == "x=1&y");
/// ```
fn percent_decode(string s) -> Result<string, UrlError> {
    let b = to_bytes(s);
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < b.len() {
        let c = b[i];
        if c == "%" {
            if i + 2 >= b.len() {
                raise invalid("truncated percent");
            }
            let hi = hex_val(b[i + 1]);
            let lo = hex_val(b[i + 2]);
            if hi < 0 || lo < 0 {
                raise invalid("bad percent");
            }
            let sixteen: int = 16;
            let n = hi * sixteen + lo;
            out.push(n as byte);
            i = i + 3;
            continue;
        }
        out.push(c);
        i = i + 1;
    }
    return bytes_to_str(out)?;
}

fn check_pct(Vec<byte> b, int start, int end) -> Result<(), UrlError> {
    let i = start;
    while i < end {
        if b[i] == "%" {
            if i + 2 >= end {
                raise invalid("truncated percent");
            }
            if !is_hex(b[i + 1]) || !is_hex(b[i + 2]) {
                raise invalid("bad percent");
            }
            i = i + 3;
            continue;
        }
        if b[i] <= " " {
            raise invalid("whitespace");
        }
        i = i + 1;
    }
    return ();
}

fn last_slash(string s) -> int {
    let b = to_bytes(s);
    let i = b.len();
    while i > 0 {
        i = i - 1;
        if b[i] == "/" {
            return i;
        }
    }
    return -1;
}

fn starts_with_str(string s, string prefix) -> bool {
    let a = to_bytes(s);
    let p = to_bytes(prefix);
    if p.len() > a.len() {
        return false;
    }
    let i = 0;
    while i < p.len() {
        if a[i] != p[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn merge_path(string base_path, bool has_authority, string rel) -> Result<string, UrlError> {
    if has_authority {
        if base_path == "" {
            return "/" + rel;
        }
    }
    let at = last_slash(base_path);
    if at < 0 {
        return rel;
    }
    let bb = to_bytes(base_path);
    let left = slice_str(bb, 0, at + 1)?;
    return left + rel;
}

fn starts_with_bytes(Vec<byte> b, string prefix) -> bool {
    let p = to_bytes(prefix);
    if p.len() > b.len() {
        return false;
    }
    let i = 0;
    while i < p.len() {
        if b[i] != p[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn eq_bytes(Vec<byte> b, string s) -> bool {
    let p = to_bytes(s);
    if p.len() != b.len() {
        return false;
    }
    let i = 0;
    while i < p.len() {
        if b[i] != p[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn drop_n(Vec<byte> b, int n) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = n;
    while i < b.len() {
        out.push(b[i]);
        i = i + 1;
    }
    return out;
}

fn replace_prefix(Vec<byte> b, int skip) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    out.push("/" as byte);
    let i = skip + 1;
    while i < b.len() {
        out.push(b[i]);
        i = i + 1;
    }
    return out;
}

fn pop_segment(Vec<byte> out) -> Vec<byte> {
    let n = out.len();
    if n == 0 {
        return out;
    }
    let i = n;
    while i > 0 {
        i = i - 1;
        if out[i] == "/" {
            let cut = i;
            let dst: Vec<byte> = Vec::new();
            let k = 0;
            while k < cut {
                dst.push(out[k]);
                k = k + 1;
            }
            return dst;
        }
    }
    let empty: Vec<byte> = Vec::new();
    return empty;
}

fn next_segment(Vec<byte> inp) -> (Vec<byte>, Vec<byte>) {
    let n = inp.len();
    let i = 0;
    if n > 0 {
        if inp[0] == "/" {
            i = 1;
        }
    }
    while i < n {
        if inp[i] == "/" {
            break;
        }
        i = i + 1;
    }
    let seg: Vec<byte> = Vec::new();
    let k = 0;
    while k < i {
        seg.push(inp[k]);
        k = k + 1;
    }
    let rest: Vec<byte> = Vec::new();
    while i < n {
        rest.push(inp[i]);
        i = i + 1;
    }
    return (seg, rest);
}

fn remove_dot_segments(string path) -> Result<string, UrlError> {
    let inp = to_bytes(path);
    let out: Vec<byte> = Vec::new();
    while inp.len() > 0 {
        if starts_with_bytes(inp, "../") {
            inp = drop_n(inp, 3);
            continue;
        }
        if starts_with_bytes(inp, "./") {
            inp = drop_n(inp, 2);
            continue;
        }
        if eq_bytes(inp, ".") {
            inp = drop_n(inp, 1);
            continue;
        }
        if eq_bytes(inp, "..") {
            inp = drop_n(inp, 2);
            continue;
        }
        if starts_with_bytes(inp, "/./") {
            inp = replace_prefix(inp, 2);
            continue;
        }
        if eq_bytes(inp, "/.") {
            inp = to_bytes("/");
            continue;
        }
        if starts_with_bytes(inp, "/../") {
            inp = replace_prefix(inp, 3);
            out = pop_segment(out);
            continue;
        }
        if eq_bytes(inp, "/..") {
            inp = to_bytes("/");
            out = pop_segment(out);
            continue;
        }
        let (seg, rest) = next_segment(inp);
        let k = 0;
        while k < seg.len() {
            out.push(seg[k]);
            k = k + 1;
        }
        inp = rest;
    }
    return bytes_to_str(out)?;
}

fn first_colon_in_segment(Vec<byte> b, int start, int end) -> int {
    let i = start;
    while i < end {
        if b[i] == "/" || b[i] == "?" || b[i] == "#" {
            return -1;
        }
        if b[i] == ":" {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

impl Parser {
    pub fn at_end() -> bool {
        return self.i >= self.bytes.len();
    }

    fn cur() -> byte {
        return self.bytes[self.i];
    }

    fn peek_eq(byte c) -> bool {
        if self.at_end() {
            return false;
        }
        return self.cur() == c;
    }

    fn find_from(int start, byte c, int limit) -> int {
        let i = start;
        while i < limit {
            if self.bytes[i] == c {
                return i;
            }
            i = i + 1;
        }
        return -1;
    }

    fn hier_limit() -> int {
        let n = self.bytes.len();
        let i = self.i;
        while i < n {
            let c = self.bytes[i];
            if c == "/" || c == "?" || c == "#" {
                return i;
            }
            i = i + 1;
        }
        return n;
    }

    fn parse_scheme() -> Result<string, UrlError> {
        if self.at_end() {
            return "";
        }
        if !is_alpha(self.cur()) {
            return "";
        }
        let start = self.i;
        let j = self.i + 1;
        let n = self.bytes.len();
        while j < n {
            if !is_scheme_char(self.bytes[j]) {
                break;
            }
            j = j + 1;
        }
        if j >= n {
            return "";
        }
        if self.bytes[j] != ":" {
            return "";
        }
        let raw = slice_str(self.bytes, start, j)?;
        self.i = j + 1;
        return ascii_lower(raw)?;
    }

    fn parse_port(int start, int end) -> Result<int, UrlError> {
        if start >= end {
            return 0;
        }
        let port = 0;
        let i = start;
        while i < end {
            if !is_digit(self.bytes[i]) {
                raise invalid("bad port");
            }
            port = port * 10 + ((self.bytes[i] as int) - ("0" as byte as int));
            if port > 65535 {
                raise invalid("port range");
            }
            i = i + 1;
        }
        return port;
    }

    fn parse_authority(int limit) -> Result<(string, string, int), UrlError> {
        check_pct(self.bytes, self.i, limit)?;
        let at = self.find_from(self.i, "@", limit);
        let host_start = self.i;
        let userinfo = "";
        if at >= 0 {
            userinfo = slice_str(self.bytes, self.i, at)?;
            host_start = at + 1;
        }
        if host_start >= limit {
            self.i = limit;
            return ("", "", 0);
        }
        let host = "";
        let port_start = limit;
        if self.bytes[host_start] == "[" {
            let close = self.find_from(host_start + 1, "]", limit);
            if close < 0 {
                raise invalid("unclosed ipv6");
            }
            host = slice_str(self.bytes, host_start + 1, close)?;
            let after = close + 1;
            if after < limit {
                if self.bytes[after] != ":" {
                    raise invalid("junk after ipv6");
                }
                port_start = after + 1;
            } else {
                port_start = limit;
            }
        } else {
            let colon = self.find_from(host_start, ":", limit);
            let slashish = self.find_from(host_start, "/", limit);
            if colon >= 0 {
                if slashish < 0 || colon < slashish {
                    host = slice_str(self.bytes, host_start, colon)?;
                    port_start = colon + 1;
                } else {
                    host = slice_str(self.bytes, host_start, limit)?;
                    port_start = limit;
                }
            } else {
                host = slice_str(self.bytes, host_start, limit)?;
                port_start = limit;
            }
        }
        let port = self.parse_port(port_start, limit)?;
        self.i = limit;
        return (userinfo, host, port);
    }

    fn parse_until(byte stop1, byte stop2) -> Result<string, UrlError> {
        let start = self.i;
        let n = self.bytes.len();
        while self.i < n {
            let c = self.cur();
            if c == stop1 || c == stop2 {
                break;
            }
            self.i = self.i + 1;
        }
        check_pct(self.bytes, start, self.i)?;
        return slice_str(self.bytes, start, self.i)?;
    }

    pub fn parse_url() -> Result<Url, UrlError> {
        let n = self.bytes.len();
        if n == 0 {
            return new Url("", "", "", 0, "", "", "", false, false, false);
        }
        let i = 0;
        while i < n {
            if self.bytes[i] <= " " {
                raise invalid("whitespace");
            }
            i = i + 1;
        }
        let scheme = self.parse_scheme()?;
        let has_authority = false;
        let userinfo = "";
        let host = "";
        let port = 0;
        if self.peek_eq("/") {
            if self.i + 1 < n {
                if self.bytes[self.i + 1] == "/" {
                    has_authority = true;
                    self.i = self.i + 2;
                    let auth_end = self.hier_limit();
                    let (u, h, p) = self.parse_authority(auth_end)?;
                    userinfo = u;
                    host = h;
                    port = p;
                    if host == "" {
                        if is_http_family(scheme) {
                            raise invalid("empty host");
                        }
                    } else {
                        if is_http_family(scheme) {
                            host = ascii_lower(host)?;
                        }
                    }
                }
            }
        }
        let path = self.parse_until("?", "#")?;
        if scheme == "" {
            let colon = first_colon_in_segment(to_bytes(path), 0, to_bytes(path).len());
            if colon >= 0 {
                raise invalid("colon in relative path");
            }
        }
        let has_query = false;
        let query = "";
        if self.peek_eq("?") {
            has_query = true;
            self.i = self.i + 1;
            query = self.parse_until("#", "#")?;
        }
        let has_fragment = false;
        let fragment = "";
        if self.peek_eq("#") {
            has_fragment = true;
            self.i = self.i + 1;
            let start = self.i;
            self.i = self.bytes.len();
            check_pct(self.bytes, start, self.i)?;
            fragment = slice_str(self.bytes, start, self.i)?;
        }
        if !self.at_end() {
            raise invalid("trailing");
        }
        return new Url(
            scheme,
            userinfo,
            host,
            port,
            path,
            query,
            fragment,
            has_authority,
            has_query,
            has_fragment,
        );
    }
}

fn query_pair_key(string pair) -> Result<string, UrlError> {
    let b = to_bytes(pair);
    let i = 0;
    while i < b.len() {
        if b[i] == "=" {
            return percent_decode(slice_str(b, 0, i)?)?;
        }
        i = i + 1;
    }
    return percent_decode(pair)?;
}

fn query_pair_value(string pair) -> Result<string, UrlError> {
    let b = to_bytes(pair);
    let i = 0;
    while i < b.len() {
        if b[i] == "=" {
            return percent_decode(slice_str(b, i + 1, b.len())?)?;
        }
        i = i + 1;
    }
    return "";
}

fn split_amp(string s) -> Result<Vec<string>, UrlError> {
    let b = to_bytes(s);
    let out: Vec<string> = Vec::new();
    let start = 0;
    let i = 0;
    while i < b.len() {
        if b[i] == "&" {
            out.push(slice_str(b, start, i)?);
            start = i + 1;
        }
        i = i + 1;
    }
    out.push(slice_str(b, start, b.len())?);
    return out;
}

impl Url {
    /// Parses an absolute URI or a relative reference. Same as the free `parse`.
    ///
    /// See `parse` for what is accepted and the errors.
    ///
    /// # Examples
    ///
    /// ```
    /// use url::{Url};
    /// # use tests::assert;
    /// let u = match Url::parse("ws://localhost:9000/chat") {
    ///     Result::Ok(u) => u,
    ///     Result::Err(_) => panic "bad url",
    /// };
    /// assert!(u.host == "localhost" && u.port == 9000);
    /// assert!(Url::parse("http://").is_err());
    /// ```
    pub static fn parse(string s) -> Result<Url, UrlError> {
        let p = new Parser(to_bytes(s), 0);
        return p.parse_url()?;
    }

    /// Writes the URL back out as text (RFC 3986 §5.3 recomposition).
    ///
    /// Components are written as stored, so parsing and writing back gives the
    /// input again, apart from the lowercased scheme and host and a dropped
    /// empty or `:0` port. Port `0` is left out, and a host with a `:` (IPv6)
    /// is wrapped in `[` `]`.
    ///
    /// # Examples
    ///
    /// ```
    /// use url::{parse};
    /// # use tests::assert;
    /// let u = match parse("HTTP://[::1]:8080/x?") {
    ///     Result::Ok(u) => u,
    ///     Result::Err(_) => panic "bad url",
    /// };
    /// assert!(u.to_string() == "http://[::1]:8080/x?");
    /// ```
    pub fn to_string() -> string {
        let out = "";
        if self.scheme != "" {
            out = out + self.scheme + ":";
        }
        if self.has_authority {
            out = out + "//";
            if self.userinfo != "" {
                out = out + self.userinfo + "@";
            }
            if host_needs_brackets(self.host) {
                out = out + "[" + self.host + "]";
            } else {
                out = out + self.host;
            }
            if self.port != 0 {
                out = out + ":" + format("%i", self.port);
            }
        }
        out = out + self.path;
        if self.has_query {
            out = out + "?" + self.query;
        }
        if self.has_fragment {
            out = out + "#" + self.fragment;
        }
        return out;
    }

    /// Same as `to_string`.
    pub fn string() -> string {
        return self.to_string();
    }

    /// Returns the value of the first `key=value` pair in the query, percent-decoded.
    ///
    /// The query is split on `&` and each pair on its first `=`; keys are
    /// percent-decoded before they are compared with `key`. Returns `""` when
    /// the key is missing, has no `=`, or does not decode. Use `has_query` and
    /// the raw `query` field to tell those cases apart.
    ///
    /// # Examples
    ///
    /// ```
    /// use url::{parse};
    /// # use tests::assert;
    /// let u = match parse("https://example.com/search?q=hello%20world&page=2&page=3") {
    ///     Result::Ok(u) => u,
    ///     Result::Err(_) => panic "bad url",
    /// };
    /// assert!(u.query_get("q") == "hello world");
    /// assert!(u.query_get("page") == "2");
    /// assert!(u.query_get("lang") == "");
    /// ```
    pub fn query_get(string key) -> string {
        if !self.has_query {
            return "";
        }
        let parts = match split_amp(self.query) {
            Result::Ok(v) => v,
            Result::Err(_) => {
                let empty: Vec<string> = Vec::new();
                empty
            },
        };
        let i = 0;
        while i < parts.len() {
            let k = match query_pair_key(parts[i]) {
                Result::Ok(x) => x,
                Result::Err(_) => "",
            };
            if k == key {
                return match query_pair_value(parts[i]) {
                    Result::Ok(v) => v,
                    Result::Err(_) => "",
                };
            }
            i = i + 1;
        }
        return "";
    }

    /// Returns a copy of this URL with `key` set to `value` in the query.
    ///
    /// `key` and `value` are percent-encoded. Every existing pair with that key
    /// is replaced; when there is none, the pair is appended (or becomes the
    /// whole query). Other pairs keep their order and spelling. `self` is not
    /// changed.
    ///
    /// # Examples
    ///
    /// ```
    /// use url::{parse};
    /// # use tests::assert;
    /// let u = match parse("http://example.com/p?a=1&b=2") {
    ///     Result::Ok(u) => u,
    ///     Result::Err(_) => panic "bad url",
    /// };
    /// assert!(u.query_set("a", "x y").to_string() == "http://example.com/p?a=x%20y&b=2");
    /// assert!(u.query_set("c", "3").to_string() == "http://example.com/p?a=1&b=2&c=3");
    /// assert!(u.query == "a=1&b=2");
    /// ```
    pub fn query_set(string key, string value) -> Url {
        let ek = percent_encode(key);
        let ev = percent_encode(value);
        let parts = match split_amp(self.query) {
            Result::Ok(v) => v,
            Result::Err(_) => {
                let empty: Vec<string> = Vec::new();
                empty
            },
        };
        let outq = "";
        let found = false;
        let i = 0;
        if self.has_query {
            while i < parts.len() {
                let pair = parts[i];
                let k = match query_pair_key(pair) {
                    Result::Ok(x) => x,
                    Result::Err(_) => "",
                };
                let next = "";
                if k == key {
                    next = ek + "=" + ev;
                    found = true;
                } else {
                    next = pair;
                }
                if outq == "" {
                    if i == 0 {
                        outq = next;
                    } else {
                        outq = outq + "&" + next;
                    }
                } else {
                    outq = outq + "&" + next;
                }
                i = i + 1;
            }
        }
        if !found {
            if outq == "" {
                outq = ek + "=" + ev;
            } else {
                outq = outq + "&" + ek + "=" + ev;
            }
        }
        return new Url(
            self.scheme,
            self.userinfo,
            self.host,
            self.port,
            self.path,
            outq,
            self.fragment,
            self.has_authority,
            true,
            self.has_fragment,
        );
    }

    /// Resolves `reference` against this URL as a base (RFC 3986 §5.2). Same as the free `join`.
    ///
    /// See `join` for the rules and the errors.
    ///
    /// # Examples
    ///
    /// ```
    /// use url::{parse};
    /// # use tests::assert;
    /// let u = match parse("https://example.com/docs/guide/intro") {
    ///     Result::Ok(u) => u,
    ///     Result::Err(_) => panic "bad url",
    /// };
    /// let next = match u.join("../api") {
    ///     Result::Ok(v) => v,
    ///     Result::Err(_) => panic "bad reference",
    /// };
    /// assert!(next.to_string() == "https://example.com/docs/api");
    /// ```
    pub fn join(string reference) -> Result<Url, UrlError> {
        let r = Url::parse(reference)?;
        let t_scheme = "";
        let t_user = "";
        let t_host = "";
        let t_port = 0;
        let t_path = "";
        let t_query = "";
        let t_frag = r.fragment;
        let t_auth = false;
        let t_has_q = false;
        let t_has_f = r.has_fragment;
        if r.scheme != "" {
            t_scheme = r.scheme;
            t_user = r.userinfo;
            t_host = r.host;
            t_port = r.port;
            t_path = remove_dot_segments(r.path)?;
            t_query = r.query;
            t_auth = r.has_authority;
            t_has_q = r.has_query;
        } else {
            if r.has_authority {
                t_user = r.userinfo;
                t_host = r.host;
                t_port = r.port;
                t_path = remove_dot_segments(r.path)?;
                t_query = r.query;
                t_auth = true;
                t_has_q = r.has_query;
            } else {
                if r.path == "" {
                    t_path = self.path;
                    if r.has_query {
                        t_query = r.query;
                        t_has_q = true;
                    } else {
                        t_query = self.query;
                        t_has_q = self.has_query;
                    }
                } else {
                    if starts_with_str(r.path, "/") {
                        t_path = remove_dot_segments(r.path)?;
                    } else {
                        let merged = merge_path(self.path, self.has_authority, r.path)?;
                        t_path = remove_dot_segments(merged)?;
                    }
                    t_query = r.query;
                    t_has_q = r.has_query;
                }
                t_user = self.userinfo;
                t_host = self.host;
                t_port = self.port;
                t_auth = self.has_authority;
            }
            t_scheme = self.scheme;
        }
        return new Url(
            t_scheme,
            t_user,
            t_host,
            t_port,
            t_path,
            t_query,
            t_frag,
            t_auth,
            t_has_q,
            t_has_f,
        );
    }
}

/// Parses an absolute URI (`https://host/path`) or a relative reference (`../a?b`).
///
/// A reference without a scheme gets `scheme == ""`. Empty input is an empty
/// relative reference. The scheme and, for `http`, `https`, `ws` and `wss`, the
/// host are lowercased; everything else is kept as written. Any scheme parses
/// (`mailto:`, `git:`); `file:///path` has an empty host.
///
/// Returns `UrlError::Invalid` for whitespace or control characters, a `%` not
/// followed by two hex digits, a non-numeric port or one above 65535, an
/// unclosed `[` IPv6 host, an empty host for `http`/`https`/`ws`/`wss`, or a
/// `:` in the first segment of a relative path (`a:b` is read as a scheme, so
/// write `./a:b`).
///
/// # Examples
///
/// ```
/// use url::{parse};
/// # use tests::assert;
/// let u = match parse("https://example.com/a/b?q=1#f") {
///     Result::Ok(u) => u,
///     Result::Err(_) => panic "bad url",
/// };
/// assert!(u.host == "example.com" && u.path == "/a/b");
/// assert!(u.query_get("q") == "1");
///
/// let rel = match parse("../c?x") {
///     Result::Ok(u) => u,
///     Result::Err(_) => panic "bad url",
/// };
/// assert!(rel.scheme == "" && rel.path == "../c" && rel.has_query);
///
/// assert!(parse("http://").is_err());
/// assert!(parse("http://h/a b").is_err());
/// ```
fn parse(string s) -> Result<Url, UrlError> {
    return Url::parse(s)?;
}

/// Resolves `reference` against `base` (RFC 3986 §5.2), the way a browser follows a link.
///
/// A reference with a scheme replaces the base; one starting with `//`
/// keeps only the base's scheme; an absolute path keeps the base's authority;
/// a relative path is merged with the base path's directory. `.` and `..`
/// segments are removed. An empty reference keeps the base path and query;
/// the fragment always comes from `reference`. Returns `UrlError::Invalid` when
/// `reference` does not parse.
///
/// # Examples
///
/// ```
/// use url::{parse, join, Url};
/// # use tests::assert;
///
/// fn resolve(Url base, string r) -> string {
///     return match join(base, r) {
///         Result::Ok(v) => v.to_string(),
///         Result::Err(_) => "error",
///     };
/// }
///
/// fn main() {
///     let u = match parse("http://a/b/c/d;p?q") {
///         Result::Ok(u) => u,
///         Result::Err(_) => panic "bad url",
///     };
///     assert!(resolve(u, "g") == "http://a/b/c/g");
///     assert!(resolve(u, "../g") == "http://a/b/g");
///     assert!(resolve(u, "/g") == "http://a/g");
///     assert!(resolve(u, "//cdn/g") == "http://cdn/g");
///     assert!(resolve(u, "?y") == "http://a/b/c/d;p?y");
///     assert!(resolve(u, "#s") == "http://a/b/c/d;p?q#s");
/// }
/// ```
fn join(Url base, string reference) -> Result<Url, UrlError> {
    return base.join(reference)?;
}

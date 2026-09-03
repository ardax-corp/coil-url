// Package root. RFC 3986 URI parse, join, query, and percent-coding.
// Missing optional pieces are empty string / port 0. No native / FFI.
use string::{from_bytes, to_bytes, format};

/// Parse / join / percent-decode failure. `message` is a short reason, not a panic.
enum UrlError {
    Invalid { message: string },
}

/// RFC 3986 URI or relative reference.
class Url {
    pub scheme: string,
    pub userinfo: string,
    pub host: string,
    pub port: int,
    pub path: string,
    pub query: string,
    pub fragment: string,
    pub has_authority: bool,
    pub has_query: bool,
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
    while i < len(b) {
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
    while i < len(b) {
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

/// Percent-encode bytes that are not RFC 3986 unreserved.
fn percent_encode(string s) -> string {
    let b = to_bytes(s);
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < len(b) {
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

/// Percent-decode `%HH` sequences. Invalid encodings are `UrlError`.
fn percent_decode(string s) -> Result<string, UrlError> {
    let b = to_bytes(s);
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < len(b) {
        let c = b[i];
        if c == "%" {
            if i + 2 >= len(b) {
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
    let i = len(b);
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
    if len(p) > len(a) {
        return false;
    }
    let i = 0;
    while i < len(p) {
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
    if len(p) > len(b) {
        return false;
    }
    let i = 0;
    while i < len(p) {
        if b[i] != p[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn eq_bytes(Vec<byte> b, string s) -> bool {
    let p = to_bytes(s);
    if len(p) != len(b) {
        return false;
    }
    let i = 0;
    while i < len(p) {
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
    while i < len(b) {
        out.push(b[i]);
        i = i + 1;
    }
    return out;
}

fn replace_prefix(Vec<byte> b, int skip) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    out.push("/" as byte);
    let i = skip + 1;
    while i < len(b) {
        out.push(b[i]);
        i = i + 1;
    }
    return out;
}

fn pop_segment(Vec<byte> out) -> Vec<byte> {
    let n = len(out);
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
    let n = len(inp);
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
    while len(inp) > 0 {
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
        while k < len(seg) {
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
        return self.i >= len(self.bytes);
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
        let n = len(self.bytes);
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
        let n = len(self.bytes);
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
        let n = len(self.bytes);
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
        let n = len(self.bytes);
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
            let colon = first_colon_in_segment(to_bytes(path), 0, len(to_bytes(path)));
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
            self.i = len(self.bytes);
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
    while i < len(b) {
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
    while i < len(b) {
        if b[i] == "=" {
            return percent_decode(slice_str(b, i + 1, len(b))?)?;
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
    while i < len(b) {
        if b[i] == "&" {
            out.push(slice_str(b, start, i)?);
            start = i + 1;
        }
        i = i + 1;
    }
    out.push(slice_str(b, start, len(b))?);
    return out;
}

impl Url {
    /// Parse an absolute URI or relative reference.
    pub static fn parse(string s) -> Result<Url, UrlError> {
        let p = new Parser(to_bytes(s), 0);
        return p.parse_url()?;
    }

    /// RFC 3986 reconstruction. Port 0 is omitted.
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

    pub fn string() -> string {
        return self.to_string();
    }

    /// First matching query value, percent-decoded. Missing key → empty string.
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
        while i < len(parts) {
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

    /// Set or replace `key` (encoded). Returns a new `Url`.
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
            while i < len(parts) {
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

    /// RFC 3986 relative resolution against `self`.
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

/// Parse an absolute URI or relative reference.
fn parse(string s) -> Result<Url, UrlError> {
    return Url::parse(s)?;
}

/// Resolve `reference` against `base` (RFC 3986 §5).
fn join(Url base, string reference) -> Result<Url, UrlError> {
    return base.join(reference)?;
}

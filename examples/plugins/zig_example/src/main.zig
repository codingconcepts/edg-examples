var alloc_buf: [65536]u8 = undefined;
var alloc_len: usize = 0;

export fn alloc(size: i32) i32 {
    alloc_len = @intCast(@as(u32, @bitCast(size)));
    return @intCast(@intFromPtr(&alloc_buf));
}

fn writeToMemory(data: []const u8) i64 {
    _ = alloc(@intCast(data.len));
    @memcpy(alloc_buf[0..data.len], data);
    const ptr: u64 = @intFromPtr(&alloc_buf);
    const len: u64 = data.len;
    return @bitCast((ptr << 32) | len);
}

fn writeError(msg: []const u8) i64 {
    var buf: [512]u8 = undefined;
    const prefix = "{\"error\":\"";
    const suffix = "\"}";
    const total = prefix.len + msg.len + suffix.len;
    if (total > buf.len) return writeToMemory("{\"error\":\"error too long\"}");
    @memcpy(buf[0..prefix.len], prefix);
    @memcpy(buf[prefix.len .. prefix.len + msg.len], msg);
    @memcpy(buf[prefix.len + msg.len .. total], suffix);
    return writeToMemory(buf[0..total]);
}

fn writeJsonString(s: []const u8) i64 {
    var buf: [65536]u8 = undefined;
    var pos: usize = 0;

    buf[pos] = '"';
    pos += 1;

    for (s) |c| {
        if (pos + 2 >= buf.len) return writeError("output too long");
        switch (c) {
            '"' => {
                buf[pos] = '\\';
                buf[pos + 1] = '"';
                pos += 2;
            },
            '\\' => {
                buf[pos] = '\\';
                buf[pos + 1] = '\\';
                pos += 2;
            },
            else => {
                buf[pos] = c;
                pos += 1;
            },
        }
    }

    buf[pos] = '"';
    pos += 1;

    return writeToMemory(buf[0..pos]);
}

const manifest =
    \\{"name":"zig_example","functions":[{"name":"slug","description":"Convert a string to a URL-friendly slug.","example":"slug('Hello World')","params":[{"name":"input","type":"string"}],"returns":"string"},{"name":"rot13","description":"Apply ROT13 cipher to a string.","example":"rot13('Hello')","params":[{"name":"input","type":"string"}],"returns":"string"}]}
;

export fn describe() i64 {
    return writeToMemory(manifest);
}

export fn call(fn_id: i32, arg_ptr: i32, arg_len: i32) i64 {
    const ptr: [*]const u8 = @ptrFromInt(@as(usize, @intCast(@as(u32, @bitCast(arg_ptr)))));
    const raw = ptr[0..@as(usize, @intCast(@as(u32, @bitCast(arg_len))))];

    const str_arg = extractFirstJsonString(raw) orelse return writeError("expected string argument");

    return switch (fn_id) {
        0 => slug(str_arg),
        1 => rot13(str_arg),
        else => writeError("invalid function ID"),
    };
}

fn slug(input: []const u8) i64 {
    var buf: [65536]u8 = undefined;
    var pos: usize = 0;

    for (input) |c| {
        if (pos >= buf.len) break;
        if (c >= 'A' and c <= 'Z') {
            buf[pos] = c + 32;
            pos += 1;
        } else if ((c >= 'a' and c <= 'z') or (c >= '0' and c <= '9')) {
            buf[pos] = c;
            pos += 1;
        } else if (c == ' ' or c == '_') {
            if (pos > 0 and buf[pos - 1] != '-') {
                buf[pos] = '-';
                pos += 1;
            }
        }
    }

    while (pos > 0 and buf[pos - 1] == '-') pos -= 1;

    return writeJsonString(buf[0..pos]);
}

fn rot13(input: []const u8) i64 {
    var buf: [65536]u8 = undefined;
    const len = @min(input.len, buf.len);

    for (input[0..len], 0..) |c, i| {
        if (c >= 'a' and c <= 'z') {
            buf[i] = 'a' + (c - 'a' + 13) % 26;
        } else if (c >= 'A' and c <= 'Z') {
            buf[i] = 'A' + (c - 'A' + 13) % 26;
        } else {
            buf[i] = c;
        }
    }

    return writeJsonString(buf[0..len]);
}

fn extractFirstJsonString(json: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i < json.len and json[i] != '"') : (i += 1) {}
    i += 1;
    if (i >= json.len) return null;

    const start = i;
    while (i < json.len) : (i += 1) {
        if (json[i] == '\\') {
            i += 1;
            continue;
        }
        if (json[i] == '"') return json[start..i];
    }
    return null;
}

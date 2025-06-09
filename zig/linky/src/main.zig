const std = @import("std");
const zap = @import("zap");

fn dispatch_routes(r: zap.Request) !void {
    if (r.path) |path| {
        if (routes.get(path)) |handler| {
            try handler(r);
            return;
        }
    }

    try r.sendBody("default response");
}

var routes: std.StringHashMap(zap.HttpRequestFn) = undefined;

fn test_handler(r: zap.Request) !void {
    r.sendBody("it works!") catch return;
}

fn build_routes(a: std.mem.Allocator) !void {
    routes = std.StringHashMap(zap.HttpRequestFn).init(a);
    try routes.put("/test", test_handler);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try build_routes(allocator);
    var listener = zap.HttpListener.init(.{
        .port = 8080,
        .on_request = dispatch_routes,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on :8080\n", .{});

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}

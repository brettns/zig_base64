const std = @import("std");
const b64 = @import("b64.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <base64_input>\n", .{args[0]});
        return;
    }

    const result = try b64.decode(allocator, args[1]);
    defer allocator.free(result);
    std.debug.print("{s}", .{result});
}

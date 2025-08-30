const std = @import("std");
const dia = @import("dia");

pub fn main() !void {
    std.debug.print("🧪 Testing dia framework connection...\n", .{});

    // Test framework initialization and version
    try dia.test_connection();

    std.debug.print("✅ All tests passed! dia framework is working correctly.\n", .{});
}

const std = @import("std");

const BitQueue = struct {
    const Self = @This();
    queue: u32 = 0,
    count: u5 = 0,

    pub fn enqueue(self: *Self, value: u8) void {
        // first two bits are always 0 so no need to truncate 8 to 6
        self.queue = (self.queue << 6) | value;
        self.count += 6;
    }

    pub fn dequeue(self: *Self) u8 {
        if (self.count < 8) @panic("cannot dequeue!");

        // Get the value
        const shift_amount: u5 = self.count - 8;
        const result: u8 = @intCast(self.queue >> shift_amount);

        // Remove the bits from the queue
        self.queue &= (@as(u32, 1) << shift_amount) - 1;
        self.count -= 8;
        return result;
    }
};

pub fn decode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const padding = count_padding(input);
    const length = ((input.len - padding) * 6) / 8;
    var output = try allocator.alloc(u8, length);
    errdefer allocator.free(output);
    var byte_index: usize = 0;
    var bit_queue = BitQueue{};

    for (input[0 .. input.len - padding]) |c| {
        bit_queue.enqueue(switch (c) {
            'A'...'Z' => c - 'A',
            'a'...'z' => c - 'a' + 26,
            '0'...'9' => c - '0' + 52,
            '+' => 62,
            '/' => 63,
            else => return error.InvalidBase64Character,
        });

        if (bit_queue.count >= 8) {
            output[byte_index] = bit_queue.dequeue();
            byte_index += 1;
        }
    }

    return output;
}

fn count_padding(input: []const u8) usize {
    if (input.len == 0) return 0;
    var i: usize = input.len - 1;
    var padding: usize = 0;

    while (i >= 0 and input[i] == '=') : (i -= 1) {
        padding += 1;
    }

    return padding;
}

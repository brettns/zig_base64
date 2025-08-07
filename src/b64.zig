const std = @import("std");

const BitQueue = struct {
    const Self = @This();
    queue: u32 = 0,
    count: u5 = 0,

    pub fn enqueue(self: *Self, value: u8, size: u5) void {
        // first two bits are always 0 so no need to truncate 8 to 6 on decode
        self.queue = (self.queue << size) | value;
        self.count += size;
    }

    pub fn dequeue(self: *Self, size: u5) u8 {
        if (self.count < size) @panic("cannot dequeue!");

        // Get the value
        const shift_amount: u5 = self.count - size;
        const result: u8 = @intCast(self.queue >> shift_amount);

        // Remove the bits from the queue
        self.queue &= (@as(u32, 1) << shift_amount) - 1;
        self.count -= size;
        return result;
    }
};

pub fn encode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const padding: usize = switch (input.len % 3) {
        1 => 2,
        2 => 1,
        else => 0,
    };

    const length = ((input.len + padding) * 8) / 6;
    var output = try allocator.alloc(u8, length);
    errdefer allocator.free(output);
    var byte_index: usize = 0;
    var bit_queue = BitQueue{};

    for (0..length - padding) |i| {
        if (i < input.len) {
            bit_queue.enqueue(input[i], 8);
        } else {
            // add extra zeroes for the padding
            bit_queue.enqueue(0, 8);
        }

        if (bit_queue.count >= 6) {
            const c: u8 = @as(u8, bit_queue.dequeue(6));
            const encoded_char: u8 = switch (c) {
                0...25 => c + 'A',
                26...51 => c - 26 + 'a',
                52...61 => c - 52 + '0',
                62 => '+',
                63 => '/',
                else => {
                    std.debug.print("{d} {b:0>8}\n", .{ c, c });
                    return error.InvalidBase64Character;
                },
            };

            output[byte_index] = encoded_char;
            byte_index += 1;
        }
    }

    for (0..padding) |_| {
        output[byte_index] = '=';
        byte_index += 1;
    }

    return output;
}

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
        }, 6);

        if (bit_queue.count >= 8) {
            output[byte_index] = bit_queue.dequeue(8);
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

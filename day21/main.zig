const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;
const Array2D = @import("common").arrays.Array2D;

const Keypad = struct {
    type: KeypadType,
    keys: Array2D(u8),

    pub const KeypadType = enum {
        Numeric,
        Directional,
    };

    pub fn init(allocator: std.mem.Allocator, typ: KeypadType) !Keypad {
        return .{ .type = typ, .keys = try Array2D(u8).fromSliceDelim(allocator, switch (typ) {
            .Numeric => "789\n456\n123\n 0A",
            .Directional => " ^A\n<v>",
        }, "\n") };
    }

    pub fn deinit(self: *const Keypad) void {
        self.keys.deinit();
    }
};

const KeySequenceLengthMapKey = struct {
    sequence: []const u8,
    iteration: usize,
    keypad_type: Keypad.KeypadType,
};

fn keySequenceLengthMapEqlFn(_: KeySequenceLengthMapContext, a: KeySequenceLengthMapKey, b: KeySequenceLengthMapKey) bool {
    return std.mem.eql(u8, a.sequence, b.sequence) and a.iteration == b.iteration and a.keypad_type == b.keypad_type;
}

fn keySequenceLengthMapHashFn(_: KeySequenceLengthMapContext, key: KeySequenceLengthMapKey) u64 {
    var hasher = std.hash.Wyhash.init(0);
    std.hash.autoHashStrat(&hasher, key, .Deep);
    return hasher.final();
}

const KeySequenceLengthMapContext = struct {
    pub const hash = keySequenceLengthMapHashFn;
    pub const eql = keySequenceLengthMapEqlFn;
};

const KeySequenceLengthMap = std.HashMap(KeySequenceLengthMapKey, u64, KeySequenceLengthMapContext, 80);

fn getKeypadSequenceLengthAllocRecurse(allocator: std.mem.Allocator, input: []const u8, keypads: []const Keypad, iteration: usize, sequence_length_map: *KeySequenceLengthMap) !u64 {
    if (iteration == 0) {
        return input.len;
    }

    const keypad = keypads[keypads.len - iteration];

    if (sequence_length_map.get(.{ .sequence = input, .iteration = iteration, .keypad_type = keypad.type })) |length| {
        return length;
    }

    var sequence = std.ArrayList(u8).init(allocator);
    defer sequence.deinit();

    var pos = keypad.keys.find('A').?.as(i32);
    var sequence_length: u64 = 0;
    for (input) |char| {
        const key_pos = keypad.keys.find(char).?.as(i32);
        sequence.clearRetainingCapacity();

        if (keypad.keys.at((Vec2D(i32){ .x = key_pos.x, .y = pos.y }).as(usize)) == ' ' or
            keypad.keys.at((Vec2D(i32){ .x = pos.x, .y = key_pos.y }).as(usize)) == ' ')
        {
            if (key_pos.x > pos.x) try sequence.appendNTimes('>', @intCast(key_pos.x - pos.x));
            if (key_pos.y > pos.y) try sequence.appendNTimes('v', @intCast(key_pos.y - pos.y));
            if (key_pos.y < pos.y) try sequence.appendNTimes('^', @intCast(pos.y - key_pos.y));
            if (key_pos.x < pos.x) try sequence.appendNTimes('<', @intCast(pos.x - key_pos.x));
        } else {
            if (key_pos.x < pos.x) try sequence.appendNTimes('<', @intCast(pos.x - key_pos.x));
            if (key_pos.y < pos.y) try sequence.appendNTimes('^', @intCast(pos.y - key_pos.y));
            if (key_pos.y > pos.y) try sequence.appendNTimes('v', @intCast(key_pos.y - pos.y));
            if (key_pos.x > pos.x) try sequence.appendNTimes('>', @intCast(key_pos.x - pos.x));
        }
        try sequence.append('A');

        sequence_length += try getKeypadSequenceLengthAllocRecurse(allocator, sequence.items, keypads, iteration - 1, sequence_length_map);

        pos = key_pos;
    }

    const input_dupe = try allocator.dupe(u8, input);
    try sequence_length_map.putNoClobber(.{ .sequence = input_dupe, .iteration = iteration, .keypad_type = keypad.type }, sequence_length);

    return sequence_length;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_complexity_codes_a: u64,
    sum_complexity_codes_b: u64,
} {
    const numeric_keypad = try Keypad.init(allocator, .Numeric);
    defer numeric_keypad.deinit();

    const directional_keypad = try Keypad.init(allocator, .Directional);
    defer directional_keypad.deinit();

    const keypads_a: []const Keypad = &(.{numeric_keypad} ++ .{directional_keypad} ** 2);
    const keypads_b: []const Keypad = &(.{numeric_keypad} ++ .{directional_keypad} ** 25);

    var sequence_length_map = KeySequenceLengthMap.init(allocator);
    defer sequence_length_map.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var sum_complexity_codes_a: u64 = 0;
    var sum_complexity_codes_b: u64 = 0;

    // Part 1 & 2
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        for ([2][]const Keypad{ keypads_a, keypads_b }, 0..) |keypads_variant, i| {
            const complexity = try getKeypadSequenceLengthAllocRecurse(arena_allocator, line, keypads_variant, keypads_variant.len, &sequence_length_map) * try std.fmt.parseInt(u64, line[0 .. line.len - 1], 10);
            if (i == 0) {
                sum_complexity_codes_a += complexity;
            } else {
                sum_complexity_codes_b += complexity;
            }
        }
    }

    return .{
        .sum_complexity_codes_a = sum_complexity_codes_a,
        .sum_complexity_codes_b = sum_complexity_codes_b,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 21 - Part 1: {}\n", .{solution.sum_complexity_codes_a});
    std.debug.print("Day 21 - Part 2: {}\n", .{solution.sum_complexity_codes_b});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(126384, solution.sum_complexity_codes_a);
    try std.testing.expectEqual(154115708116294, solution.sum_complexity_codes_b);
}

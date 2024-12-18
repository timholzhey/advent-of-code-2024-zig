const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;

const ClawMachine = struct {
    button_a: Vec2D(i64),
    button_b: Vec2D(i64),
    prize_location: Vec2D(i64),
};

fn parsePositionFromInputLine(line: []const u8) !Vec2D(i64) {
    const x_start = std.mem.indexOfScalar(u8, line, 'X').?;
    const x_end = std.mem.indexOfScalar(u8, line[x_start..], ',').?;
    const x_val = try std.fmt.parseInt(i64, line[x_start + 2 .. x_start + x_end], 10);

    const y_start = std.mem.indexOfScalar(u8, line, 'Y').?;
    const y_val = try std.fmt.parseInt(i64, line[y_start + 2 ..], 10);

    return .{
        .y = y_val,
        .x = x_val,
    };
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_tokens_win_all_prizes: u64,
    num_tokens_win_all_prizes_10trillion: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    var claw_machines = std.ArrayList(ClawMachine).init(allocator);
    defer claw_machines.deinit();

    var claw_machine_iter = std.mem.tokenizeSequence(u8, input_trimmed, "\n\n");
    while (claw_machine_iter.next()) |machine| {
        var line_iter = std.mem.tokenizeScalar(u8, machine, '\n');

        try claw_machines.append(.{
            .button_a = try parsePositionFromInputLine(line_iter.next().?),
            .button_b = try parsePositionFromInputLine(line_iter.next().?),
            .prize_location = try parsePositionFromInputLine(line_iter.next().?),
        });
    }

    // Solve system: Linear combination of two vectors equals a third vector
    // X = nA + kB
    // x1 = n*a1 + k*b1, x2 = n*a2 + k*b2
    // n = (x1 - k*b1) / a1, n = (x2 - k*b2) / a2
    // k = (x1*a2 - x2*a1) / (b1*a2 - b2*a1)

    // Part 1
    var num_tokens_win_all_prizes: u64 = 0;
    for (claw_machines.items) |claw_machine| {
        const k = std.math.divExact(i64, claw_machine.prize_location.x * claw_machine.button_a.y - claw_machine.prize_location.y * claw_machine.button_a.x, claw_machine.button_b.x * claw_machine.button_a.y - claw_machine.button_a.x * claw_machine.button_b.y) catch continue;
        const n = std.math.divExact(i64, claw_machine.prize_location.x - k * claw_machine.button_b.x, claw_machine.button_a.x) catch continue;
        num_tokens_win_all_prizes += @intCast(3 * n + k);
    }

    // Part 2
    var num_tokens_win_all_prizes_10trillion: u64 = 0;
    for (claw_machines.items) |claw_machine| {
        const prize_location = claw_machine.prize_location.add(.{ .x = 10000000000000, .y = 10000000000000 });
        const k = std.math.divExact(i64, prize_location.x * claw_machine.button_a.y - prize_location.y * claw_machine.button_a.x, claw_machine.button_b.x * claw_machine.button_a.y - claw_machine.button_a.x * claw_machine.button_b.y) catch continue;
        const n = std.math.divExact(i64, prize_location.x - k * claw_machine.button_b.x, claw_machine.button_a.x) catch continue;
        num_tokens_win_all_prizes_10trillion += @intCast(3 * n + k);
    }

    return .{
        .num_tokens_win_all_prizes = num_tokens_win_all_prizes,
        .num_tokens_win_all_prizes_10trillion = num_tokens_win_all_prizes_10trillion,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 13 - Part 1: {}\n", .{solution.num_tokens_win_all_prizes});
    std.debug.print("Day 13 - Part 2: {}\n", .{solution.num_tokens_win_all_prizes_10trillion});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(480, solution.num_tokens_win_all_prizes);
    try std.testing.expectEqual(875318608908, solution.num_tokens_win_all_prizes_10trillion);
}

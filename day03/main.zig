const std = @import("std");

const ParseInstrState = enum {
    Idle,
    MulOpenParen,
    MulOp1,
    MulComma,
    MulOp2,
    MulCloseParen,
    DoOpenParen,
    DoCloseParen,
    DontOpenParen,
    DontCloseParen,
};

const MulOp = struct {
    op1: u32,
    op2: u32,
};

fn interpretInstructionsGetSum(input: []const u8, do_dont_instr_enabled: bool) u64 {
    var total_sum: u32 = 0;
    var state: ParseInstrState = .Idle;
    var mul_op: MulOp = .{ .op1 = 0, .op2 = 0 };
    var is_mul_enabled = true;
    var index: u32 = 0;

    while (index < input.len) : (index += 1) {
        switch (state) {
            .Idle => {
                if (is_mul_enabled and input.len - index >= 3 and std.mem.eql(u8, input[index .. index + 3], "mul")) {
                    state = .MulOpenParen;
                    index += 2;
                }
                if (do_dont_instr_enabled and input.len - index >= 5 and std.mem.eql(u8, input[index .. index + 5], "don't")) {
                    state = .DontOpenParen;
                    index += 4;
                }
                if (do_dont_instr_enabled and input.len - index >= 2 and std.mem.eql(u8, input[index .. index + 2], "do")) {
                    state = .DoOpenParen;
                    index += 1;
                }
            },
            .MulOpenParen => {
                if (input[index] == '(') {
                    state = .MulOp1;
                } else {
                    state = .Idle;
                }
            },
            .MulOp1 => {
                var num_digits: u32 = 0;
                while (input.len - index >= num_digits and std.ascii.isDigit(input[index + num_digits])) {
                    num_digits += 1;
                }
                mul_op.op1 = std.fmt.parseInt(u32, input[index .. index + num_digits], 10) catch {
                    state = .Idle;
                    continue;
                };
                index += num_digits - 1;
                state = .MulComma;
            },
            .MulComma => {
                if (input[index] == ',') {
                    state = .MulOp2;
                } else {
                    state = .Idle;
                }
            },
            .MulOp2 => {
                var num_digits: u32 = 0;
                while (input.len - index >= num_digits and std.ascii.isDigit(input[index + num_digits])) {
                    num_digits += 1;
                }
                mul_op.op2 = std.fmt.parseInt(u32, input[index .. index + num_digits], 10) catch {
                    state = .Idle;
                    continue;
                };
                index += num_digits - 1;
                state = .MulCloseParen;
            },
            .MulCloseParen => {
                if (input[index] == ')') {
                    total_sum += mul_op.op1 * mul_op.op2;
                }
                state = .Idle;
            },
            .DoOpenParen => {
                if (input[index] == '(') {
                    state = .DoCloseParen;
                } else {
                    state = .Idle;
                }
            },
            .DoCloseParen => {
                if (input[index] == ')') {
                    is_mul_enabled = true;
                }
                state = .Idle;
            },
            .DontOpenParen => {
                if (input[index] == '(') {
                    state = .DontCloseParen;
                } else {
                    state = .Idle;
                }
            },
            .DontCloseParen => {
                if (input[index] == ')') {
                    is_mul_enabled = false;
                }
                state = .Idle;
            },
        }
    }

    return total_sum;
}

fn solve(_: std.mem.Allocator, input: []const u8) !struct {
    uncorrupted_mul_sum: u64,
    uncorrupted_mul_sum_with_do_dont: u64,
} {
    // Part 1
    const uncorrupted_mul_sum: u64 = interpretInstructionsGetSum(input, false);

    // Part 2
    const uncorrupted_mul_sum_with_do_dont: u64 = interpretInstructionsGetSum(input, true);

    return .{
        .uncorrupted_mul_sum = uncorrupted_mul_sum,
        .uncorrupted_mul_sum_with_do_dont = uncorrupted_mul_sum_with_do_dont,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 03 - Part 1: {}\n", .{solution.uncorrupted_mul_sum});
    std.debug.print("Day 03 - Part 2: {}\n", .{solution.uncorrupted_mul_sum_with_do_dont});
}

test "sample" {
    const solution1 = try solve(std.testing.allocator, @embedFile("sample1.txt"));
    try std.testing.expectEqual(161, solution1.uncorrupted_mul_sum);

    const solution2 = try solve(std.testing.allocator, @embedFile("sample2.txt"));
    try std.testing.expectEqual(48, solution2.uncorrupted_mul_sum_with_do_dont);
}

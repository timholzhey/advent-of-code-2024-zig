const std = @import("std");

const Equation = struct {
    test_value: u64,
    operands: std.ArrayList(u64),
};

const Operator = enum {
    Add,
    Multiply,
    Concat,
    Noop,
};

fn evalEquationTestRecurse(operands: []u64, operators: []const Operator, test_value: u64, accum: u64) !u64 {
    if (operands.len == 0) {
        if (accum == test_value) {
            return accum;
        }
        return error.TestValueMismatch;
    }

    var concat_buffer: [64]u8 = undefined;

    for (operators) |operator| {
        // Apply operator
        const total = switch (operator) {
            .Add => accum + operands[0],
            .Multiply => accum * operands[0],
            .Concat => try std.fmt.parseInt(u64, try std.fmt.bufPrint(&concat_buffer, "{}{}", .{ accum, operands[0] }), 10),
            .Noop => continue,
        };

        // Since all operators are increasing the total, skip when exceeding test value
        if (total > test_value) {
            continue;
        }

        // Recurse next operand
        return evalEquationTestRecurse(operands[1..], operators, test_value, total) catch continue;
    }

    return error.TestValueMismatch;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_equations_possible_add_mul: u64,
    sum_equations_possible_add_mul_concat: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const num_lines = std.mem.count(u8, input_trimmed, "\n") + 1;
    var equations = try std.ArrayList(Equation).initCapacity(allocator, num_lines);
    defer {
        for (equations.items) |equation| {
            equation.operands.deinit();
        }
        equations.deinit();
    }

    var lines_iter = std.mem.tokenizeScalar(u8, input_trimmed, '\n');
    while (lines_iter.next()) |line| {
        var equation = Equation{ .test_value = 0, .operands = std.ArrayList(u64).init(allocator) };

        var delim_iter = std.mem.tokenizeScalar(u8, line, ':');
        equation.test_value = try std.fmt.parseInt(u64, delim_iter.next() orelse unreachable, 10);

        var operands_iter = std.mem.tokenizeScalar(u8, delim_iter.next() orelse unreachable, ' ');
        while (operands_iter.next()) |operand| {
            const number = try std.fmt.parseInt(u64, operand, 10);
            try equation.operands.append(number);
        }

        try equations.append(equation);
    }

    // Part 1
    var sum_equations_possible_add_mul: u64 = 0;
    for (equations.items) |equation| {
        const operators = [_]Operator{ .Add, .Multiply };
        sum_equations_possible_add_mul += evalEquationTestRecurse(equation.operands.items[1..], &operators, equation.test_value, equation.operands.items[0]) catch continue;
    }

    // Part 2
    var sum_equations_possible_add_mul_concat: u64 = 0;
    for (equations.items) |equation| {
        const operators = [_]Operator{ .Add, .Multiply, .Concat };
        sum_equations_possible_add_mul_concat += evalEquationTestRecurse(equation.operands.items[1..], &operators, equation.test_value, equation.operands.items[0]) catch continue;
    }

    return .{
        .sum_equations_possible_add_mul = sum_equations_possible_add_mul,
        .sum_equations_possible_add_mul_concat = sum_equations_possible_add_mul_concat,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 07 - Part 1: {}\n", .{solution.sum_equations_possible_add_mul});
    std.debug.print("Day 07 - Part 2: {}\n", .{solution.sum_equations_possible_add_mul_concat});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(3749, solution.sum_equations_possible_add_mul);
    try std.testing.expectEqual(11387, solution.sum_equations_possible_add_mul_concat);
}

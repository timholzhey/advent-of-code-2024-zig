const std = @import("std");

const Opcode = enum(u8) {
    div_store_a = 0,
    div_store_b = 6,
    div_store_c = 7,
    xor_literal = 1,
    xor_operand = 4,
    jump_not_zero = 3,
    mask = 2,
    print = 5,
};

const Operand = struct {
    value: u8,

    fn compositeValue(self: Operand, registers: Registers) u64 {
        return switch (self.value) {
            0, 1, 2, 3 => self.value,
            4 => registers.a,
            5 => registers.b,
            6 => registers.c,
            else => unreachable,
        };
    }
};

const Instruction = struct {
    opcode: Opcode,
    operand: Operand,
};

const Registers = struct {
    a: u64,
    b: u64,
    c: u64,
};

const Checkpoint = struct {
    reg_a_accum: u64,
    index: usize,
};

fn parseNumberFromLine(line: []const u8) !u64 {
    const begin_num = std.mem.indexOf(u8, line, ": ").? + 2;
    return try std.fmt.parseInt(u64, line[begin_num..], 10);
}

fn lessThanCheckpointRegA(context: void, a: Checkpoint, b: Checkpoint) std.math.Order {
    _ = context;
    return std.math.order(a.reg_a_accum, b.reg_a_accum);
}

fn runProgramYieldNextOutput(program: []Instruction, registers: *Registers, pc: *u64) !?u64 {
    while (pc.* < program.len) {
        const instr = program[pc.*];
        switch (instr.opcode) {
            .div_store_a => registers.*.a >>= @as(u6, @intCast(instr.operand.compositeValue(registers.*))),
            .div_store_b => registers.*.b = registers.*.a >> @as(u6, @intCast(instr.operand.compositeValue(registers.*))),
            .div_store_c => registers.*.c = registers.*.a >> @as(u6, @intCast(instr.operand.compositeValue(registers.*))),
            .xor_literal => registers.*.b ^= instr.operand.value,
            .xor_operand => registers.*.b ^= registers.*.c,
            .mask => registers.*.b = @mod(instr.operand.compositeValue(registers.*), 8),
            .print => {
                pc.* += 1;
                return @mod(instr.operand.compositeValue(registers.*), 8);
            },
            .jump_not_zero => {
                if (registers.*.a != 0) {
                    pc.* = instr.operand.value;
                    continue;
                }
            },
        }
        pc.* += 1;
    }
    return null;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    program_output: []u8,
    lowest_init_register_a_output_self: u64,
} {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    const registers_init = Registers{
        .a = try parseNumberFromLine(line_iter.next().?),
        .b = try parseNumberFromLine(line_iter.next().?),
        .c = try parseNumberFromLine(line_iter.next().?),
    };

    var program = std.ArrayList(Instruction).init(allocator);
    defer program.deinit();

    var encoded_program = std.ArrayList(u8).init(allocator);
    defer encoded_program.deinit();

    const program_line = line_iter.next().?;
    const program_str = program_line[std.mem.indexOf(u8, program_line, ": ").? + 2 ..];
    var instruction_iter = std.mem.tokenizeScalar(u8, program_str, ',');
    var opcode: ?Opcode = null;
    while (instruction_iter.next()) |instr_str| {
        if (opcode) |op| {
            const operand = Operand{ .value = try std.fmt.parseInt(u8, instr_str, 10) };
            try program.append(.{ .opcode = op, .operand = operand });
            opcode = null;
        } else {
            const instruction = try std.fmt.parseInt(u8, instr_str, 10);
            opcode = @enumFromInt(instruction);
        }

        try encoded_program.append(try std.fmt.parseInt(u8, instr_str, 10));
    }

    // Part 1
    var program_output = std.ArrayList(u8).init(allocator);
    defer program_output.deinit();
    {
        var registers = registers_init;
        var pc: u64 = 0;

        while (try runProgramYieldNextOutput(program.items, &registers, &pc)) |output| {
            var buffer: [32]u8 = undefined;
            const str = try std.fmt.bufPrint(&buffer, "{}", .{output});
            if (program_output.items.len > 0) {
                try program_output.appendSlice(",");
            }
            try program_output.appendSlice(str);
        }
    }

    // Part 2
    var lowest_init_register_a_output_self: u64 = 0;
    {
        // 2,4,1,1,7,5,4,7,1,4,0,3,5,5,3,0
        //
        // bst 4
        // bxl 1
        // cdv 5
        // bxc 7
        // bxl 4
        // adv 3
        // out 5
        // jnz 0
        //
        // do {
        //     b = a % 8;
        //     b = b ^ 1;
        //     c = a >> b;
        //     b = b ^ c;
        //     b = b ^ 4;
        //     a = a >> 3;
        //     print(b % 8);
        // } while (a != 0);
        //
        // fn step(a) {
        //     print(((a % 8) ^ 5 ^ (a >> ((a % 8) ^ 1))) % 8);
        // }

        var checkpoint_queue = std.PriorityQueue(Checkpoint, void, lessThanCheckpointRegA).init(allocator, {});
        defer checkpoint_queue.deinit();
        try checkpoint_queue.add(.{ .reg_a_accum = 0, .index = 0 });

        stack_pop: while (checkpoint_queue.count() != 0) {
            const checkpoint = checkpoint_queue.remove();

            for (0..8) |i| {
                const reg_a_init = (checkpoint.reg_a_accum << 3) | i;
                var registers = registers_init;
                registers.a = reg_a_init;
                var pc: u64 = 0;

                if (try runProgramYieldNextOutput(program.items, &registers, &pc)) |num| {
                    if (num == encoded_program.items[encoded_program.items.len - 1 - checkpoint.index]) {
                        if (checkpoint.index == encoded_program.items.len - 1) {
                            lowest_init_register_a_output_self = reg_a_init;
                            break :stack_pop;
                        }

                        try checkpoint_queue.add(.{ .reg_a_accum = reg_a_init, .index = checkpoint.index + 1 });
                    }
                }
            }
        }
    }

    return .{
        .program_output = try program_output.toOwnedSlice(),
        .lowest_init_register_a_output_self = lowest_init_register_a_output_self,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 17 - Part 1: {s}\n", .{solution.program_output});
    std.debug.print("Day 17 - Part 2: {}\n", .{solution.lowest_init_register_a_output_self});
}

test "sample" {
    const allocator = std.testing.allocator;

    const solution1 = try solve(allocator, @embedFile("sample1.txt"));
    defer allocator.free(solution1.program_output);
    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", solution1.program_output);

    const solution2 = try solve(allocator, @embedFile("sample2.txt"));
    defer allocator.free(solution2.program_output);
    try std.testing.expectEqual(117440, solution2.lowest_init_register_a_output_self);
}

const std = @import("std");

fn findPermutationsSubstringRecurse(design: []const u8, patterns: std.ArrayList([]const u8), design_pattern_permutation_map: *std.StringHashMap(u64)) !u64 {
    if (design.len == 0) {
        return 1;
    }

    const design_count = design_pattern_permutation_map.get(design);
    if (design_count) |count| {
        return count;
    }

    var count: u64 = 0;
    for (patterns.items) |pattern| {
        if (pattern.len > design.len or !std.mem.eql(u8, design[0..pattern.len], pattern)) {
            continue;
        }

        count += try findPermutationsSubstringRecurse(design[pattern.len..], patterns, design_pattern_permutation_map);
    }

    try design_pattern_permutation_map.put(design, count);

    return count;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_designs_possible: u64,
    num_ways_designs_possible: u64,
} {
    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var comma_iter = std.mem.tokenizeAny(u8, lines_iter.next().?, ", ");

    var towel_patterns = std.ArrayList([]const u8).init(allocator);
    defer towel_patterns.deinit();

    while (comma_iter.next()) |comma| {
        try towel_patterns.append(comma);
    }

    var towel_designs = std.ArrayList([]const u8).init(allocator);
    defer towel_designs.deinit();

    while (lines_iter.next()) |line| {
        try towel_designs.append(line);
    }

    var design_pattern_map = std.StringHashMap(u64).init(allocator);
    defer design_pattern_map.deinit();

    var num_designs_possible: u64 = 0;
    var num_ways_designs_possible: u64 = 0;

    for (towel_designs.items) |design| {
        const count = try findPermutationsSubstringRecurse(design, towel_patterns, &design_pattern_map);
        num_designs_possible += if (count > 0) 1 else 0;
        num_ways_designs_possible += count;
    }

    return .{
        .num_designs_possible = num_designs_possible,
        .num_ways_designs_possible = num_ways_designs_possible,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 19 - Part 1: {}\n", .{solution.num_designs_possible});
    std.debug.print("Day 19 - Part 2: {}\n", .{solution.num_ways_designs_possible});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(6, solution.num_designs_possible);
    try std.testing.expectEqual(16, solution.num_ways_designs_possible);
}

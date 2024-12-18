const std = @import("std");

const Pos = struct {
    x: i32,
    y: i32,
};

const PosVisit = packed struct {
    up: bool,
    down: bool,
    left: bool,
    right: bool,
};

fn moveGuardStep(grid: []u8, grid_width: usize, grid_height: usize, guard_index: usize) !usize {
    while (true) {
        const guard_val = grid[guard_index];
        const guard_pos: Pos = .{
            .x = @intCast(guard_index % (grid_width + 1)),
            .y = @intCast(guard_index / (grid_width + 1)),
        };

        const guard_new_pos: Pos = switch (guard_val) {
            '^' => .{ .x = guard_pos.x, .y = guard_pos.y - 1 },
            'v' => .{ .x = guard_pos.x, .y = guard_pos.y + 1 },
            '<' => .{ .x = guard_pos.x - 1, .y = guard_pos.y },
            '>' => .{ .x = guard_pos.x + 1, .y = guard_pos.y },
            else => unreachable,
        };

        // Check still in grid
        if (guard_new_pos.x < 0 or guard_new_pos.x >= grid_width or guard_new_pos.y < 0 or guard_new_pos.y >= grid_height) {
            return error.OutOfBounds;
        }

        // Check obstacle at new position, rotate guard 90 degrees right, start over
        if (grid[@intCast(guard_new_pos.y * @as(i32, @intCast(grid_width + 1)) + guard_new_pos.x)] == '#') {
            grid[guard_index] = switch (guard_val) {
                '^' => '>',
                'v' => '<',
                '<' => '^',
                '>' => 'v',
                else => unreachable,
            };
            continue;
        }

        const guard_new_index: usize = @intCast(guard_new_pos.y * @as(i32, @intCast(grid_width + 1)) + guard_new_pos.x);

        // Move guard
        grid[guard_new_index] = guard_val;
        grid[guard_index] = '.';

        return guard_new_index;
    }
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_distinct_pos_visited: u64,
    num_obstructions_cause_loop: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const grid_width = std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable;
    const grid_height = std.mem.count(u8, input_trimmed, "\n") + 1;

    // Part 1
    var num_distinct_pos_visited: u64 = 0;
    {
        const grid = try allocator.dupe(u8, input_trimmed);
        defer allocator.free(grid);

        var positions_visited = try allocator.alloc(bool, grid.len);
        @memset(positions_visited, false);
        defer allocator.free(positions_visited);

        var guard_index = std.mem.indexOfAny(u8, grid, "^v<>") orelse unreachable;

        while (true) {
            guard_index = moveGuardStep(grid, grid_width, grid_height, guard_index) catch break;

            if (!positions_visited[guard_index]) {
                num_distinct_pos_visited += 1;
                positions_visited[guard_index] = true;
            }
        }
    }

    // Part 2
    var num_obstructions_cause_loop: u64 = 0;
    {
        var grid = try allocator.dupe(u8, input_trimmed);
        defer allocator.free(grid);

        var positions_visits = try allocator.alloc(PosVisit, grid.len);
        @memset(positions_visits, .{ .up = false, .down = false, .left = false, .right = false });
        defer allocator.free(positions_visits);

        const guard_index_init = std.mem.indexOfAny(u8, grid, "^v<>") orelse unreachable;

        var input_dot_iter = std.mem.splitScalar(u8, input_trimmed, '.');
        while (input_dot_iter.next()) |_| {
            var guard_index = guard_index_init;

            const obstruction_index = (input_dot_iter.index orelse input_trimmed.len) - 1;

            // Reset grid
            @memcpy(grid, input_trimmed);

            // Reset visits
            @memset(positions_visits, .{ .up = false, .down = false, .left = false, .right = false });

            // Insert new obstruction
            grid[obstruction_index] = '#';

            blk: while (true) {
                guard_index = moveGuardStep(grid, grid_width, grid_height, guard_index) catch break;

                switch (grid[guard_index]) {
                    '^' => {
                        if (positions_visits[guard_index].up) {
                            num_obstructions_cause_loop += 1;
                            break :blk;
                        }
                        positions_visits[guard_index].up = true;
                    },
                    'v' => {
                        if (positions_visits[guard_index].down) {
                            num_obstructions_cause_loop += 1;
                            break :blk;
                        }
                        positions_visits[guard_index].down = true;
                    },
                    '<' => {
                        if (positions_visits[guard_index].left) {
                            num_obstructions_cause_loop += 1;
                            break :blk;
                        }
                        positions_visits[guard_index].left = true;
                    },
                    '>' => {
                        if (positions_visits[guard_index].right) {
                            num_obstructions_cause_loop += 1;
                            break :blk;
                        }
                        positions_visits[guard_index].right = true;
                    },
                    else => unreachable,
                }
            }
        }
    }

    return .{
        .num_distinct_pos_visited = num_distinct_pos_visited,
        .num_obstructions_cause_loop = num_obstructions_cause_loop,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 06 - Part 1: {}\n", .{solution.num_distinct_pos_visited});
    std.debug.print("Day 06 - Part 2: {}\n", .{solution.num_obstructions_cause_loop});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(41, solution.num_distinct_pos_visited);
    try std.testing.expectEqual(6, solution.num_obstructions_cause_loop);
}

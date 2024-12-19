const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_coordinates: u64,
    sum_coordinates_wide: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const input_seperator = std.mem.indexOf(u8, input_trimmed, "\n\n").?;
    const input_grid = input_trimmed[0..input_seperator];

    var moves_list = std.ArrayList(Direction).init(allocator);
    defer moves_list.deinit();

    for (input_trimmed[input_seperator..]) |char| {
        if (char == '\n') {
            continue;
        }

        try moves_list.append(switch (char) {
            '^' => .north,
            'v' => .south,
            '<' => .west,
            '>' => .east,
            else => unreachable,
        });
    }

    var sum_coordinates: u64 = 0;
    {
        var grid = try allocator.dupe(u8, input_grid);
        defer allocator.free(grid);

        const dimensions = Vec2D(i32){
            .x = @intCast(std.mem.indexOfScalar(u8, grid, '\n') orelse unreachable),
            .y = @intCast(std.mem.count(u8, grid, "\n") + 1),
        };

        var current_pos = Vec2D(i32).from2DIndex(std.mem.indexOfScalar(u8, grid, '@') orelse unreachable, @intCast(dimensions.x + 1));

        for_moves: for (moves_list.items) |direction| {
            const next_pos = current_pos.add(direction.toNormVec2D(i32));
            const next_val = grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))];

            switch (next_val) {
                '#' => continue,
                'O' => {
                    var box_pos = next_pos;
                    traverse_boxes: while (true) {
                        box_pos = box_pos.add(direction.toNormVec2D(i32));

                        switch (grid[box_pos.to2DIndex(@intCast(dimensions.x + 1))]) {
                            '#' => continue :for_moves,
                            'O' => {},
                            '.' => {
                                grid[box_pos.to2DIndex(@intCast(dimensions.x + 1))] = 'O';
                                grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))] = '@';
                                grid[current_pos.to2DIndex(@intCast(dimensions.x + 1))] = '.';
                                break :traverse_boxes;
                            },
                            else => unreachable,
                        }
                    }
                },
                '.' => {
                    grid[current_pos.to2DIndex(@intCast(dimensions.x + 1))] = '.';
                    grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))] = '@';
                },
                else => unreachable,
            }

            current_pos = next_pos;
        }

        for (grid, 0..) |char, index| {
            if (char == 'O') {
                const box_pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));
                sum_coordinates += @intCast(box_pos.x + 100 * box_pos.y);
            }
        }
    }

    var sum_coordinates_wide: u64 = 0;
    {
        var grid = try allocator.alloc(u8, 2 * input_grid.len);
        defer allocator.free(grid);

        for (input_grid, 0..) |char, index| {
            @memcpy(grid[2 * index .. 2 * index + 2], switch (char) {
                '#' => "##",
                'O' => "[]",
                '.' => "..",
                '@' => "@.",
                '\n' => " \n",
                else => unreachable,
            });
        }

        const dimensions = Vec2D(i32){
            .x = @intCast(std.mem.indexOfScalar(u8, grid, '\n') orelse unreachable),
            .y = @intCast(std.mem.count(u8, grid, "\n") + 1),
        };

        const Box = struct {
            pos: Vec2D(i32),
            is_start: bool,
        };

        var current_pos = Vec2D(i32).from2DIndex(std.mem.indexOfScalar(u8, grid, '@') orelse unreachable, @intCast(dimensions.x + 1));
        var boxes_stack = std.ArrayList(Box).init(allocator);
        defer boxes_stack.deinit();

        for_moves: for (moves_list.items) |direction| {
            const next_pos = current_pos.add(direction.toNormVec2D(i32));
            const next_val = grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))];

            switch (next_val) {
                '#' => continue,
                '[', ']' => {
                    var box_pos = next_pos;
                    if (next_val == ']') {
                        box_pos = box_pos.add(Direction.west.toNormVec2D(i32));
                    }
                    boxes_stack.clearRetainingCapacity();
                    try boxes_stack.append(.{ .pos = box_pos, .is_start = true });
                    try boxes_stack.append(.{ .pos = box_pos.add(Direction.east.toNormVec2D(i32)), .is_start = false });

                    var box_stack_index: usize = 0;
                    while (box_stack_index < boxes_stack.items.len and box_stack_index < 1000) : (box_stack_index += 1) {
                        const box = boxes_stack.items[box_stack_index];
                        var next_pos_box = box.pos.add(direction.toNormVec2D(i32));

                        const next_val_box = grid[next_pos_box.to2DIndex(@intCast(dimensions.x + 1))];
                        switch (next_val_box) {
                            '#' => continue :for_moves,
                            '[', ']' => {
                                if ((box.is_start and direction == .east) or (!box.is_start and direction == .west)) {
                                    continue;
                                }
                                if (next_val_box == ']') {
                                    next_pos_box = next_pos_box.add(Direction.west.toNormVec2D(i32));
                                }
                                try boxes_stack.append(.{ .pos = next_pos_box, .is_start = true });
                                try boxes_stack.append(.{ .pos = next_pos_box.add(Direction.east.toNormVec2D(i32)), .is_start = false });
                            },
                            '.' => {},
                            else => unreachable,
                        }
                    }

                    for (0..boxes_stack.items.len) |i| {
                        const index = boxes_stack.items.len - 1 - i;
                        const box = boxes_stack.items[index];
                        if (!box.is_start) continue;
                        grid[box.pos.to2DIndex(@intCast(dimensions.x + 1))] = '.';
                        grid[box.pos.to2DIndex(@intCast(dimensions.x + 1)) + 1] = '.';
                        grid[box.pos.add(direction.toNormVec2D(i32)).to2DIndex(@intCast(dimensions.x + 1))] = '[';
                        grid[box.pos.add(direction.toNormVec2D(i32)).to2DIndex(@intCast(dimensions.x + 1)) + 1] = ']';
                    }

                    grid[current_pos.to2DIndex(@intCast(dimensions.x + 1))] = '.';
                    grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))] = '@';
                },
                '.' => {
                    grid[current_pos.to2DIndex(@intCast(dimensions.x + 1))] = '.';
                    grid[next_pos.to2DIndex(@intCast(dimensions.x + 1))] = '@';
                },
                else => unreachable,
            }

            current_pos = next_pos;
        }

        for (grid, 0..) |char, index| {
            if (char == '[') {
                const box_pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));
                sum_coordinates_wide += @intCast(box_pos.x + 100 * box_pos.y);
            }
        }
    }

    return .{
        .sum_coordinates = sum_coordinates,
        .sum_coordinates_wide = sum_coordinates_wide,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 14 - Part 1: {}\n", .{solution.sum_coordinates});
    std.debug.print("Day 14 - Part 2: {}\n", .{solution.sum_coordinates_wide});
}

test "sample" {
    const solution1 = try solve(std.testing.allocator, @embedFile("sample1.txt"));
    try std.testing.expectEqual(2028, solution1.sum_coordinates);

    const solution2 = try solve(std.testing.allocator, @embedFile("sample2.txt"));
    try std.testing.expectEqual(10092, solution2.sum_coordinates);
    try std.testing.expectEqual(9021, solution2.sum_coordinates_wide);
}

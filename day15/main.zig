const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;
const Array2D = @import("common").arrays.Array2D;

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_coordinates: u64,
    sum_coordinates_wide: u64,
} {
    const input_grid = try Array2D(u8).fromSliceDelim(allocator, input, "\n");
    defer input_grid.deinit();

    var moves_list = std.ArrayList(Direction).init(allocator);
    defer moves_list.deinit();

    for (input[std.mem.indexOfAny(u8, input, "<>^v").?..]) |char| {
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
        var grid = try input_grid.clone();
        defer grid.deinit();

        var current_pos = grid.find('@').?.as(i32);

        for_moves: for (moves_list.items) |direction| {
            const next_pos = current_pos.add(direction.toNormVec2D(i32));
            const next_val = grid.at(next_pos.as(usize));

            switch (next_val) {
                '#' => continue,
                'O' => {
                    var box_pos = next_pos;
                    traverse_boxes: while (true) {
                        box_pos = box_pos.add(direction.toNormVec2D(i32));

                        switch (grid.at(box_pos.as(usize))) {
                            '#' => continue :for_moves,
                            'O' => {},
                            '.' => {
                                grid.set(current_pos.as(usize), '.');
                                grid.set(next_pos.as(usize), '@');
                                grid.set(box_pos.as(usize), 'O');
                                break :traverse_boxes;
                            },
                            else => unreachable,
                        }
                    }
                },
                '.' => {
                    grid.set(current_pos.as(usize), '.');
                    grid.set(next_pos.as(usize), '@');
                },
                else => unreachable,
            }

            current_pos = next_pos;
        }

        var grid_iter = grid.iterator();
        while (grid_iter.next()) |elem| {
            if (elem.value != 'O') continue;
            sum_coordinates += @intCast(elem.position.x + 100 * elem.position.y);
        }
    }

    var sum_coordinates_wide: u64 = 0;
    {
        var grid = try Array2D(u8).initSize(allocator, input_grid.dimensions.mulVec(.{ .x = 2, .y = 1 }));
        defer grid.deinit();

        var input_grid_iter = input_grid.iterator();
        while (input_grid_iter.next()) |elem| {
            grid.setSlice(elem.position.mulVec(.{ .x = 2, .y = 1 }), switch (elem.value) {
                '#' => "##",
                'O' => "[]",
                '.' => "..",
                '@' => "@.",
                '\n' => " \n",
                else => unreachable,
            });
        }

        const Box = struct {
            pos: Vec2D(i32),
            is_start: bool,
        };

        var current_pos = grid.find('@').?.as(i32);
        var boxes_stack = std.ArrayList(Box).init(allocator);
        defer boxes_stack.deinit();

        for_moves: for (moves_list.items) |direction| {
            const next_pos = current_pos.add(direction.toNormVec2D(i32));
            const next_val = grid.at(next_pos.as(usize));

            switch (next_val) {
                '#' => continue,
                '[', ']' => {
                    boxes_stack.clearRetainingCapacity();

                    var box_pos = next_pos;
                    if (next_val == ']') {
                        box_pos = box_pos.add(Direction.west.toNormVec2D(i32));
                    }
                    try boxes_stack.append(.{ .pos = box_pos, .is_start = true });
                    try boxes_stack.append(.{ .pos = box_pos.add(Direction.east.toNormVec2D(i32)), .is_start = false });

                    var box_stack_index: usize = 0;
                    while (box_stack_index < boxes_stack.items.len and box_stack_index < 1000) : (box_stack_index += 1) {
                        const box = boxes_stack.items[box_stack_index];
                        var next_pos_box = box.pos.add(direction.toNormVec2D(i32));

                        const next_val_box = grid.at(next_pos_box.as(usize));
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
                        grid.set(box.pos.as(usize), '.');
                        grid.set(box.pos.add(Direction.east.toNormVec2D(i32)).as(usize), '.');
                        grid.set(box.pos.add(direction.toNormVec2D(i32)).as(usize), '[');
                        grid.set(box.pos.add(direction.toNormVec2D(i32)).add(Direction.east.toNormVec2D(i32)).as(usize), ']');
                    }

                    grid.set(current_pos.as(usize), '.');
                    grid.set(next_pos.as(usize), '@');
                },
                '.' => {
                    grid.set(current_pos.as(usize), '.');
                    grid.set(next_pos.as(usize), '@');
                },
                else => unreachable,
            }

            current_pos = next_pos;
        }

        var grid_iter = grid.iterator();
        while (grid_iter.next()) |elem| {
            if (elem.value == '[') {
                sum_coordinates_wide += @intCast(elem.position.x + 100 * elem.position.y);
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

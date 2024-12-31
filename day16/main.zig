const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;
const Array2D = @import("common").arrays.Array2D;

const Node = struct {
    pos: Vec2D(i32),
    heading: Direction,
    score: u64,
};

const MinScore = struct {
    north: u64 = std.math.maxInt(u64),
    east: u64 = std.math.maxInt(u64),
    south: u64 = std.math.maxInt(u64),
    west: u64 = std.math.maxInt(u64),

    fn at(self: MinScore, heading: Direction) u64 {
        return switch (heading) {
            .north => self.north,
            .east => self.east,
            .south => self.south,
            .west => self.west,
            else => unreachable,
        };
    }

    fn set(self: *MinScore, heading: Direction, score: u64) void {
        switch (heading) {
            .north => self.north = score,
            .east => self.east = score,
            .south => self.south = score,
            .west => self.west = score,
            else => unreachable,
        }
    }
};

fn lessThanNodeScore(context: void, a: Node, b: Node) std.math.Order {
    _ = context;
    return std.math.order(a.score, b.score);
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    lowest_score_traverse_maze: u64,
    num_tiles_part_of_best_path: u64,
} {
    const grid = try Array2D(u8).fromSliceDelim(allocator, input, "\n");
    defer grid.deinit();

    const start_pos = grid.find('S').?.as(i32);
    const end_pos = grid.find('E').?.as(i32);

    // Part 1
    var prio_queue = std.PriorityQueue(Node, void, lessThanNodeScore).init(allocator, {});
    defer prio_queue.deinit();

    var best_cost_grid = try Array2D(MinScore).initDefault(allocator, grid.dimensions, MinScore{});
    defer best_cost_grid.deinit();
    best_cost_grid.set(start_pos.as(usize), MinScore{ .east = 0 });

    try prio_queue.add(.{
        .pos = start_pos,
        .heading = .east,
        .score = 0,
    });

    var best_score: u64 = std.math.maxInt(u64);
    while (prio_queue.count() != 0) {
        const current = prio_queue.remove();

        if (current.pos.equals(end_pos)) {
            if (current.score == best_score) {} else if (current.score < best_score) {
                best_score = current.score;
            }
            continue;
        }

        for (.{current.heading} ++ current.heading.rotateEither(.quarter)) |direction| {
            const neighbor_pos = current.pos.add(direction.toNormVec2D(i32));

            if (!neighbor_pos.isWithinZeroRect(grid.dimensions.as(i32)) or grid.at(neighbor_pos.as(usize)) == '#') {
                continue;
            }

            const score = current.score + 1 + @as(u64, (if (direction != current.heading) 1000 else 0));

            var best_score_here = best_cost_grid.at(neighbor_pos.as(usize));
            if (score > best_score or score > best_score_here.at(direction)) {
                continue;
            }

            best_score_here.set(direction, score);
            best_cost_grid.set(neighbor_pos.as(usize), best_score_here);

            try prio_queue.add(.{
                .pos = neighbor_pos,
                .heading = direction,
                .score = score,
            });
        }
    }

    // Part 2
    prio_queue.items.len = 0;

    for (Direction.cardinals) |direction| {
        if (best_cost_grid.at(end_pos.as(usize)).at(direction) != std.math.maxInt(u64)) {
            try prio_queue.add(.{
                .pos = end_pos,
                .heading = direction,
                .score = best_cost_grid.at(end_pos.as(usize)).at(direction),
            });
        }
    }

    var part_of_best_path_grid = try Array2D(bool).initDefault(allocator, grid.dimensions, false);
    defer part_of_best_path_grid.deinit();

    while (prio_queue.count() != 0) {
        const current = prio_queue.remove();

        const prev_pos = current.pos.sub(current.heading.toNormVec2D(i32));

        part_of_best_path_grid.set(prev_pos.as(usize), true);

        for (.{current.heading} ++ current.heading.rotateEither(.quarter)) |direction| {
            if (current.score < 1 + @as(u64, (if (direction != current.heading) 1000 else 0))) {
                continue;
            }

            const score = current.score - 1 - @as(u64, (if (direction != current.heading) 1000 else 0));

            var best_score_here = best_cost_grid.at(prev_pos.as(usize));
            if (score != best_score_here.at(direction)) {
                continue;
            }

            try prio_queue.add(.{
                .pos = prev_pos,
                .heading = direction,
                .score = score,
            });
        }
    }

    var num_tiles_part_of_best_path: u64 = 0;
    var part_of_best_path_grid_iter = part_of_best_path_grid.iterator();
    while (part_of_best_path_grid_iter.next()) |elem| {
        if (elem.value) {
            num_tiles_part_of_best_path += 1;
        }
    }

    return .{
        .lowest_score_traverse_maze = best_score,
        .num_tiles_part_of_best_path = num_tiles_part_of_best_path,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 16 - Part 1: {}\n", .{solution.lowest_score_traverse_maze});
    std.debug.print("Day 16 - Part 2: {}\n", .{solution.num_tiles_part_of_best_path});
}

test "sample" {
    const solution1 = try solve(std.testing.allocator, @embedFile("sample1.txt"));
    try std.testing.expectEqual(7036, solution1.lowest_score_traverse_maze);
    try std.testing.expectEqual(45, solution1.num_tiles_part_of_best_path);

    const solution2 = try solve(std.testing.allocator, @embedFile("sample2.txt"));
    try std.testing.expectEqual(11048, solution2.lowest_score_traverse_maze);
    try std.testing.expectEqual(64, solution2.num_tiles_part_of_best_path);
}

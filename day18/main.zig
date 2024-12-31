const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;
const Array2D = @import("common").arrays.Array2D;

const Node = struct {
    pos: Vec2D(i32),
    score: u64,
};

fn lessThanNodeScore(context: void, a: Node, b: Node) std.math.Order {
    _ = context;
    return std.math.order(a.score, b.score);
}

fn find_path(grid: Array2D(bool), start_pos: Vec2D(i32), end_pos: Vec2D(i32), best_cost_grid: *Array2D(u64), prio_queue: *std.PriorityQueue(Node, void, lessThanNodeScore)) !u64 {
    best_cost_grid.fill(std.math.maxInt(u64));
    prio_queue.items.len = 0;

    try prio_queue.add(.{
        .pos = start_pos,
        .score = 0,
    });

    return blk: while (prio_queue.count() != 0) {
        const current = prio_queue.remove();

        if (current.pos.equals(end_pos)) {
            break :blk current.score;
        }

        for (Direction.cardinals) |direction| {
            const neighbor_pos = current.pos.add(direction.toNormVec2D(i32));

            if (!neighbor_pos.isWithinZeroRect(grid.dimensions.as(i32)) or grid.at(neighbor_pos.as(usize))) {
                continue;
            }

            const score = current.score + 1;
            if (score >= best_cost_grid.at(neighbor_pos.as(usize))) {
                continue;
            }

            best_cost_grid.set(neighbor_pos.as(usize), score);

            try prio_queue.add(.{
                .pos = neighbor_pos,
                .score = score,
            });
        }
    } else return error.NoPath;
}

fn solve(allocator: std.mem.Allocator, input: []const u8, num_tiles: usize, num_bytes_sim: u64) !struct {
    min_num_steps_reach_exit: u64,
    first_breaking_byte_pos: Vec2D(i32),
} {
    var incoming_bytes_positions = std.ArrayList(Vec2D(i32)).init(allocator);
    defer incoming_bytes_positions.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var comma_iter = std.mem.tokenizeScalar(u8, line, ',');
        try incoming_bytes_positions.append(.{
            .x = try std.fmt.parseInt(i32, comma_iter.next().?, 10),
            .y = try std.fmt.parseInt(i32, comma_iter.next().?, 10),
        });
    }

    const grid = try Array2D(bool).initDefault(allocator, Vec2D(usize){ .x = num_tiles, .y = num_tiles }, false);
    defer grid.deinit();

    const start_pos = Vec2D(i32){ .x = 0, .y = 0 };
    const end_pos = Vec2D(i32){ .x = @intCast(num_tiles - 1), .y = @intCast(num_tiles - 1) };

    var best_cost_grid = try Array2D(u64).initDefault(std.heap.page_allocator, grid.dimensions, std.math.maxInt(u64));
    defer best_cost_grid.deinit();
    best_cost_grid.set(start_pos.as(usize), 0);

    var prio_queue = std.PriorityQueue(Node, void, lessThanNodeScore).init(std.heap.page_allocator, {});
    defer prio_queue.deinit();

    // Part 1
    for (incoming_bytes_positions.items[0..num_bytes_sim]) |byte_pos| {
        grid.set(byte_pos.as(usize), true);
    }

    const shortest_path = try find_path(grid, start_pos, end_pos, &best_cost_grid, &prio_queue);

    // Part 2
    const first_breaking_byte_pos = blk: for (incoming_bytes_positions.items[num_bytes_sim..]) |byte_pos| {
        grid.set(byte_pos.as(usize), true);
        _ = find_path(grid, start_pos, end_pos, &best_cost_grid, &prio_queue) catch break :blk byte_pos;
    } else unreachable;

    return .{
        .min_num_steps_reach_exit = shortest_path,
        .first_breaking_byte_pos = first_breaking_byte_pos,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"), 71, 1024);
    std.debug.print("Day 18 - Part 1: {}\n", .{solution.min_num_steps_reach_exit});
    std.debug.print("Day 18 - Part 2: {},{}\n", .{ solution.first_breaking_byte_pos.x, solution.first_breaking_byte_pos.y });
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"), 7, 12);
    try std.testing.expectEqual(22, solution.min_num_steps_reach_exit);
    try std.testing.expectEqual(Vec2D(i32){ .x = 6, .y = 1 }, solution.first_breaking_byte_pos);
}

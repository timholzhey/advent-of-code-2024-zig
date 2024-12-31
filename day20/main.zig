const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;
const Array2D = @import("common").arrays.Array2D;

const Cheat = struct {
    start: Vec2D(usize),
    end: Vec2D(usize),
};

fn isPathContinuation(val: u8, _: Vec2D(usize)) bool {
    return val == '.' or val == 'E';
}

fn traverseGridCountCheats(allocator: std.mem.Allocator, grid: Array2D(u8), start_pos: Vec2D(i32), end_pos: Vec2D(i32), path_grid: Array2D(u64), max_cheat_distance: u64, saved_time_min_threshold: u64) !u64 {
    var known_cheats_map = std.AutoHashMap(Cheat, u64).init(allocator);
    defer known_cheats_map.deinit();

    var check_cheat_path_queue = std.ArrayList(Vec2D(i32)).init(allocator);
    defer check_cheat_path_queue.deinit();

    var visited_grid = try Array2D(bool).initDefault(allocator, grid.dimensions, false);
    defer visited_grid.deinit();

    var num_cheats_save_time: u64 = 0;

    var grid_traverse_iter = grid.traverse(start_pos.as(usize), end_pos.as(usize), &Direction.cardinals, isPathContinuation, true);
    while (grid_traverse_iter.next()) |element| {
        check_cheat_path_queue.clearRetainingCapacity();
        try check_cheat_path_queue.append(element.position.as(i32));

        visited_grid.fill(false);

        while (check_cheat_path_queue.items.len != 0) {
            const cheat_path_pos = check_cheat_path_queue.pop();

            const manhattan = @as(u64, @intCast(element.position.as(i32).manhattan(cheat_path_pos.as(i32))));
            if (manhattan > max_cheat_distance) {
                continue;
            }

            for (Direction.cardinals) |direction| {
                const neighbor_pos = cheat_path_pos.as(i32).add(direction.toNormVec2D(i32));
                if (!neighbor_pos.isWithinZeroRect(grid.dimensions.as(i32))) {
                    continue;
                }

                if (visited_grid.at(neighbor_pos.as(usize))) {
                    continue;
                }

                visited_grid.set(neighbor_pos.as(usize), true);
                try check_cheat_path_queue.append(neighbor_pos);
            }

            const this_index = path_grid.at(element.position);
            const other_index = path_grid.at(cheat_path_pos.as(usize));

            if (other_index == std.math.maxInt(u64) or other_index <= this_index + manhattan) {
                continue;
            }

            const saved_time = other_index - this_index - manhattan;

            if (saved_time < saved_time_min_threshold) {
                continue;
            }

            const cheat = Cheat{ .start = element.position, .end = cheat_path_pos.as(usize) };
            if (known_cheats_map.contains(cheat)) {
                continue;
            }

            try known_cheats_map.put(cheat, saved_time);
            num_cheats_save_time += 1;
        }
    }

    return num_cheats_save_time;
}

fn solve(allocator: std.mem.Allocator, input: []const u8, cheats_saved_time_threshold: u64) !struct {
    num_cheats_save_time_2: u64,
    num_cheats_save_time_20: u64,
} {
    const grid = try Array2D(u8).fromSliceDelim(allocator, input, "\n");
    defer grid.deinit();

    const start_pos = grid.find('S').?.as(i32);
    const end_pos = grid.find('E').?.as(i32);

    // Part 1
    var path_grid = try Array2D(u64).initDefault(allocator, grid.dimensions, std.math.maxInt(u64));
    defer path_grid.deinit();

    // Traverse path and mark with indices
    {
        var index: u64 = 0;
        var grid_traverse_iter = grid.traverse(start_pos.as(usize), end_pos.as(usize), &Direction.cardinals, isPathContinuation, true);
        while (grid_traverse_iter.next()) |element| {
            path_grid.set(element.position, index);
            index += 1;
        }
    }

    const num_cheats_save_time_2: u64 = try traverseGridCountCheats(allocator, grid, start_pos, end_pos, path_grid, 2, cheats_saved_time_threshold);
    const num_cheats_save_time_20: u64 = try traverseGridCountCheats(allocator, grid, start_pos, end_pos, path_grid, 20, cheats_saved_time_threshold);

    return .{
        .num_cheats_save_time_2 = num_cheats_save_time_2,
        .num_cheats_save_time_20 = num_cheats_save_time_20,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"), 100);
    std.debug.print("Day 20 - Part 1: {}\n", .{solution.num_cheats_save_time_2});
    std.debug.print("Day 20 - Part 2: {}\n", .{solution.num_cheats_save_time_20});
}

test "sample" {
    const solutionA = try solve(std.testing.allocator, @embedFile("sample.txt"), 0);
    try std.testing.expectEqual(44, solutionA.num_cheats_save_time_2);

    const solutionB = try solve(std.testing.allocator, @embedFile("sample.txt"), 50);
    try std.testing.expectEqual(285, solutionB.num_cheats_save_time_20);
}

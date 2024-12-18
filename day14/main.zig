const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;

const Robot = struct {
    position: Vec2D(i32),
    velocity: Vec2D(i32),
};

fn solve(allocator: std.mem.Allocator, input: []const u8, dimensions: Vec2D(i32)) !struct {
    num_robots_quadrant_product100: u64,
    num_iterations_xmas_tree_configuration: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    var robots_list = std.ArrayList(Robot).init(allocator);
    defer robots_list.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input_trimmed, '\n');
    while (line_iter.next()) |line| {
        const pos_start = std.mem.indexOf(u8, line, "p=").? + 2;
        const pos_sep = std.mem.indexOfScalar(u8, line[pos_start..], ',').?;
        const pos_end = std.mem.indexOfScalar(u8, line[pos_start + pos_sep + 1 ..], ' ').?;
        const pos_x = try std.fmt.parseInt(i32, line[pos_start .. pos_start + pos_sep], 10);
        const pos_y = try std.fmt.parseInt(i32, line[pos_start + pos_sep + 1 .. pos_start + pos_sep + 1 + pos_end], 10);

        const vel_start = std.mem.indexOf(u8, line, "v=").? + 2;
        const vel_sep = std.mem.indexOfScalar(u8, line[vel_start..], ',').?;
        const vel_x = try std.fmt.parseInt(i32, line[vel_start .. vel_start + vel_sep], 10);
        const vel_y = try std.fmt.parseInt(i32, line[vel_start + vel_sep + 1 ..], 10);

        try robots_list.append(.{
            .position = .{ .x = pos_x, .y = pos_y },
            .velocity = .{ .x = vel_x, .y = vel_y },
        });
    }

    var num_robots_quadrant_product100: u64 = 0;
    {
        var robots = try robots_list.clone();
        defer robots.deinit();

        for (0..100) |_| {
            for (robots.items) |*robot| {
                robot.position = robot.position.add(robot.velocity).modVec(dimensions);
            }
        }

        var num_robots_quadrants: [4]u64 = .{ 0, 0, 0, 0 };
        for (robots.items) |robot| {
            const half_dimensions = dimensions.divFloorScalar(2);
            if (robot.position.x == half_dimensions.x or robot.position.y == half_dimensions.y) continue;
            const quadrant = robot.position.divFloorVec(half_dimensions.add(.{ .x = 1, .y = 1 }));
            num_robots_quadrants[@intCast(quadrant.y * 2 + quadrant.x)] += 1;
        }

        num_robots_quadrant_product100 = num_robots_quadrants[0] * num_robots_quadrants[1] * num_robots_quadrants[2] * num_robots_quadrants[3];
    }

    var num_iterations_xmas_tree_configuration: u64 = 0;
    {
        var robots = try robots_list.clone();
        defer robots.deinit();

        var robots_visited_map = std.AutoHashMap(Vec2D(i32), bool).init(allocator);
        defer robots_visited_map.deinit();

        loop: for (0..10000) |iter| {
            robots_visited_map.clearRetainingCapacity();

            for (robots.items) |*robot| {
                robot.position = robot.position.add(robot.velocity).modVec(dimensions);
            }

            for (robots.items) |robot| {
                _ = try robots_visited_map.fetchPut(robot.position, false) orelse continue;
                continue :loop;
            }

            num_iterations_xmas_tree_configuration = iter + 1;
            break;
        }
    }

    return .{
        .num_robots_quadrant_product100 = num_robots_quadrant_product100,
        .num_iterations_xmas_tree_configuration = num_iterations_xmas_tree_configuration,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"), .{ .x = 101, .y = 103 });
    std.debug.print("Day 14 - Part 1: {}\n", .{solution.num_robots_quadrant_product100});
    std.debug.print("Day 14 - Part 2: {}\n", .{solution.num_iterations_xmas_tree_configuration});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"), .{ .x = 11, .y = 7 });
    try std.testing.expectEqual(12, solution.num_robots_quadrant_product100);
}

const std = @import("std");

fn evaluateReportSafety(report: []u32) struct {
    is_safe: bool,
    index: usize,
} {
    var is_all_increasing = true;
    var is_all_decreasing = true;

    if (report.len <= 1) unreachable;

    for (report[0 .. report.len - 1], 0..) |level, index| {
        const diff = @abs(@as(i64, level) - @as(i64, report[index + 1]));

        if (level > report[index + 1]) {
            is_all_increasing = false;
        } else if (level < report[index + 1]) {
            is_all_decreasing = false;
        }

        if ((!is_all_increasing and !is_all_decreasing) or (diff == 0 or diff > 3)) {
            return .{
                .is_safe = false,
                .index = index,
            };
        }
    }

    return .{
        .is_safe = true,
        .index = 0,
    };
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_safe_reports: u64,
    num_safe_reports_dampener: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const num_lines = std.mem.count(u8, input_trimmed, "\n") + 1;
    var reports = try std.ArrayList(std.ArrayList(u32)).initCapacity(allocator, num_lines);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }

    var lines_iter = std.mem.tokenizeScalar(u8, input_trimmed, '\n');
    while (lines_iter.next()) |line| {
        var report = std.ArrayList(u32).init(allocator);

        var columns_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (columns_iter.next()) |column| {
            const level = try std.fmt.parseInt(u32, column, 10);
            try report.append(level);
        }

        try reports.append(report);
    }

    // Part 1
    var num_safe_reports: u64 = 0;
    for (reports.items) |report| {
        if (!evaluateReportSafety(report.items).is_safe) continue;
        num_safe_reports += 1;
    }

    // Part 2
    var num_safe_reports_dampener: u64 = 0;
    for (reports.items) |report| {
        const report_result = evaluateReportSafety(report.items);
        if (report_result.is_safe) {
            num_safe_reports_dampener += 1;
            continue;
        }

        var report_short = try std.ArrayList(u32).initCapacity(allocator, report.items.len - 1);
        defer report_short.deinit();

        for (report.items, 0..) |level, index| {
            if (index == report_result.index) continue;
            try report_short.append(level);
        }

        if (evaluateReportSafety(report_short.items).is_safe) {
            num_safe_reports_dampener += 1;
            continue;
        }

        report_short.items[report_result.index] = report.items[report_result.index];
        if (evaluateReportSafety(report_short.items).is_safe) {
            num_safe_reports_dampener += 1;
            continue;
        }

        @memcpy(report_short.items[0..], report.items[1..]);
        if (evaluateReportSafety(report_short.items).is_safe) {
            num_safe_reports_dampener += 1;
            continue;
        }
    }

    return .{
        .num_safe_reports = num_safe_reports,
        .num_safe_reports_dampener = num_safe_reports_dampener,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 02 - Part 1: {}\n", .{solution.num_safe_reports});
    std.debug.print("Day 02 - Part 2: {}\n", .{solution.num_safe_reports_dampener});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(2, solution.num_safe_reports);
    try std.testing.expectEqual(4, solution.num_safe_reports_dampener);
}

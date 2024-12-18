const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var days_completed: [25]bool = .{false} ** 25;

    const build_all = b.step("build_all", "Build all days");
    const run_all = b.step("run_all", "Run all days");
    const test_all = b.step("test_all", "Test all days");

    const common_module = b.addModule("common", .{
        .root_source_file = b.path("common/module.zig"),
    });

    for (0..25) |advent_day| {
        const day_str = try std.fmt.allocPrint(b.allocator, "day{:0>2}", .{advent_day});
        defer b.allocator.free(day_str);

        _ = std.fs.cwd().openDir(b.path(day_str).getPath(b), .{}) catch continue;
        days_completed[advent_day] = true;

        const day_main_file_str = try std.fmt.allocPrint(b.allocator, "{s}/main.zig", .{day_str});
        defer b.allocator.free(day_main_file_str);

        const exe = b.addExecutable(.{
            .name = day_str,
            .root_source_file = b.path(day_main_file_str),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("common", common_module);

        b.installArtifact(exe);
        build_all.dependOn(&exe.step);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step_name = try std.fmt.allocPrint(b.allocator, "run_{s}", .{day_str});
        defer b.allocator.free(run_step_name);

        const run_step = b.step(run_step_name, "Run the app");
        run_step.dependOn(&run_cmd.step);
        run_all.dependOn(run_step);

        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path(day_main_file_str),
            .target = target,
            .optimize = optimize,
        });
        exe_unit_tests.root_module.addImport("common", common_module);

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const run_unit_tests_step_name = try std.fmt.allocPrint(b.allocator, "test_{s}", .{day_str});
        defer b.allocator.free(run_unit_tests_step_name);

        const test_step = b.step(run_unit_tests_step_name, "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
        test_all.dependOn(test_step);
    }
}

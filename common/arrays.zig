const std = @import("std");
const Vec2D = @import("vectors.zig").Vec2D;
const Direction = @import("compass.zig").Direction;

pub fn Array2D(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Error = std.mem.Allocator.Error || error{InvalidDimensions};

        dimensions: Vec2D(usize),
        elements: std.ArrayList(T),

        pub const Iterator = struct {
            arr: *const Self,
            index: usize = 0,

            pub const Element = struct {
                position: Vec2D(usize),
                value: T,
            };

            pub fn next(it: *Iterator) ?Element {
                if (it.index >= it.arr.dimensions.x * it.arr.dimensions.y) {
                    return null;
                }

                const position = Vec2D(usize).from2DIndex(it.index, it.arr.dimensions.x);
                const value = it.arr.at(position);
                it.index += 1;

                return .{
                    .position = position,
                    .value = value,
                };
            }
        };

        pub const FilterIterator = struct {
            arr: *const Self,
            index: usize = 0,
            filter: FilterFunction,

            pub const FilterFunction = *const fn (T, Vec2D(usize)) bool;

            pub const Element = struct {
                position: Vec2D(usize),
                value: T,
            };

            pub fn next(it: *FilterIterator) ?Element {
                while (it.index < it.arr.dimensions.x * it.arr.dimensions.y) {
                    const position = Vec2D(usize).from2DIndex(it.index, it.arr.dimensions.x);
                    const value = it.arr.at(position);
                    it.index += 1;

                    if (it.filter(value, position)) {
                        return .{
                            .position = position,
                            .value = value,
                        };
                    }
                }

                return null;
            }
        };

        pub const TraversalIterator = struct {
            arr: *const Self,
            position: ?Vec2D(usize),
            start: Vec2D(usize),
            end: Vec2D(usize),
            directions: []const Direction,
            path_condition: PathCondition,
            lookback_pos: ?Vec2D(usize),

            pub const PathCondition = *const fn (T, Vec2D(usize)) bool;

            pub const Element = struct {
                position: Vec2D(usize),
                value: T,
            };

            pub fn next(it: *TraversalIterator) ?Element {
                if (it.position == null) {
                    it.position = it.start;
                    return .{
                        .position = it.start,
                        .value = it.arr.at(it.start),
                    };
                }

                for (it.directions) |direction| {
                    const neighbor_pos = it.position.?.as(i32).add(direction.toNormVec2D(i32));
                    if (!neighbor_pos.isWithinZeroRect(it.arr.dimensions.as(i32))) {
                        continue;
                    }

                    const next_pos = neighbor_pos.as(usize);
                    if (it.lookback_pos) |back_pos| {
                        if (next_pos.equals(back_pos)) {
                            continue;
                        }
                    }

                    const value = it.arr.at(next_pos);
                    if (!it.path_condition(value, next_pos)) {
                        continue;
                    }

                    if (it.lookback_pos) |_| {
                        it.lookback_pos = it.position.?;
                    }
                    it.position = next_pos;

                    return .{
                        .position = next_pos,
                        .value = value,
                    };
                }

                return null;
            }
        };

        /// Initializes an Array2D with fixed dimensions, allocates memory for the elements.
        /// The elements are not initialized and must be set manually.
        pub fn init(allocator: std.mem.Allocator, dimensions: Vec2D(usize)) std.mem.Allocator.Error!Self {
            var elements = try std.ArrayList(T).initCapacity(allocator, dimensions.x * dimensions.y);
            elements.expandToCapacity();

            return .{
                .dimensions = dimensions,
                .elements = elements,
            };
        }

        // Initializes an Array2D with fixed dimensions and fills it with a default value.
        pub fn initDefault(allocator: std.mem.Allocator, dimensions: Vec2D(usize), fill_value: T) std.mem.Allocator.Error!Self {
            var arr = try Self.init(allocator, dimensions);
            arr.fill(fill_value);
            return arr;
        }

        /// Initializes an Array2D from a slice of elements with rows separated by a delimiter slice.
        /// The dimensions are inferred by the delimiter.
        /// Each row must have the same number of elements.
        /// Stops at end of input or when an empty row is encountered (two consecutive delimiters).
        pub fn fromSliceDelim(allocator: std.mem.Allocator, slice: []const T, delim: []const T) Error!Self {
            var dimensions = Vec2D(usize){
                .x = 0,
                .y = 0,
            };
            var elements = std.ArrayList(T).init(allocator);

            var iter = std.mem.split(T, slice, delim);
            while (iter.next()) |line| {
                if (line.len == 0) {
                    break;
                }

                if (dimensions.x == 0) {
                    dimensions.x = line.len;
                } else if (dimensions.x != line.len) {
                    return error.InvalidDimensions;
                }
                dimensions.y += 1;

                try elements.appendSlice(line);
            }

            return .{
                .dimensions = dimensions,
                .elements = elements,
            };
        }

        pub fn fill(self: Self, value: T) void {
            @memset(self.elements.items, value);
        }

        pub fn find(self: Self, element: T) ?Vec2D(usize) {
            const index = std.mem.indexOfScalar(T, self.elements.items, element);
            if (index) |idx| {
                return Vec2D(usize).from2DIndex(idx, self.dimensions.x);
            }
            return null;
        }

        pub fn contains(self: Self, element: T) bool {
            return self.find(element) != null;
        }

        pub fn at(self: Self, pos: Vec2D(usize)) T {
            return self.elements.items[pos.to2DIndex(self.dimensions.x)];
        }

        pub fn set(self: Self, pos: Vec2D(usize), element: T) void {
            self.elements.items[pos.to2DIndex(self.dimensions.x)] = element;
        }

        pub fn setSlice(self: Self, pos: Vec2D(usize), slice: []const T) void {
            const index = pos.to2DIndex(self.dimensions.x);
            for (slice, 0..) |elem, i| {
                self.elements.items[index + i] = elem;
            }
        }

        pub fn iterator(self: *const Self) Iterator {
            return .{
                .arr = self,
            };
        }

        pub fn filter(self: *const Self, comptime filter_fn: fn (T, Vec2D(usize)) bool) FilterIterator {
            return .{
                .arr = self,
                .filter = filter_fn,
            };
        }

        pub fn traverse(self: *const Self, start_pos: Vec2D(usize), end_pos: Vec2D(usize), directions: []const Direction, path_condition: TraversalIterator.PathCondition, lookback: bool) TraversalIterator {
            return .{
                .arr = self,
                .position = null,
                .start = start_pos,
                .end = end_pos,
                .directions = directions,
                .path_condition = path_condition,
                .lookback_pos = if (lookback) start_pos else null,
            };
        }

        pub fn clone(self: Self) std.mem.Allocator.Error!Self {
            return .{
                .dimensions = self.dimensions,
                .elements = try self.elements.clone(),
            };
        }

        pub fn deinit(self: Self) void {
            self.elements.deinit();
        }
    };
}

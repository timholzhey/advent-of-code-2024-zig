const std = @import("std");

const MemBlock = struct {
    is_free: bool,
    id: u64,
    offset: u64,
    size: u64,
};

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    reordered_blocks_single_checksum: u64,
    reordered_blocks_whole_checksum: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = arena.allocator();

    const BlocksList = std.DoublyLinkedList(MemBlock);
    var mem_blocks = BlocksList{};

    {
        var id: u64 = 0;
        var is_free = false;
        var offset: u64 = 0;

        for (0..input_trimmed.len) |index| {
            const digit = try std.fmt.parseInt(u64, input_trimmed[index .. index + 1], 10);

            const block = try arena_allocator.create(BlocksList.Node);
            block.data = MemBlock{ .is_free = is_free, .id = id, .offset = offset, .size = digit };
            mem_blocks.append(block);

            id += if (is_free) 1 else 0;
            offset += digit;
            is_free = !is_free;
        }
    }

    // Part 1
    var reordered_blocks_single_checksum: u64 = 0;
    {
        var blocks = BlocksList{};
        var current_block = mem_blocks.first;

        while (current_block) |block| : (current_block = block.next) {
            const new_block = try arena_allocator.create(BlocksList.Node);
            new_block.data = block.data;
            blocks.append(new_block);
        }

        current_block = blocks.first;

        // Reorder blocks
        outer: while (current_block) |block| {
            if (!block.data.is_free or block.data.size == 0) {
                current_block = block.next;
                continue;
            }

            const last_used_block: *BlocksList.Node = blk: while (true) {
                const last_block = blocks.last orelse break :outer;
                if (last_block.data.is_free or last_block.data.size == 0) {
                    _ = blocks.pop();
                    continue;
                }
                break :blk last_block;
            };

            const max_fill_free = @min(last_used_block.data.size, block.data.size);
            if (max_fill_free == block.data.size) {
                block.data.is_free = false;
                block.data.id = last_used_block.data.id;
                current_block = block.next;
            } else {
                const new_block = try arena_allocator.create(BlocksList.Node);
                new_block.data = MemBlock{ .is_free = false, .id = last_used_block.data.id, .offset = block.data.offset, .size = max_fill_free };
                blocks.insertBefore(block, new_block);

                block.data.size -= max_fill_free;
                block.data.offset += max_fill_free;
            }

            last_used_block.data.size -= max_fill_free;
            if (last_used_block.data.size == 0) {
                _ = blocks.pop();
            }
        }

        // Calculate checksum
        current_block = blocks.first;

        while (current_block) |block| : (current_block = block.next) {
            if (block.data.is_free) {
                continue;
            }
            for (0..block.data.size) |i| {
                reordered_blocks_single_checksum += block.data.id * (block.data.offset + i);
            }
        }
    }

    // Part 2
    var reordered_blocks_whole_checksum: u64 = 0;
    {
        var blocks = BlocksList{};
        var current_block = mem_blocks.first;

        while (current_block) |block| : (current_block = block.next) {
            const new_block = try arena_allocator.create(BlocksList.Node);
            new_block.data = block.data;
            blocks.append(new_block);
        }

        current_block = blocks.last;

        // Reorder files
        blk: while (current_block) |block| {
            if (block.data.is_free) {
                current_block = block.prev;
                continue;
            }

            var find_free_block = blocks.first;
            while (find_free_block) |free_block| : (find_free_block = free_block.next) {
                if (free_block.data.offset > block.data.offset) {
                    break;
                }

                if (!free_block.data.is_free or free_block.data.size < block.data.size) {
                    continue;
                }

                if (block.data.size == free_block.data.size) {
                    free_block.data.is_free = false;
                    free_block.data.id = block.data.id;
                } else {
                    const new_block = try arena_allocator.create(BlocksList.Node);
                    new_block.data = MemBlock{ .is_free = false, .id = block.data.id, .offset = free_block.data.offset, .size = block.data.size };
                    blocks.insertBefore(free_block, new_block);

                    free_block.data.size -= block.data.size;
                    free_block.data.offset += block.data.size;
                }

                current_block = block.prev;
                blocks.remove(block);
                continue :blk;
            }

            current_block = block.prev;
        }

        // Calculate checksum
        current_block = blocks.first;

        while (current_block) |block| : (current_block = block.next) {
            if (block.data.is_free) {
                continue;
            }
            for (0..block.data.size) |i| {
                reordered_blocks_whole_checksum += block.data.id * (block.data.offset + i);
            }
        }
    }

    return .{
        .reordered_blocks_single_checksum = reordered_blocks_single_checksum,
        .reordered_blocks_whole_checksum = reordered_blocks_whole_checksum,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 09 - Part 1: {}\n", .{solution.reordered_blocks_single_checksum});
    std.debug.print("Day 09 - Part 2: {}\n", .{solution.reordered_blocks_whole_checksum});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(1928, solution.reordered_blocks_single_checksum);
    try std.testing.expectEqual(2858, solution.reordered_blocks_whole_checksum);
}

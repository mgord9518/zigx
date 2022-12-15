// A working example to test various parts of the API
const std = @import("std");
const x = @import("./x.zig");
const common = @import("common.zig");
const Memfd = x.Memfd;
const ContiguousReadBuffer = @import("ContiguousReadBuffer.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

const window_width = 400;
const window_height = 400;

pub fn main() !u8 {
    const conn = try common.connect(allocator);
    defer std.os.shutdown(conn.sock, .both) catch {};

    const screen = blk: {
        const fixed = conn.setup.fixed();
        inline for (@typeInfo(@TypeOf(fixed.*)).Struct.fields) |field| {
            std.log.debug("{s}: {any}", .{field.name, @field(fixed, field.name)});
        }
        std.log.debug("vendor: {s}", .{try conn.setup.getVendorSlice(fixed.vendor_len)});
        const format_list_offset = x.ConnectSetup.getFormatListOffset(fixed.vendor_len);
        const format_list_limit = x.ConnectSetup.getFormatListLimit(format_list_offset, fixed.format_count);
        std.log.debug("fmt list off={} limit={}", .{format_list_offset, format_list_limit});
        const formats = try conn.setup.getFormatList(format_list_offset, format_list_limit);
        for (formats) |format, i| {
            std.log.debug("format[{}] depth={:3} bpp={:3} scanpad={:3}", .{i, format.depth, format.bits_per_pixel, format.scanline_pad});
        }
        var screen = conn.setup.getFirstScreenPtr(format_list_limit);
        inline for (@typeInfo(@TypeOf(screen.*)).Struct.fields) |field| {
            std.log.debug("SCREEN 0| {s}: {any}", .{field.name, @field(screen, field.name)});
        }
        break :blk screen;
    };

    // TODO: maybe need to call conn.setup.verify or something?

    const window_id = conn.setup.fixed().resource_id_base;
    {
        var msg_buf: [x.create_window.max_len]u8 = undefined;
        const len = x.create_window.serialize(&msg_buf, .{
            .window_id = window_id,
            .parent_window_id = screen.root,
            .depth = 0, // we don't care, just inherit from the parent
            .x = 0, .y = 0,
            .width = window_width, .height = window_height,
            .border_width = 0, // TODO: what is this?
            .class = .input_output,
            .visual_id = screen.root_visual,
        }, .{
//            .bg_pixmap = .copy_from_parent,
            .bg_pixel = 0xaabbccdd,
//            //.border_pixmap =
//            .border_pixel = 0x01fa8ec9,
//            .bit_gravity = .north_west,
//            .win_gravity = .east,
//            .backing_store = .when_mapped,
//            .backing_planes = 0x1234,
//            .backing_pixel = 0xbbeeeeff,
//            .override_redirect = true,
//            .save_under = true,
            .event_mask =
                  x.event.key_press
                | x.event.key_release
                | x.event.button_press
                | x.event.button_release
                | x.event.enter_window
                | x.event.leave_window
                | x.event.pointer_motion
//                | x.event.pointer_motion_hint WHAT THIS DO?
//                | x.event.button1_motion  WHAT THIS DO?
//                | x.event.button2_motion  WHAT THIS DO?
//                | x.event.button3_motion  WHAT THIS DO?
//                | x.event.button4_motion  WHAT THIS DO?
//                | x.event.button5_motion  WHAT THIS DO?
//                | x.event.button_motion  WHAT THIS DO?
                | x.event.keymap_state
                | x.event.exposure
                ,
//            .dont_propagate = 1,
        });
        try conn.send(msg_buf[0..len]);
    }

    const bg_gc_id = window_id + 1;
    {
        var msg_buf: [x.create_gc.max_len]u8 = undefined;
        const len = x.create_gc.serialize(&msg_buf, .{
            .gc_id = bg_gc_id,
            .drawable_id = screen.root,
        }, .{
            .foreground = screen.black_pixel,
        });
        try conn.send(msg_buf[0..len]);
    }
    const fg_gc_id = window_id + 2;
    {
        var msg_buf: [x.create_gc.max_len]u8 = undefined;
        const len = x.create_gc.serialize(&msg_buf, .{
            .gc_id = fg_gc_id,
            .drawable_id = screen.root,
        }, .{
            .background = screen.black_pixel,
            .foreground = 0xffaadd,
        });
        try conn.send(msg_buf[0..len]);
    }

    // get some font information
    {
        const text_literal = [_]u16 { 'm' };
        const text = x.Slice(u16, [*]const u16) { .ptr = &text_literal, .len = text_literal.len };
        var msg: [x.query_text_extents.getLen(text.len)]u8 = undefined;
        x.query_text_extents.serialize(&msg, fg_gc_id, text);
        try conn.send(&msg);
    }

    const buf_memfd = try Memfd.init("ZigX11DoubleBuffer");
    // no need to deinit
    const buffer_capacity = std.mem.alignForward(1000, std.mem.page_size);
    std.log.info("buffer capacity is {}", .{buffer_capacity});
    var buf = ContiguousReadBuffer { .double_buffer_ptr = try buf_memfd.toDoubleBuffer(buffer_capacity), .half_size = buffer_capacity };

    const font_dims: FontDims = blk: {
        _ = try x.readOneMsg(conn.reader(), @alignCast(4, buf.nextReadBuffer()));
        switch (x.serverMsgTaggedUnion(@alignCast(4, buf.double_buffer_ptr))) {
            .reply => |msg_reply| {
                const msg = @ptrCast(*x.ServerMsg.QueryTextExtents, msg_reply);
                break :blk .{
                    .width = @intCast(u8, msg.overall_width),
                    .height = @intCast(u8, msg.font_ascent + msg.font_descent),
                    .font_left = @intCast(i16, msg.overall_left),
                    .font_ascent = msg.font_ascent,
                };
            },
            else => |msg| {
                std.log.err("expected a reply but got {}", .{msg});
                return 1;
            },
        }
    };


    {
        const ext_name = comptime x.Slice(u16, [*]const u8).initComptime("RENDER");
        var msg: [x.query_extension.getLen(ext_name.len)]u8 = undefined;
        x.query_extension.serialize(&msg, ext_name);
        try conn.send(&msg);
    }
    _ = try x.readOneMsg(conn.reader(), @alignCast(4, buf.nextReadBuffer()));
    const opt_render_ext: ?struct { opcode: u8 } = blk: {
        switch (x.serverMsgTaggedUnion(@alignCast(4, buf.double_buffer_ptr))) {
            .reply => |msg_reply| {
                const msg = @ptrCast(*x.ServerMsg.QueryExtension, msg_reply);
                if (msg.present == 0) {
                    std.log.info("RENDER extension: not present", .{});
                    break :blk null;
                }
                std.debug.assert(msg.present == 1);
                std.log.info("RENDER extension: opcode={}", .{msg.major_opcode});
                break :blk .{ .opcode = msg.major_opcode };
            },
            else => |msg| {
                std.log.err("expected a reply but got {}", .{msg});
                return 1;
            },

        }
    };
    if (opt_render_ext) |render_ext| {
        {
            var msg: [x.render.query_version.len]u8 = undefined;
            x.render.query_version.serialize(&msg, render_ext.opcode, .{
                .major_version = 0,
                .minor_version = 11,
            });
            try conn.send(&msg);
        }
        _ = try x.readOneMsg(conn.reader(), @alignCast(4, buf.nextReadBuffer()));
        switch (x.serverMsgTaggedUnion(@alignCast(4, buf.double_buffer_ptr))) {
            .reply => |msg_reply| {
                const msg = @ptrCast(*x.render.query_version.Reply, msg_reply);
                std.log.info("RENDER extension: version {}.{}", .{msg.major_version, msg.minor_version});
                if (msg.major_version != 0) {
                    std.log.err("xrender extension major version {} too new", .{msg.major_version});
                    return 1;
                }
                if (msg.minor_version < 11) {
                    std.log.err("xrender extension minor version {} too old", .{msg.minor_version});
                    return 1;
                }
            },
            else => |msg| {
                std.log.err("expected a reply but got {}", .{msg});
                return 1;
            },
        }
    }

    {
        var msg: [x.map_window.len]u8 = undefined;
        x.map_window.serialize(&msg, window_id);
        try conn.send(&msg);
    }

    while (true) {
        {
            const recv_buf = buf.nextReadBuffer();
            if (recv_buf.len == 0) {
                std.log.err("buffer size {} not big enough!", .{buf.half_size});
                return 1;
            }
            const len = try std.os.recv(conn.sock, recv_buf, 0);
            if (len == 0) {
                std.log.info("X server connection closed", .{});
                return 0;
            }
            buf.reserve(len);
        }
        while (true) {
            const data = buf.nextReservedBuffer();
            const msg_len = x.parseMsgLen(@alignCast(4, data));
            if (msg_len == 0)
                break;
            buf.release(msg_len);
            //buf.resetIfEmpty();
            switch (x.serverMsgTaggedUnion(@alignCast(4, data.ptr))) {
                .err => |msg| {
                    std.log.err("{}", .{msg});
                    return 1;
                },
                .reply => |msg| {
                    std.log.info("todo: handle a reply message {}", .{msg});
                    return error.TodoHandleReplyMessage;
                },
                .key_press => |msg| {
                    std.log.info("key_press: keycode={}", .{msg.keycode});
                },
                .key_release => |msg| {
                    std.log.info("key_release: keycode={}", .{msg.keycode});
                },
                .button_press => |msg| {
                    std.log.info("button_press: {}", .{msg});
                },
                .button_release => |msg| {
                    std.log.info("button_release: {}", .{msg});
                },
                .enter_notify => |msg| {
                    std.log.info("enter_window: {}", .{msg});
                },
                .leave_notify => |msg| {
                    std.log.info("leave_window: {}", .{msg});
                },
                .motion_notify => |msg| {
                    // too much logging
                    _ = msg;
                    //std.log.info("pointer_motion: {}", .{msg});
                },
                .keymap_notify => |msg| {
                    std.log.info("keymap_state: {}", .{msg});
                },
                .expose => |msg| {
                    std.log.info("expose: {}", .{msg});
                    try render(conn.sock, window_id, bg_gc_id, fg_gc_id, font_dims);
                },
                .mapping_notify => |msg| {
                    std.log.info("mapping_notify: {}", .{msg});
                },
                .unhandled => |msg| {
                    std.log.info("todo: server msg {}", .{msg});
                    return error.UnhandledServerMsg;
                },
            }
        }
    }
}

const FontDims = struct {
    width: u8,
    height: u8,
    font_left: i16, // pixels to the left of the text basepoint
    font_ascent: i16, // pixels up from the text basepoint to the top of the text
};

fn render(sock: std.os.socket_t, drawable_id: u32, bg_gc_id: u32, fg_gc_id: u32, font_dims: FontDims) !void {
    {
        var msg: [x.poly_fill_rectangle.getLen(1)]u8 = undefined;
        x.poly_fill_rectangle.serialize(&msg, .{
            .drawable_id = drawable_id,
            .gc_id = bg_gc_id,
        }, &[_]x.Rectangle {
            .{ .x = 100, .y = 100, .width = 200, .height = 200 },
        });
        try common.send(sock, &msg);
    }
    {
        var msg: [x.clear_area.len]u8 = undefined;
        x.clear_area.serialize(&msg, false, drawable_id, .{
            .x = 150, .y = 150, .width = 100, .height = 100,
        });
        try common.send(sock, &msg);
    }


    try changeGcColor(sock, fg_gc_id, 0xffaadd);
    {
        const text_literal: []const u8 = "Hello X!";
        const text = x.Slice(u8, [*]const u8) { .ptr = text_literal.ptr, .len = text_literal.len };
        var msg: [x.image_text8.getLen(text.len)]u8 = undefined;

        const text_width = font_dims.width * text_literal.len;

        x.image_text8.serialize(&msg, text, .{
            .drawable_id = drawable_id,
            .gc_id = fg_gc_id,
            .x = @divTrunc((window_width - @intCast(i16, text_width)),  2) + font_dims.font_left,
            .y = @divTrunc((window_height - @intCast(i16, font_dims.height)), 2) + font_dims.font_ascent,
        });
        try common.send(sock, &msg);
    }

    try changeGcColor(sock, fg_gc_id, 0x00ff00);
    {
        const rectangles = [_]x.Rectangle{
            .{ .x = 20, .y = 20, .width = 15, .height = 15 },
            .{ .x = 40, .y = 20, .width = 15, .height = 15 },
        };
        var msg: [x.poly_fill_rectangle.getLen(rectangles.len)]u8 = undefined;
        x.poly_fill_rectangle.serialize(&msg, .{
            .drawable_id = drawable_id,
            .gc_id = fg_gc_id,
        }, &rectangles);
        try common.send(sock, &msg);
    }
    try changeGcColor(sock, fg_gc_id, 0x0000ff);
    {
        const rectangles = [_]x.Rectangle{
            .{ .x = 60, .y = 20, .width = 15, .height = 15 },
            .{ .x = 80, .y = 20, .width = 15, .height = 15 },
        };
        var msg: [x.poly_rectangle.getLen(rectangles.len)]u8 = undefined;
        x.poly_rectangle.serialize(&msg, .{
            .drawable_id = drawable_id,
            .gc_id = fg_gc_id,
        }, &rectangles);
        try common.send(sock, &msg);
    }
}

fn changeGcColor(sock: std.os.socket_t, gc_id: u32, color: u32) !void {
    var msg_buf: [x.change_gc.max_len]u8 = undefined;
    const len = x.change_gc.serialize(&msg_buf, gc_id, .{
        .foreground = color,
    });
    try common.send(sock, msg_buf[0..len]);
}

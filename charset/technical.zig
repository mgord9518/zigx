const Combined = @import("combined.zig").Combined;
pub const Technical = enum(u8) {
    left_radical = 161,
    top_left_radical = 162,
    horizontal_connector = 163,
    top_integral = 164,
    bottom_integral = 165,
    vertical_connector = 166,
    top_left_square_bracket = 167,
    bottom_left_square_bracket = 168,
    top_right_square_bracket = 169,
    bottom_right_square_bracket = 170,
    top_left_paren = 171,
    bottom_left_paren = 172,
    top_right_paren = 173,
    bottom_right_paren = 174,
    left_middle_curly_brace = 175,
    right_middle_curly_brace = 176,
    top_left_summation = 177,
    bottom_left_summation = 178,
    top_vertical_summation_connector = 179,
    bottom_vertical_summation_connector = 180,
    top_right_summation = 181,
    bottom_right_summation = 182,
    right_middle_summation = 183,
    less_than_or_equal_sign = 188,
    not_equal_sign = 189,
    greater_than_or_equal_sign = 190,
    integral = 191,
    therefore = 192,
    variation_proportional_to = 193,
    infinity = 194,
    nabla_del = 197,
    is_approximate_to = 200,
    similar_or_equal_to = 201,
    if_and_only_if = 205,
    implies = 206,
    identical_to = 207,
    radical = 214,
    is_included_in = 218,
    includes = 219,
    intersection = 220,
    @"union" = 221,
    logical_and = 222,
    logical_or = 223,
    partial_derivative = 239,
    function = 246,
    left_arrow = 251,
    upward_arrow = 252,
    right_arrow = 253,
    downward_arrow = 254,

    pub fn toCombined(self: Technical) Combined {
        return @intToEnum(Combined, (@as(u16, 8) << 8) | @enumToInt(self));
    }
    pub fn next(self: Technical) Technical {
        return @intToEnum(Technical, @enumToInt(self) + 1);
    }
};
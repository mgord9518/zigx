const Combined = @import("combined.zig").Combined;
pub const Arabic = enum(u8) {
    comma = 172,
    semicolon = 187,
    question_mark = 191,
    letter_hamza = 193,
    letter_madda_on_alef = 194,
    letter_hamza_on_alef = 195,
    letter_hamza_on_waw = 196,
    letter_hamza_under_alef = 197,
    letter_hamza_on_yeh = 198,
    letter_alef = 199,
    letter_beh = 200,
    letter_teh_marbuta = 201,
    letter_teh = 202,
    letter_theh = 203,
    letter_jeem = 204,
    letter_hah = 205,
    letter_khah = 206,
    letter_dal = 207,
    letter_thal = 208,
    letter_ra = 209,
    letter_zain = 210,
    letter_seen = 211,
    letter_sheen = 212,
    letter_sad = 213,
    letter_dad = 214,
    letter_tah = 215,
    letter_zah = 216,
    letter_ain = 217,
    letter_ghain = 218,
    letter_tatweel = 224,
    letter_feh = 225,
    letter_qaf = 226,
    letter_kaf = 227,
    letter_lam = 228,
    letter_meem = 229,
    letter_noon = 230,
    letter_ha = 231,
    letter_waw = 232,
    letter_alef_maksura = 233,
    letter_yeh = 234,
    letter_fathatan = 235,
    letter_dammatan = 236,
    letter_kasratan = 237,
    letter_fatha = 238,
    letter_damma = 239,
    letter_kasra = 240,
    letter_shadda = 241,
    letter_sukun = 242,

    pub fn toCombined(self: Arabic) Combined {
        return @as(Combined, @enumFromInt((@as(u16, 5) << 8) | @intFromEnum(self)));
    }
    pub fn next(self: Arabic) Arabic {
        return @as(Arabic, @enumFromInt(@intFromEnum(self) + 1));
    }
};

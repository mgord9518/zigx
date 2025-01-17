const Combined = @import("combined.zig").Combined;
pub const Thai = enum(u8) {
    kokai = 161,
    khokhai = 162,
    khokhuat = 163,
    khokhwai = 164,
    khokhon = 165,
    khorakhang = 166,
    ngongu = 167,
    chochan = 168,
    choching = 169,
    chochang = 170,
    soso = 171,
    chochoe = 172,
    yoying = 173,
    dochada = 174,
    topatak = 175,
    thothan = 176,
    thonangmontho = 177,
    thophuthao = 178,
    nonen = 179,
    dodek = 180,
    totao = 181,
    thothung = 182,
    thothahan = 183,
    thothong = 184,
    nonu = 185,
    bobaimai = 186,
    popla = 187,
    phophung = 188,
    fofa = 189,
    phophan = 190,
    fofan = 191,
    phosamphao = 192,
    moma = 193,
    yoyak = 194,
    rorua = 195,
    ru = 196,
    loling = 197,
    lu = 198,
    wowaen = 199,
    sosala = 200,
    sorusi = 201,
    sosua = 202,
    hohip = 203,
    lochula = 204,
    oang = 205,
    honokhuk = 206,
    paiyannoi = 207,
    saraa = 208,
    maihanakat = 209,
    saraaa = 210,
    saraam = 211,
    sarai = 212,
    saraii = 213,
    saraue = 214,
    sarauee = 215,
    sarau = 216,
    sarauu = 217,
    phinthu = 218,
    maihanakat2 = 222,
    baht = 223,
    sarae = 224,
    saraae = 225,
    sarao = 226,
    saraaimaimuan = 227,
    saraaimaimalai = 228,
    lakkhangyao = 229,
    maiyamok = 230,
    maitaikhu = 231,
    maiek = 232,
    maitho = 233,
    maitri = 234,
    maichattawa = 235,
    thanthakhat = 236,
    nikhahit = 237,
    leksun = 240,
    leknung = 241,
    leksong = 242,
    leksam = 243,
    leksi = 244,
    lekha = 245,
    lekhok = 246,
    lekchet = 247,
    lekpaet = 248,
    lekkao = 249,

    pub fn toCombined(self: Thai) Combined {
        return @as(Combined, @enumFromInt((@as(u16, 13) << 8) | @intFromEnum(self)));
    }
    pub fn next(self: Thai) Thai {
        return @as(Thai, @enumFromInt(@intFromEnum(self) + 1));
    }
};

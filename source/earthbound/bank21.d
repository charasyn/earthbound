module earthbound.bank21;

import earthbound.commondefs;

// $E1CE08
immutable SpriteMap[][9] UnknownE1CF9D = [
	[
		SpriteMap(0x10, 0x3052, 0x04, 0x00),
		SpriteMap(0x08, 0x3042, 0x04, 0x00),
		SpriteMap(0x08, 0x3040, 0xF4, 0x01),
		SpriteMap(0x00, 0x3032, 0x04, 0x00),
		SpriteMap(0xF8, 0x3022, 0x04, 0x00),
		SpriteMap(0xF8, 0x3020, 0xF4, 0x01),
		SpriteMap(0xF0, 0x3012, 0x04, 0x00),
		SpriteMap(0xE8, 0x3002, 0x04, 0x00),
		SpriteMap(0xE8, 0x3000, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x3055, 0x04, 0x00),
		SpriteMap(0x08, 0x3045, 0x04, 0x00),
		SpriteMap(0x08, 0x3043, 0xF4, 0x01),
		SpriteMap(0x00, 0x3035, 0x04, 0x00),
		SpriteMap(0xF8, 0x3025, 0x04, 0x00),
		SpriteMap(0xF8, 0x3023, 0xF4, 0x01),
		SpriteMap(0xF0, 0x3015, 0x04, 0x00),
		SpriteMap(0xE8, 0x3005, 0x04, 0x00),
		SpriteMap(0xE8, 0x3003, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x3058, 0x04, 0x00),
		SpriteMap(0x08, 0x3048, 0x04, 0x00),
		SpriteMap(0x08, 0x3046, 0xF4, 0x01),
		SpriteMap(0x00, 0x3038, 0x04, 0x00),
		SpriteMap(0xF8, 0x3028, 0x04, 0x00),
		SpriteMap(0xF8, 0x3026, 0xF4, 0x01),
		SpriteMap(0xF0, 0x3018, 0x04, 0x00),
		SpriteMap(0xE8, 0x3008, 0x04, 0x00),
		SpriteMap(0xE8, 0x3006, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x305B, 0x04, 0x00),
		SpriteMap(0x08, 0x304B, 0x04, 0x00),
		SpriteMap(0x08, 0x3049, 0xF4, 0x01),
		SpriteMap(0x00, 0x303B, 0x04, 0x00),
		SpriteMap(0xF8, 0x302B, 0x04, 0x00),
		SpriteMap(0xF8, 0x3029, 0xF4, 0x01),
		SpriteMap(0xF0, 0x301B, 0x04, 0x00),
		SpriteMap(0xE8, 0x300B, 0x04, 0x00),
		SpriteMap(0xE8, 0x3009, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x305E, 0x04, 0x00),
		SpriteMap(0x08, 0x304E, 0x04, 0x00),
		SpriteMap(0x08, 0x304C, 0xF4, 0x01),
		SpriteMap(0x00, 0x303E, 0x04, 0x00),
		SpriteMap(0xF8, 0x302E, 0x04, 0x00),
		SpriteMap(0xF8, 0x302C, 0xF4, 0x01),
		SpriteMap(0xF0, 0x301E, 0x04, 0x00),
		SpriteMap(0xE8, 0x300E, 0x04, 0x00),
		SpriteMap(0xE8, 0x300C, 0xF4, 0x81),
	],
	[
		SpriteMap(0x08, 0x3140, 0xFC, 0x01),
		SpriteMap(0xF8, 0x3120, 0xFC, 0x01),
		SpriteMap(0xE8, 0x3100, 0xFC, 0x01),
		SpriteMap(0x10, 0x305F, 0xF4, 0x00),
		SpriteMap(0x08, 0x304F, 0xF4, 0x00),
		SpriteMap(0x00, 0x303F, 0xF4, 0x00),
		SpriteMap(0xF8, 0x302F, 0xF4, 0x00),
		SpriteMap(0xF0, 0x301F, 0xF4, 0x00),
		SpriteMap(0xE8, 0x300F, 0xF4, 0x80),
	],
	[
		SpriteMap(0x10, 0x3154, 0x04, 0x00),
		SpriteMap(0x08, 0x3144, 0x04, 0x00),
		SpriteMap(0x08, 0x3142, 0xF4, 0x01),
		SpriteMap(0x00, 0x3134, 0x04, 0x00),
		SpriteMap(0xF8, 0x3124, 0x04, 0x00),
		SpriteMap(0xF8, 0x3122, 0xF4, 0x01),
		SpriteMap(0xF0, 0x3114, 0x04, 0x00),
		SpriteMap(0xE8, 0x3104, 0x04, 0x00),
		SpriteMap(0xE8, 0x3102, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x3157, 0x04, 0x00),
		SpriteMap(0x08, 0x3147, 0x04, 0x00),
		SpriteMap(0x08, 0x3145, 0xF4, 0x01),
		SpriteMap(0x00, 0x3137, 0x04, 0x00),
		SpriteMap(0xF8, 0x3127, 0x04, 0x00),
		SpriteMap(0xF8, 0x3125, 0xF4, 0x01),
		SpriteMap(0xF0, 0x3117, 0x04, 0x00),
		SpriteMap(0xE8, 0x3107, 0x04, 0x00),
		SpriteMap(0xE8, 0x3105, 0xF4, 0x81),
	],
	[
		SpriteMap(0x10, 0x315A, 0x04, 0x00),
		SpriteMap(0x08, 0x314A, 0x04, 0x00),
		SpriteMap(0x08, 0x3148, 0xF4, 0x01),
		SpriteMap(0x00, 0x313A, 0x04, 0x00),
		SpriteMap(0xF8, 0x312A, 0x04, 0x00),
		SpriteMap(0xF8, 0x3128, 0xF4, 0x01),
		SpriteMap(0xF0, 0x311A, 0x04, 0x00),
		SpriteMap(0xE8, 0x310A, 0x04, 0x00),
		SpriteMap(0xE8, 0x3108, 0xF4, 0x81),
	]
];

// $E14EC1
immutable ubyte[] APEArrangement = cast(immutable(ubyte)[])import("intro/logos/ape.arr.lzhal");

// $E14F2A
immutable ubyte[] APEGraphics = cast(immutable(ubyte)[])import("intro/logos/ape.gfx.lzhal");

// $E15130
immutable ubyte[] APEPalette = cast(immutable(ubyte)[])import("intro/logos/ape.pal.lzhal");

// $E15174
immutable ubyte[] HALKENArrangement = cast(immutable(ubyte)[])import("intro/logos/halken.arr.lzhal");

// $E151E8
immutable ubyte[] HALKENGraphics = cast(immutable(ubyte)[])import("intro/logos/halken.gfx.lzhal");

// $E153B8
immutable ubyte[] HALKENPalette = cast(immutable(ubyte)[])import("intro/logos/halken.pal.lzhal");

// $E15455
immutable ubyte[] NintendoArrangement = cast(immutable(ubyte)[])import("intro/logos/nintendo.arr.lzhal");

// $E1549E
immutable ubyte[] NintendoGraphics = cast(immutable(ubyte)[])import("intro/logos/nintendo.gfx.lzhal");

// $E1558F
immutable ubyte[] NintendoPalette = cast(immutable(ubyte)[])import("intro/logos/nintendo.pal.lzhal");

// $E1CFAF
immutable ubyte[] UnknownE1CFAF = cast(immutable(ubyte)[])import("E1CFAF.gfx.lzhal");

// $E1D4F4
immutable ubyte[] UnknownE1D4F4 = cast(immutable(ubyte)[])import("E1D4F4.pal.lzhal");

// $E1D5E8
immutable ubyte[] UnknownE1D5E8 = cast(immutable(ubyte)[])import("E1D5E8.arr.lzhal");

// $E1EA50
immutable ubyte[] TownMapLabelGfx = cast(immutable(ubyte)[])import("town_maps/label.gfx.lzhal");

// $E1F1C3
immutable ubyte[] TownMapIconPalette = cast(immutable(ubyte)[])import("town_maps/icon.pal");

// $E1F44C
immutable SpriteMap[][23] UnknownE1F44C = [
	[
		SpriteMap(0x00, 0x320C, 0x00, 0x01),
		SpriteMap(0x00, 0x320E, 0x10, 0x01),
		SpriteMap(0x10, 0x322C, 0x00, 0x00),
		SpriteMap(0x10, 0x322D, 0x08, 0x00),
		SpriteMap(0x10, 0x322E, 0x10, 0x00),
		SpriteMap(0x10, 0x322F, 0x18, 0x80),
	],
	[
		SpriteMap(0x00, 0x3290, 0x00, 0x01),
		SpriteMap(0x00, 0x3292, 0x10, 0x01),
		SpriteMap(0x10, 0x32B0, 0x00, 0x00),
		SpriteMap(0x10, 0x32B1, 0x08, 0x00),
		SpriteMap(0x10, 0x32B2, 0x10, 0x00),
		SpriteMap(0x10, 0x32B3, 0x18, 0x80),
	],
	[
		SpriteMap(0x00, 0x32BC, 0x00, 0x01),
		SpriteMap(0x00, 0x32BE, 0x10, 0x00),
		SpriteMap(0x08, 0x32CE, 0x10, 0x00),
		SpriteMap(0x10, 0x32DC, 0x00, 0x00),
		SpriteMap(0x10, 0x32DD, 0x08, 0x00),
		SpriteMap(0x10, 0x32DE, 0x10, 0x80),
	],
	[
		SpriteMap(0x00, 0x3294, 0x00, 0x01),
		SpriteMap(0x00, 0x3296, 0x10, 0x01),
		SpriteMap(0x10, 0x32B4, 0x00, 0x00),
		SpriteMap(0x10, 0x32B5, 0x08, 0x00),
		SpriteMap(0x10, 0x32B6, 0x10, 0x00),
		SpriteMap(0x10, 0x32B7, 0x18, 0x80),
	],
	[
		SpriteMap(0x00, 0x3236, 0x00, 0x01),
		SpriteMap(0x00, 0x3238, 0x10, 0x01),
		SpriteMap(0x00, 0x323A, 0x20, 0x00),
		SpriteMap(0x08, 0x324A, 0x20, 0x00),
		SpriteMap(0x10, 0x3256, 0x00, 0x00),
		SpriteMap(0x10, 0x3257, 0x08, 0x00),
		SpriteMap(0x10, 0x3258, 0x10, 0x00),
		SpriteMap(0x10, 0x3259, 0x18, 0x00),
		SpriteMap(0x10, 0x325A, 0x20, 0x80),
	],
	[
		SpriteMap(0x00, 0x32C0, 0x00, 0x01),
		SpriteMap(0x00, 0x32C2, 0x10, 0x00),
		SpriteMap(0x08, 0x32D2, 0x10, 0x00),
		SpriteMap(0x10, 0x32E0, 0x00, 0x00),
		SpriteMap(0x10, 0x32E1, 0x08, 0x00),
		SpriteMap(0x10, 0x32E2, 0x10, 0x80),
	],
	[
		SpriteMap(0x00, 0x323B, 0x00, 0x01),
		SpriteMap(0x00, 0x323D, 0x10, 0x01),
		SpriteMap(0x00, 0x323F, 0x20, 0x00),
		SpriteMap(0x08, 0x324F, 0x20, 0x00),
		SpriteMap(0x10, 0x325B, 0x00, 0x00),
		SpriteMap(0x10, 0x325C, 0x08, 0x00),
		SpriteMap(0x10, 0x325D, 0x10, 0x00),
		SpriteMap(0x10, 0x325E, 0x18, 0x00),
		SpriteMap(0x10, 0x325F, 0x20, 0x80),
	],
	[
		SpriteMap(0x00, 0x326F, 0x00, 0x80),
	],
	[
		SpriteMap(0x00, 0x3260, 0x00, 0x01),
		SpriteMap(0x00, 0x3262, 0x10, 0x01),
		SpriteMap(0x00, 0x3264, 0x20, 0x00),
		SpriteMap(0x08, 0x3274, 0x20, 0x00),
		SpriteMap(0x10, 0x3280, 0x00, 0x00),
		SpriteMap(0x10, 0x3281, 0x08, 0x00),
		SpriteMap(0x10, 0x3282, 0x10, 0x00),
		SpriteMap(0x10, 0x3283, 0x18, 0x00),
		SpriteMap(0x10, 0x3284, 0x20, 0x80),
	],
	[
		SpriteMap(0x00, 0x329C, 0x00, 0x01),
		SpriteMap(0x00, 0x329E, 0x10, 0x81),
	],
	[
		SpriteMap(0x00, 0x3265, 0x00, 0x01),
		SpriteMap(0x00, 0x3267, 0x10, 0x01),
		SpriteMap(0x00, 0x3269, 0x20, 0x00),
		SpriteMap(0x08, 0x3279, 0x20, 0x00),
		SpriteMap(0x10, 0x3285, 0x00, 0x00),
		SpriteMap(0x10, 0x3286, 0x08, 0x00),
		SpriteMap(0x10, 0x3287, 0x10, 0x00),
		SpriteMap(0x10, 0x3288, 0x18, 0x00),
		SpriteMap(0x10, 0x3289, 0x20, 0x80),
	],
	[
		SpriteMap(0x00, 0x3200, 0x00, 0x01),
		SpriteMap(0x00, 0x3202, 0x10, 0x01),
		SpriteMap(0x00, 0x3204, 0x20, 0x01),
		SpriteMap(0x10, 0x3220, 0x00, 0x00),
		SpriteMap(0x10, 0x3221, 0x08, 0x00),
		SpriteMap(0x10, 0x3222, 0x10, 0x00),
		SpriteMap(0x10, 0x3223, 0x18, 0x00),
		SpriteMap(0x10, 0x3224, 0x20, 0x00),
		SpriteMap(0x10, 0x3225, 0x28, 0x80),
	],
	[
		SpriteMap(0x00, 0x3206, 0x00, 0x01),
		SpriteMap(0x00, 0x3208, 0x10, 0x01),
		SpriteMap(0x00, 0x320A, 0x20, 0x01),
		SpriteMap(0x10, 0x3226, 0x00, 0x00),
		SpriteMap(0x10, 0x3227, 0x08, 0x00),
		SpriteMap(0x10, 0x3228, 0x10, 0x00),
		SpriteMap(0x10, 0x3229, 0x18, 0x00),
		SpriteMap(0x10, 0x322A, 0x20, 0x00),
		SpriteMap(0x10, 0x322B, 0x28, 0x80),
	],
	[
		SpriteMap(0x00, 0x3230, 0x00, 0x01),
		SpriteMap(0x00, 0x3232, 0x10, 0x01),
		SpriteMap(0x00, 0x3234, 0x20, 0x01),
		SpriteMap(0x10, 0x3250, 0x00, 0x00),
		SpriteMap(0x10, 0x3251, 0x08, 0x00),
		SpriteMap(0x10, 0x3252, 0x10, 0x00),
		SpriteMap(0x10, 0x3253, 0x18, 0x00),
		SpriteMap(0x10, 0x3254, 0x20, 0x00),
		SpriteMap(0x10, 0x3255, 0x28, 0x80),
	],
	[
		SpriteMap(0x00, 0x326A, 0x00, 0x01),
		SpriteMap(0x00, 0x326C, 0x10, 0x01),
		SpriteMap(0x00, 0x326E, 0x20, 0x00),
		SpriteMap(0x08, 0x327E, 0x20, 0x00),
		SpriteMap(0x10, 0x328A, 0x00, 0x00),
		SpriteMap(0x10, 0x328B, 0x08, 0x00),
		SpriteMap(0x10, 0x328C, 0x10, 0x00),
		SpriteMap(0x10, 0x328D, 0x18, 0x00),
		SpriteMap(0x10, 0x328E, 0x20, 0x80),
	],
	[
		SpriteMap(0x00, 0x3298, 0x00, 0x01),
		SpriteMap(0x00, 0x329A, 0x10, 0x01),
		SpriteMap(0x10, 0x32B8, 0x00, 0x00),
		SpriteMap(0x10, 0x32B9, 0x08, 0x00),
		SpriteMap(0x10, 0x32BA, 0x10, 0x00),
		SpriteMap(0x10, 0x32BB, 0x18, 0x80),
	],
	[
		SpriteMap(0x00, 0x32C3, 0x00, 0x81),
	],
	[
		SpriteMap(0x00, 0x32C5, 0x00, 0x81),
	],
	[
		SpriteMap(0x00, 0x32C7, 0x00, 0x81),
	],
	[
		SpriteMap(0x00, 0x32C9, 0x00, 0x81),
	],
	[
		SpriteMap(0x00, 0x3300, 0x00, 0x81),
	],
	[
		SpriteMap(0x00, 0x3302, 0x00, 0x81),
	]
];

// $E1F47A
immutable ubyte[23] UnknownE1F47A = [0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

// $E1F491
immutable TownMapIconPlacement[][6] TownMapIconPlacementTable = [
	[
		TownMapIconPlacement(0x55, 0x5B, 0x06, EventFlag.UNKNOWN_22E),
		TownMapIconPlacement(0x6A, 0x5E, 0x01, EventFlag.UNKNOWN_22F),
		TownMapIconPlacement(0x8C, 0x7B, 0x03, EventFlag.UNKNOWN_230),
		TownMapIconPlacement(0x1D, 0x9E, 0x05, EventFlag.UNKNOWN_231),
		TownMapIconPlacement(0x75, 0xA6, 0x02, EventFlag.UNKNOWN_232),
		TownMapIconPlacement(0x60, 0xBE, 0x09, EventFlag.UNKNOWN_233),
		TownMapIconPlacement(0xBB, 0x5E, 0x10, EventFlag.UNKNOWN_2A9 | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	],
	[
		TownMapIconPlacement(0x48, 0x2A, 0x03, EventFlag.UNKNOWN_234),
		TownMapIconPlacement(0x70, 0x2E, 0x07, EventFlag.UNKNOWN_235),
		TownMapIconPlacement(0x20, 0x30, 0x0A, EventFlag.UNKNOWN_236),
		TownMapIconPlacement(0xD0, 0x9A, 0x08, EventFlag.UNKNOWN_237),
		TownMapIconPlacement(0xB8, 0x09, 0x05, EventFlag.UNKNOWN_238),
		TownMapIconPlacement(0x78, 0xB8, 0x0B, EventFlag.UNKNOWN_239),
		TownMapIconPlacement(0x60, 0x70, 0x02, EventFlag.UNKNOWN_2A1),
		TownMapIconPlacement(0xD0, 0x3D, 0x10, EventFlag.UNKNOWN_2AA | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	],
	[
		TownMapIconPlacement(0x48, 0x6B, 0x06, EventFlag.UNKNOWN_23A),
		TownMapIconPlacement(0x70, 0x3B, 0x03, EventFlag.UNKNOWN_23B),
		TownMapIconPlacement(0x8C, 0x67, 0x02, EventFlag.UNKNOWN_23D),
		TownMapIconPlacement(0x7E, 0x6B, 0x05, EventFlag.UNKNOWN_23E),
		TownMapIconPlacement(0x18, 0x8E, 0x0C, EventFlag.UNKNOWN_282),
		TownMapIconPlacement(0xB0, 0x8E, 0x0D, EventFlag.UNKNOWN_281),
		TownMapIconPlacement(0x6C, 0x5D, 0x08, EventFlag.UNKNOWN_2A4),
		TownMapIconPlacement(0x73, 0x61, 0x08, EventFlag.UNKNOWN_2A5),
		TownMapIconPlacement(0xD7, 0x0A, 0x10, EventFlag.UNKNOWN_2AB | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	],
	[
		TownMapIconPlacement(0x74, 0x0A, 0x05, EventFlag.UNKNOWN_23F),
		TownMapIconPlacement(0xC2, 0x28, 0x07, EventFlag.UNKNOWN_240),
		TownMapIconPlacement(0xAC, 0x84, 0x02, EventFlag.UNKNOWN_241),
		TownMapIconPlacement(0x40, 0x7B, 0x03, EventFlag.UNKNOWN_242),
		TownMapIconPlacement(0x10, 0xC0, 0x0E, EventFlag.UNKNOWN_280),
		TownMapIconPlacement(0x3E, 0xC8, 0x08, EventFlag.UNKNOWN_2A6),
		TownMapIconPlacement(0x58, 0x77, 0x10, EventFlag.UNKNOWN_2AC | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	],
	[
		TownMapIconPlacement(0x80, 0x1B, 0x03, EventFlag.UNKNOWN_243),
		TownMapIconPlacement(0x88, 0x09, 0x05, EventFlag.UNKNOWN_244),
		TownMapIconPlacement(0xB0, 0x12, 0x06, EventFlag.UNKNOWN_245),
		TownMapIconPlacement(0xAC, 0x2E, 0x02, EventFlag.UNKNOWN_2A2),
		TownMapIconPlacement(0x8D, 0x5E, 0x10, EventFlag.UNKNOWN_2AE | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	],
	[
		TownMapIconPlacement(0x40, 0x04, 0x03, EventFlag.UNKNOWN_246),
		TownMapIconPlacement(0x71, 0x04, 0x04, EventFlag.UNKNOWN_247),
		TownMapIconPlacement(0xA5, 0x04, 0x06, EventFlag.UNKNOWN_248),
		TownMapIconPlacement(0x61, 0x6C, 0x05, EventFlag.UNKNOWN_249),
		TownMapIconPlacement(0xA0, 0x72, 0x06, EventFlag.UNKNOWN_24A),
		TownMapIconPlacement(0x48, 0x6C, 0x10, EventFlag.UNKNOWN_2AD | EVENT_FLAG_UNSET),
		TownMapIconPlacement(0xFF)
	]
];


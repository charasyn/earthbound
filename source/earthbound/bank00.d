/// low level stuff, actionscript, overworld code
module earthbound.bank00;

import earthbound.commondefs;
import earthbound.globals;
import earthbound.hardware;
import earthbound.actionscripts;
import earthbound.bank01;
import earthbound.bank02;
import earthbound.bank03;
import earthbound.bank04;
import earthbound.text;
import earthbound.bank0F;
import earthbound.bank10;
import earthbound.bank11;
import earthbound.bank15;
import earthbound.bank17;
import earthbound.bank1C;
import earthbound.bank1F;
import earthbound.bank20;
import earthbound.bank21;
import earthbound.bank2F;
import earthbound.testing;
import core.stdc.string;
import core.bitop;
import std.experimental.logger;

/// $C00000
short* clearEntityDrawSortingTable() {
	entityDrawSorting[] = 0;
	return entityDrawSorting.ptr;
}

/// $C00013
void overworldSetupVRAM() {
	setBGMODE(BGMode.mode1 | BG3Priority);
	setBG1VRAMLocation(BGTileMapSize.horizontal, 0x3800, 0);
	setBG2VRAMLocation(BGTileMapSize.horizontal, 0x5800, 0x2000);
	setBG3VRAMLocation(BGTileMapSize.normal, 0x7C00, 0x6000);
	setOAMSize(0x62);
}

/// $C0004B
void overworldInitialize() {
	overworldSetupVRAM();
	buffer[0] = 0;
	copyToVRAM(3, 0, 0, &buffer[0]);
	loadedMapPalette = -1;
	loadedMapTileCombo = -1;
}

/// $C00085
void loadTilesetAnim() {
	loadedAnimatedTileCount = 0;
	if (mapDataTilesetAnimationPointerTable[loadedMapTileset].count == 0) {
		return;
	}
	decomp(&mapDataAnimatedTilesets[loadedMapTileset][0], &animatedTilesetBuffer[0]);
	loadedAnimatedTileCount = mapDataTilesetAnimationPointerTable[loadedMapTileset].count;
	for (short i = 0; i < loadedAnimatedTileCount; i++) {
		overworldTilesetAnim[i].frameCount = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].frameCount;
		overworldTilesetAnim[i].framesUntilUpdate = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].frameDelay;
		overworldTilesetAnim[i].frameDelay = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].frameDelay;
		overworldTilesetAnim[i].copySize = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].copySize;
		overworldTilesetAnim[i].sourceOffset = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].sourceOffset;
		overworldTilesetAnim[i].sourceOffset2 = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].sourceOffset;
		overworldTilesetAnim[i].destinationAddress = mapDataTilesetAnimationPointerTable[loadedMapTileset].animations[i].destinationAddress;
		overworldTilesetAnim[i].frameCounter = 0;
	}
}

/// $C00172
void animateTileset() {
	for (short i = 0; loadedAnimatedTileCount > i; i++) {
		if (--overworldTilesetAnim[i].framesUntilUpdate != 0) {
			continue;
		}
		overworldTilesetAnim[i].framesUntilUpdate = overworldTilesetAnim[i].frameDelay;
		if (overworldTilesetAnim[i].frameCounter == overworldTilesetAnim[i].frameCount) {
			overworldTilesetAnim[i].frameCounter = 0;
			overworldTilesetAnim[i].sourceOffset2 = overworldTilesetAnim[i].sourceOffset;
		}
		copyToVRAM(0, overworldTilesetAnim[i].copySize, overworldTilesetAnim[i].destinationAddress, &animatedTilesetBuffer[overworldTilesetAnim[i].sourceOffset2]);
		overworldTilesetAnim[i].sourceOffset2 += overworldTilesetAnim[i].copySize;
		overworldTilesetAnim[i].frameCounter++;
	}
}

/// $C0023F
void loadPaletteAnim() {
	mapPaletteAnimationLoaded = 0;
	if (palettes[5][0] == 0) {
		return;
	}
	if (mapDataPaletteAnimationPointerTable[palettes[5][0] - 1].count == 0) {
		return;
	}
	decomp(&mapDataPaletteAnimationPointerTable[palettes[5][0] - 1].ptr[0], &animatedMapPaletteBuffer[0]);
	for (short i = 0; i < overworldPaletteAnim.delays.length; i++) {
		overworldPaletteAnim.delays[i] = 0;
	}
	for (short i = 0; i < mapDataPaletteAnimationPointerTable[palettes[5][0] - 1].count; i++) {
		overworldPaletteAnim.delays[i] = mapDataPaletteAnimationPointerTable[palettes[5][0] - 1].entries[i];
	}
	overworldPaletteAnim.timer = overworldPaletteAnim.delays[0];
	mapPaletteAnimationLoaded = 1;
	overworldPaletteAnim.index = 1;
}

/// $C0030F
void animatePalette() {
	if (--overworldPaletteAnim.timer != 0) {
		return;
	}
	if (overworldPaletteAnim.delays[overworldPaletteAnim.index] == 0) {
		overworldPaletteAnim.index = 0;
	}
	overworldPaletteAnim.timer = overworldPaletteAnim.delays[overworldPaletteAnim.index];
	copyMapPaletteFrame(overworldPaletteAnim.index);
	overworldPaletteAnim.index++;
}

/// $C0035B
ushort unknownC0035B(ushort a, ushort x, ushort y) {
	return tileArrangementBuffer[a * 16 + x + y * 4];
}

/// $C00391
void getColorAverage(ushort* palette) {
	ushort red = 0;
	ushort blue = 0;
	ushort green = 0;
	ushort count = 0;
	ushort* colour = palette - 1;
	for (short i = 0; i < 96; i++) {
		ushort value = *++colour;
		if ((value & 0x7FFF) == 0) {
			continue;
		}
		red += value & BGR555Mask.Red;
		green += (value & BGR555Mask.Green) >> 5;
		blue += (value & BGR555Mask.Blue) >> 10;
		count++;
	}
	colourAverageRed = cast(ushort)((red * 8) / count);
	colourAverageGreen = cast(ushort)((green * 8) / count);
	colourAverageBlue = cast(ushort)((blue * 8) / count);
}

/// $C00434
ushort adjustSingleColour(ushort original, ushort modified) {
	if (original == modified) {
		return modified;
	} else if (original > modified) {
		if (original - modified > 6) {
			return cast(ushort)(original - 6);
		} else {
			return modified;
		}
	} else if (modified - original > 6) {
		return cast(ushort)(original + 6);
	}
	return modified;
}

/// $C00480
void adjustSpritePalettesByAverage() {
	getColorAverage(&palettes[2][0]);
	ushort redModifier = cast(ushort)((colourAverageRed << 8) / savedColourAverageRed);
	ushort greenModifier = cast(ushort)((colourAverageGreen << 8) / savedColourAverageGreen);
	ushort blueModifier = cast(ushort)((colourAverageBlue << 8) / savedColourAverageBlue);
	ushort combinedModifier = (redModifier + greenModifier + blueModifier) / 3;
	if ((redModifier <= 0x100) && (greenModifier <= 0x100) && (blueModifier <= 0x100)) {
		for (short i = 0x80; i < 0x100; i++) {
			ushort modifiedRed, newRed, modifiedGreen, newGreen, modifiedBlue, newBlue;
			modifiedRed = newRed = palettes[i / 16][i % 16] & BGR555Mask.Red;
			modifiedGreen = newGreen = (palettes[i / 16][i % 16] & BGR555Mask.Green) >> 5;
			modifiedBlue = newBlue = (palettes[i / 16][i % 16] & BGR555Mask.Blue) >> 10;
			// shades of grey use combined multiplier
			if ((modifiedRed == modifiedGreen) && (modifiedGreen == modifiedBlue) && (modifiedBlue == modifiedRed)) {
				modifiedRed *= combinedModifier;
				modifiedGreen *= combinedModifier;
				modifiedBlue *= combinedModifier;
			} else {
				modifiedRed *= redModifier;
				modifiedGreen *= greenModifier;
				modifiedBlue *= blueModifier;
			}
			newRed = adjustSingleColour(newRed, (modifiedRed >> 8) & 0x1F);
			modifiedGreen = adjustSingleColour(newGreen, (modifiedGreen >> 8) & 0x1F);
			newBlue = adjustSingleColour(newBlue, (modifiedBlue >> 8) & 0x1F);
			palettes[i / 16][i % 16] = cast(ushort)((newBlue << 10) | (modifiedGreen << 5) | newRed);
		}
	}
}

/// $C005E7
void prepareAverageForSpritePalettes() {
	memcpy(&palettes[2][0], &mapPalettePointerTable[1][0], 0xC0);
	getColorAverage(&palettes[2][0]);
	savedColourAverageRed = colourAverageRed;
	savedColourAverageGreen = colourAverageGreen;
	savedColourAverageBlue = colourAverageBlue;
}

/// $C0062A
void loadCollisionData(short tileset) {
	const(ubyte[4][4]*)* src = &mapDataTileCollisionPointerTable[tileset][0];
	const(ubyte[4][4])** dest = &tileCollisionBuffer[0];
	for (short i = 0; i < 0x3C0; i++) {
		*(dest++) = *(src++);
	}
}

/// $C0067E
void function14(short index1, short index2) {
	ushort* x0A = &tileArrangementBuffer[index1 * 16];
	ushort* x06 = &tileArrangementBuffer[index2 * 16];
	for (short i = 0; i < 16; i++) {
		*(x0A++) = *(x06++);
	}
	tileCollisionBuffer[index1] = tileCollisionBuffer[index2];
}

/// $C006F2
void unknownC006F2(short arg1) {
	const(MapBlockEvent)* x06 = &eventControlPointerTable[arg1][0];
	while (true) {
		if (x06.eventFlag == 0) {
			break;
		}
		short x0E = getEventFlag(x06.eventFlag & 0x7FFF);
		short y = x06.count;
		if (x0E == (x06.eventFlag >= eventFlagUnset) ? 1 : 0) {
			const(MapBlockPair)* x06_2 = &x06.blocks[0];
			for (short i = y; i != 0; i--) {
				function14(x06_2.block1, x06_2.block2);
				x06_2++;
			}
			// Normally, x06 and x06_2 are the same variable in the SNES ver.
			// meaning that x06 would be advanced by the above code.
			// Since that's not the case here, we advance it manually.
			x06++;
		} else {
			x06++;
		}
	}
}

/// $C00778
void loadSpecialSpritePalette() {
	if (palettes[4][0] == 0) {
		return;
	}
	ushort* x10 = &palettes[palettes[4][0]][0];
	for (short i = 0; i < 0x10; i++) {
		palettes[12][i] = *(x10++);
	}
}

/// $C007B6
void loadMapPalette(short arg1, short arg2) {
	const(ubyte)* x16 = &mapPalettePointerTable[arg1][arg2 * 192];
	if (photographMapLoadingMode == 0) {
		while (true) {
			memcpy(&palettes[2][0], x16, 0xC0);
			if (palettes[2][0] == 0) {
				break;
			}
			if (getEventFlag(palettes[2][0] & 0x7FFF) != (palettes[2][0] > eventFlagUnset) ? 1 : 0) {
				break;
			}
			//the original code used palettes[3][0] as a raw near pointer, which isn't possible on most platforms
			x16 = &paletteOffsetToPointer(palettes[3][0])[0];
		}
	} else {
		decomp(&compressedPaletteUnknown[0], &buffer[0]);
		memcpy(&palettes[2][0], &buffer[photographerConfigTable[currentPhotoDisplay].creditsMapPalettesOffset], 0xC0);
	}
}

/// $C008C3
void loadMapAtSector(short x, short y) {
	tracef("Loading map sector %d, %d", x, y);
	if ((currentTeleportDestinationX | currentTeleportDestinationY) != 0) {
		x = currentTeleportDestinationX / 32;
		y = currentTeleportDestinationY / 16;
	}
	ubyte x1A = globalMapTilesetPaletteData[y][x];
	ubyte palette = x1A & 7;
	ubyte tileCombo = x1A >> 3;
	tracef("Loading map tileset %d, palette %d", tileCombo, palette);
	decomp(&mapDataTileArrangementPtrTable[tilesetTable[tileCombo]][0], &tileArrangementBuffer[0]);
	loadCollisionData(tilesetTable[tileCombo]);
	unknownC006F2(tilesetTable[tileCombo]);
	prepareAverageForSpritePalettes();
	memcpy(&palettes[8][0], &spriteGroupPalettes[0], 0x100);
	if (tileCombo != loadedMapTileCombo) {
		loadedMapTileset = tilesetTable[tileCombo];
		decomp(&mapDataTilesetPtrTable[tilesetTable[tileCombo]][0], &buffer[0]);
		while (fadeParameters.step != 0) { waitForInterrupt(); }
		if (photographMapLoadingMode == 0) {
			copyToVRAM2(0, 0x7000, 0, &buffer[0]);
		} else {
			copyToVRAM2(0, 0x4000, 0, &buffer[0]);
		}
	}
	while (fadeParameters.step != 0) { waitForInterrupt(); }
	loadMapPalette(tileCombo, palette);
	adjustSpritePalettesByAverage();
	loadSpecialSpritePalette();
	if (photographMapLoadingMode == 0) {
		loadOverlaySprites();
		loadTilesetAnim();
		loadPaletteAnim();
	}
	if (photographMapLoadingMode == 0) {
		if (debugging != 0) {
			unknownEFD9F3();
		} else {
			loadTextPalette();
		}
		preparePaletteUpload(PaletteUpload.none);
	}
	memcpy(&mapPaletteBackup[0], &palettes[2][0], 0x1C0);
	if (wipePalettesOnMapLoad != 0) {
		unknownC496F9();
		memset(&palettes[0][0], 0xFF, 0x200);
		wipePalettesOnMapLoad = 0;
	}
	if (photographMapLoadingMode != 0) {
		unknownC496F9();
		memset(&palettes[1][0], 0, 0x1E0);
	}
	preparePaletteUpload(PaletteUpload.full);
	loadedMapTileCombo = tileCombo;
	loadedMapPalette = palette;
}

/// $C00AA1
short loadSectorAttributes(ushort arg1, ushort arg2) {
	currentSectorAttributes = mapDataPerSectorAttributesTable[(arg2 &0xFF80) >> 7][arg1 >> 8];
	return currentSectorAttributes;
}

/** Loads a row of map block data, starting from (x, y) to (x + 16, y), representing a 512x32 pixel area
* Params:
*	x = X coordinate in tiles
*	y = Y coordinate in tiles
* Mutates:
* 	loadedRowsX = Block X coordinate of the row being loaded
* 	loadedRowsY = Block Y coordinate of the row being loaded
*	loadedMapBlocks = The IDs of the map blocks in the requested area
* See_Also: loadMapBlock
* Original_Address: $(DOLLAR)C00AC5
*/
void loadMapRow(short x, short y) {
	y /= 4;
	short x16 = x / 4;
	x = x16 & 0xF;
	loadedRowsX[x] = cast(byte)x16;
	loadedRowsY[y & 0xF] = cast(byte)y;
	ubyte x12;
	version(noUndefinedBehaviour) {
		// Use a boolean to track that x12 hasn't been set yet
		bool x12Set = false;
	} else {
		x12 = globalMapTilesetPaletteData[y / 4][x16 / 8] / 8;
	}
	ushort* x14 = cast(ushort*)&loadedMapBlocks[y & 0xF];
	if (cast(ushort)y < 0x140) {
		short x10 = x;
		for (short i = 0; i < 16; i++) {
			version(noUndefinedBehaviour) {
				// Set x12 only if coordinates are in range, and only if it needs
				// to be set (it was never set, or beginning new sector)
				if ((cast(ushort)x16 < 0x100) && (!x12Set || ((x16 & 7) == 0))) {
					x12 = globalMapTilesetPaletteData[y / 4][x16 / 8] / 8;
					x12Set = true;
				}
				if ((cast(ushort)x16 < 0x100) && x12Set && (loadedMapTileCombo == x12)) {
					x14[x10] = loadMapBlock(x16, y);
				} else {
					x14[x10] = 0;
				}
			} else {
				if ((x16 & 8) == 0) {
					x12 = globalMapTilesetPaletteData[y / 4][x16 / 8] / 8;
				}
				if ((cast(ushort)x16 < 0x100) && (loadedMapTileCombo == x12)) {
					x14[x10] = loadMapBlock(x16, y);
				} else {
					x14[x10] = 0;
				}
			}
			x10 = (x10 + 1) & 0xF;
			x16++;
		}
	} else {
		for (short i = 0; i < 16; i++) {
			x14[i] = 0;
		}
	}
}

/** Loads a column of map block data, starting from (x, y) to (x, y + 16), representing a 32x512 pixel area
* Params:
*	x = X coordinate in tiles
*	y = Y coordinate in tiles
* Mutates:
* 	loadedColumnsX = Block X coordinate of the column being loaded
* 	loadedColumnsY = Block Y coordinate of the column being loaded
*	loadedMapBlocks = The IDs of the map blocks in the requested area
* See_Also: loadMapBlock
* Original_Address: $(DOLLAR)C00BDC
*/
void loadMapColumn(short x, short y) {
	x /= 4;
	y /= 4;
	short x18 = x & 0xF;
	loadedColumnsX[x18] = cast(byte)x;
	short x16 = y & 0xF;
	loadedColumnsY[x16] = cast(byte)y;
	ubyte x14;
	version(noUndefinedBehaviour) {
		// Use a boolean to track that x14 hasn't been set yet
		bool x14Set = false;
	} else {
		x14 = globalMapTilesetPaletteData[y / 4][x / 8] / 8;
	}
	ushort* x12 = &loadedMapBlocks[0][x18];
	if (cast(ushort)x < 0x100) {
		short x10 = cast(short)(x16 * 16);
		for (short i = 0; i < 16; i++) {
			version(noUndefinedBehaviour) {
				// Set x14 only if coordinates are in range, and only if it needs
				// to be set (it was never set, or beginning new sector)
				if ((cast(ushort)y < 0x140) && (!x14Set || ((y & 3) == 0))) {
					x14 = globalMapTilesetPaletteData[y / 4][x / 8] / 8;
					x14Set = true;
				}
				if ((cast(ushort)y < 0x140) && x14Set && (loadedMapTileCombo == x14)) {
					x12[x10] = loadMapBlock(x, y);
				} else {
					x12[x10] = 0;
				}
			} else {
				if ((y & 3) == 0) {
					x14 = globalMapTilesetPaletteData[y / 4][x / 8] / 8;
				}
				if ((cast(ushort)y < 0x140) && (loadedMapTileCombo == x14)) {
					x12[x10] = loadMapBlock(x, y);
				} else {
					x12[x10] = 0;
				}
			}
			x10 = (x10 + 16) & 0xFF;
			y++;
		}
	} else {
		for (short i = 0; i < 16; i++) {
			x12[i * 16] = 0;
		}
	}
}

/// $C00CF3
void loadCollisionRow(short x, short y) {
	ushort* x02 = &loadedMapBlocks[(y / 4) & 0xF][0];
	ubyte* x10 = &loadedCollisionTiles[y & 0x3F][0];
	for (short i = 0; i < 16; i++) {
		const(ubyte[4][4])* x12 = tileCollisionBuffer[*x02];
		x02++;
		x10[0] = (*x12)[y & 3][0];
		x10[1] = (*x12)[y & 3][1];
		x10[2] = (*x12)[y & 3][2];
		x10[3] = (*x12)[y & 3][3];
		x10 += 4;
	}
}

/// $C00D7E
void loadCollisionColumn(short x, short y) {
	ushort* x02 = &loadedMapBlocks[0][(x >> 2) & 0xF];
	ubyte* x10 = &loadedCollisionTiles[0][x & 0x3F];
	for (short i = 0; i < 16; i++) {
		const(ubyte[4][4])* x12 = tileCollisionBuffer[*x02];
		x02 += 16;
		x10[0] = (*x12)[0][x & 3];
		x10[64] = (*x12)[1][x & 3];
		x10[128] = (*x12)[2][x & 3];
		x10[192] = (*x12)[3][x & 3];
		x10 += 256;
	}
}

/// $C00E16
void loadMapRowVRAM(short x, short y) {
	if (debugging != 0) {
		renderAttributeRow(x, y);
	}
	ushort* x1E = cast(ushort*)sbrk(0x100);
	ushort* x1C = &x1E[0x40];
	x--;
	ushort x18 = cast(ushort)((loadedMapBlocks[((y >> 2) & 0xF)][(x >> 2) & 0xF] * 16) + ((y & 3) * 4) + (x & 3));
	short x16 = x & 0x3F;
	for (short i = 0; i < 34; i++) {
		if ((x & 3) == 0) {
			x18 = cast(ushort)((loadedMapBlocks[(y >> 2) & 0xF][(x >> 2) & 0xF] * 16) + ((y & 3) * 4));
		}
		ushort x12 = tileArrangementBuffer[x18];
		x1E[x16] = x12;
		x18++;
		if ((x12 & 0x3FF) < 0x180) {
			x12 |= 0x2000;
		} else {
			x12 = 0;
		}
		x1C[x16] = x12;
		x16 = (x16 + 1) & 0x3F;
		x++;
	}
	copyToVRAM(0, 0x40, 0x3800 + ((y & 0x1F) * 32), cast(ubyte*)&x1E[0]);
	copyToVRAM(0, 0x40, 0x3C00 + ((y & 0x1F) * 32), cast(ubyte*)&x1E[0x20]);
	if (photographMapLoadingMode == 0) {
		copyToVRAM(0, 0x40, 0x5800 + ((y & 0x1F) * 32), cast(ubyte*)&x1C[0]);
		copyToVRAM(0, 0x40, 0x5C00 + ((y & 0x1F) * 32), cast(ubyte*)&x1C[0x20]);
	}
}

/// $C00FCB
void loadMapColumnVRAM(short x, short y) {
	if (debugging != 0) {
		renderAttributeColumn(x, y);
	}
	ushort* x1E = cast(ushort*)sbrk(0x80);
	ushort* x1C = &x1E[0x20];
	y--;
	ushort x18 = cast(ushort)((loadedMapBlocks[(y >> 2) & 0xF][(x >> 2) & 0xF] * 16) + ((y & 3) * 4) + (x & 3));
	short x16 = y & 0x1F;
	for (short i = 0; i < 30; i++) {
		if ((y & 3) == 0) {
			x18 = cast(ushort)((loadedMapBlocks[(y >> 2) & 0xF][(x >> 2) & 0xF] * 16) + (x & 3));
		}
		ushort x12 = tileArrangementBuffer[x18];
		x1E[x16] = x12;
		if ((x12 & 0x3FF) < 0x180) {
			x12 |= 0x2000;
		} else {
			x12 = 0;
		}
		x1C[x16] = x12;
		x18 += 4;
		x16 = (x16 + 1) & 0x1F;
		y++;
	}
	if ((x & 0x3F) <= 0x1F) {
		copyToVRAM(0x1B, 0x40, 0x3800 + (x & 0x3F), cast(ubyte*)x1E);
		copyToVRAM(0x1B, 0x40, 0x5800 + (x & 0x3F), cast(ubyte*)x1C);
	} else {
		copyToVRAM(0x1B, 0x40, 0x3C00 + (x & 0x1F), cast(ubyte*)x1E);
		copyToVRAM(0x1B, 0x40, 0x5C00 + (x & 0x1F), cast(ubyte*)x1C);
	}
}

/// $C01181
void unknownC01181(short arg1, short arg2) {
	ubyte* x12 = cast(ubyte*)sbrk(0x40);
	memset(x12, 0, 0x40);
	copyToVRAM(0, 0x40, cast(ushort)(((arg2 & 0x1F) * 32) + 0x3800), x12);
	copyToVRAM(0, 0x40, cast(ushort)(((arg2 & 0x1F) * 32) + 0x3C00), x12);
	copyToVRAM(0, 0x40, cast(ushort)(((arg2 & 0x1F) * 32) + 0x5800), x12);
	copyToVRAM(0, 0x40, cast(ushort)(((arg2 & 0x1F) * 32) + 0x5C00), x12);
}

/// $C0122A
void unknownC0122A(short arg1, short arg2) {
	ubyte* x12 = cast(ubyte*)sbrk(0x40);
	memset(x12, 0, 0x40);
	arg1 &= 0x3F;
	if (arg1 <= 0x1F) {
		copyToVRAM(0x1B, 0x40, cast(ushort)(arg1 + 0x3800), x12);
		copyToVRAM(0x1B, 0x40, cast(ushort)(arg1 + 0x5800), x12);
	} else {
		copyToVRAM(0x1B, 0x40, cast(ushort)((arg1 & 0x1F) + 0x3C00), x12);
		copyToVRAM(0x1B, 0x40, cast(ushort)((arg1 & 0x1F) + 0x5C00), x12);
	}
}

/// $C012ED
void reloadMapAtPosition(short x, short y) {
	screenXPixels = x;
	screenXPixelsCopy = x;
	screenYPixels = y;
	screenYPixelsCopy = y;
	short x14 = x / 8;
	short x02 = y / 8;
	loadedMapPalette = -1;
	loadedMapTileCombo = -1;
	loadMapAtSector(x14 / 32, x02 / 16);
	for (short i = 0; i < 16; i++) {
		loadedColumnsY[i] = -1;
		loadedColumnsX[i] = -1;
		loadedRowsY[i] = -1;
		loadedRowsX[i] = -1;
	}
	for (short i = 0; i < 60; i++) {
		loadMapRow(cast(short)(x14 - 32), cast(short)(x02 - 32 + i));
	}
	for (short i = 0; i < 60; i++) {
		loadCollisionRow(cast(short)(x14 - 32), cast(short)(x02 - 32 + i));
	}
	for (short i = -1; i != 31; i++) {
		loadMapRowVRAM(cast(short)(x14 - 16), cast(short)(x02 - 14 + i));
	}
	while (fadeParameters.step != 0) { waitForInterrupt(); }
	bg2XPosition = cast(short)(screenXPixels - 0x80);
	bg1XPosition = cast(short)(screenXPixels - 0x80);
	bg2YPosition = cast(short)(screenYPixels - 0x70);
	bg1YPosition = cast(short)(screenYPixels - 0x70);
	screenLeftX = cast(short)(x14 - 16);
	screenTopY = cast(short)(x02 - 14);
}

/// $C013F6
void loadMapAtPosition(short x, short y) {
	tracef("Loading map at %s,%s", x, y);
	unknownC02194();
	screenXPixels = x;
	screenXPixelsCopy = x;
	screenYPixels = y;
	screenYPixelsCopy = y;
	short x02 = x / 8;
	short x12 = y / 8;
	loadMapAtSector(x02 / 32, x12 / 16);
	if (photographMapLoadingMode == 0) {
		overworldSetupVRAM();
	}
	for (short i = 0; i < 16; i++) {
		loadedColumnsY[i] = -1;
		loadedColumnsX[i] = -1;
		loadedRowsY[i] = -1;
		loadedRowsX[i] = -1;
	}
	for (short i = 0; i < 60; i++) {
		loadMapRow(cast(short)(x02 - 32), cast(short)(x12 - 32 + i));
	}
	for (short i = 0; i < 60; i++) {
		loadCollisionRow(cast(short)(x02 - 32), cast(short)(x12 - 32 + i));
	}
	while (fadeParameters.step != 0) { waitForInterrupt(); }
	if (photographMapLoadingMode == 0) {
		mirrorTM = TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1;
	}
	if (npcSpawnsEnabled != SpawnControl.allDisabled) {
		npcSpawnsEnabled = SpawnControl.offscreenOnly;
	}
	bg2XPosition = cast(short)(screenXPixels - 0x80);
	bg1XPosition = cast(short)(screenXPixels - 0x80);
	bg2YPosition = cast(short)(screenYPixels - 0x70);
	bg1YPosition = cast(short)(screenYPixels - 0x70);
	for (short i = -1; i != 31; i++) {
		loadMapRowVRAM(cast(short)(x02 - 16), cast(short)(x12 - 14 + i));
		spawnNPCsRow(cast(short)(x02 - 16), cast(short)(x12 - 14 + i));
	}
	for (short i = -8; i != 40; i++) {
		spawnEnemiesRow(cast(short)(x02 - 24), cast(short)(x12 - 14 + i));
	}
	if (npcSpawnsEnabled != SpawnControl.allDisabled) {
		npcSpawnsEnabled = SpawnControl.allEnabled;
	}
	screenLeftX = cast(short)(x02 - 16);
	screenTopY = cast(short)(x12 - 14);
}

/// $C01558
void refreshMapAtPosition(short x, short y) {
	bg2XPosition = x;
	bg1XPosition = x;
	bg2YPosition = y;
	bg1YPosition = y;
	short x04 = x / 8;
	short x02 = y / 8;
	while ((screenLeftX - x04) != 0) {
		if (((screenLeftX - x04) < 0) != 0) {
			screenLeftX++;
			loadMapColumn(cast(short)(screenLeftX + 41), cast(short)(x02 - 16));
			loadCollisionColumn(cast(short)(screenLeftX + 41), cast(short)(x02 - 16));
			loadMapColumnVRAM(cast(short)(screenLeftX + 32), x02);
			spawnNPCsColumn(cast(short)(screenLeftX + 34), cast(short)(x02 - 1));
			spawnEnemiesColumn(cast(short)(screenLeftX + 40), cast(short)(x02 - 8));
		} else {
			screenLeftX--;
			loadMapColumn(cast(short)(screenLeftX - 16), cast(short)(x02 - 16));
			loadCollisionColumn(cast(short)(screenLeftX - 16), cast(short)(x02 - 16));
			loadMapColumnVRAM(cast(short)(screenLeftX - 1), x02);
			spawnNPCsColumn(cast(short)(screenLeftX - 3), cast(short)(x02 - 1));
			spawnEnemiesColumn(cast(short)(screenLeftX - 8), cast(short)(x02 - 8));
		}
	}
	while ((screenTopY - x02) != 0) {
		if (((screenTopY - x02) < 0) != 0) {
			screenTopY++;
			loadMapRow(cast(short)(x04 - 16), cast(short)(screenTopY + 41));
			loadCollisionRow(cast(short)(x04 - 16), cast(short)(screenTopY + 41));
			loadMapRowVRAM(x04, cast(short)(screenTopY + 28));
			spawnNPCsRow(x04, cast(short)(screenTopY + 29));
			spawnEnemiesRow(cast(short)(x04 - 8), cast(short)(screenTopY + 36));
		} else {
			screenTopY--;
			loadMapRow(cast(short)(x04 - 16), cast(short)(screenTopY - 16));
			loadCollisionRow(cast(short)(x04 - 16), cast(short)(screenTopY - 16));
			loadMapRowVRAM(x04, cast(short)(screenTopY - 1));
			spawnNPCsRow(x04, cast(short)(screenTopY - 1));
			spawnEnemiesRow(cast(short)(x04 - 8), cast(short)(screenTopY - 8));
		}
	}
	bg12PositionXCopy = x;
	bg12PositionYCopy = y;
}

/// $C01731
void unknownC01731(short x, short y) {
	bg2XPosition = x;
	bg1XPosition = x;
	bg2YPosition = y;
	bg1YPosition = y;
	short x0E = x / 8;
	short x02 = y / 8;
	while (screenLeftX - x0E != 0) {
		if (screenLeftX - x0E < 0) {
			screenLeftX++;
			unknownC0122A(cast(short)(screenLeftX + 0x20), x02);
		} else {
			screenLeftX--;
			unknownC0122A(cast(short)(screenLeftX - 1), x02);
		}
	}
	while (screenTopY - x02 != 0) {
		if (screenTopY - x02 < 0) {
			screenTopY++;
			unknownC01181(x0E, cast(short)(screenTopY + 0x1C));
		} else {
			screenTopY--;
			unknownC01181(x0E, cast(short)(screenTopY - 1));
		}
	}
	bg12PositionXCopy = x;
	bg12PositionYCopy = y;
}

/// $C018F3
void reloadMap() {
	loadedMapPalette = -1;
	loadedMapTileCombo = -1;
	screenXPixels &= 0xFFF8;
	screenYPixels &= 0xFFF8;
	prepareForImmediateDMA();
	currentMapMusicTrack = -1;
	loadSectorMusic(gameState.leaderX.integer, gameState.leaderY.integer);
	setBGMODE(BGMode.mode1 | BG3Priority);
	setBG1VRAMLocation(BGTileMapSize.horizontal, 0x3800, 0);
	setBG2VRAMLocation(BGTileMapSize.horizontal, 0x5800, 0x2000);
	setBG3VRAMLocation(BGTileMapSize.normal, 0x7C00, 0x6000);
	setOAMSize(0x62);
	reloadMapAtPosition(gameState.leaderX.integer, gameState.leaderY.integer);
	if (gameState.walkingStyle == WalkingStyle.bicycle) {
		changeMusic(Music.bicycle);
	} else {
		changeMapMusic();
	}
	mirrorTM = TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1;
	if (debugging != 0) {
		unknownEFD9F3();
	}
	setForceBlank();
}

/// $C019B2
void initializeMap(short x, short y, short direction) {
	loadSectorMusic(x, y);
	loadMapAtPosition(x, y);
	unknownC03FA9(x, y, direction);
	changeMapMusic();
}

/// $C019E2
void unknownC019E2() {
	for (short i = 0; i < 16; i++) {
		loadedColumnsY[i] = -1;
		loadedColumnsX[i] = -1;
		loadedRowsY[i] = -1;
		loadedRowsX[i] = -1;
	}
	short x04 = (bg1XPosition - 0x80) /8;
	short x10 = (bg1YPosition - 0x80) /8;
	for (short i = 0; i < 60; i++) {
		loadMapRow(x04, cast(short)(x10 + i));
	}
	for (short i = 0; i < 60; i++) {
		loadCollisionRow(x04, cast(short)(x10 + i));
	}
}

/// $C01A63
void unknownC01A63(short x, short y) {
	loadMapRowVRAM(x, y);
}

/// $C01A69
void initializeMiscObjectData() {
	for (short i = 0; i < 0x1E; i++) {
		entityMovementSpeed[i] = 0;
		entityCollidedObjects[i] = 0xFFFF;
		entityNPCIDs[i] = 0xFFFF;
	}
}

/// $C01A86
void clearSpriteTable() {
	ubyte* tmpPtr = cast(ubyte*)&overworldSpriteMaps[0];
	for (short i = 0; i < overworldSpriteMaps.sizeof; i++) {
		tmpPtr[i] = 0xFF;
	}
}

/// $C01A9D
short findFreeSpriteMap(ushort arg1) {
	arg1 /= 5; //convert offset to index
	short x10 = 0;
	unread7E4A6A = cast(short)(arg1 * 5);
	Unknown1:
	while (x10 < overworldSpriteMaps.length) {
		if (overworldSpriteMaps[x10].specialFlags == 0xFF) {
			goto Found;
		}
		x10++;
	}
	return -255;
	Found:
	if ((x10 + arg1) < overworldSpriteMaps.length) {
		for (short i = x10; i < x10 + arg1; i++) {
			if (overworldSpriteMaps[i].specialFlags == 0xFF) {
				continue;
			}
			x10 = cast(short)(i + 1);
			goto Unknown1;
		}
		return x10;
	}
	return -254;
}

/// $C01B15
void freeSpritemap(const(SpriteMap)* arg1) {
	if (arg1 < &overworldSpriteMaps[0]) {
		return;
	}
	//??????????
	if (cast(const(ubyte)*)arg1 > cast(ubyte*)&overworldSpriteMaps.ptr[179] + 1) {
		return;
	}
	short x10 = cast(short)(arg1 - &overworldSpriteMaps[0]);
	short i = 0;
	while(i < 2) {
		ubyte y = overworldSpriteMaps[x10].specialFlags;
		overworldSpriteMaps[x10].yOffset = 0xFF;
		overworldSpriteMaps[x10].firstTile = 0xFF;
		overworldSpriteMaps[x10].flags = 0xFF;
		overworldSpriteMaps[x10].xOffset = 0xFF;
		overworldSpriteMaps[x10].specialFlags = 0xFF;
		x10 += 1;
		if ((y & 0x80) != 0) { //if this wasn't a terminating entry, clear the next one too
			i++;
		}
	}
}

/// $C01B96
// This function will find numTiles of sequential free space in the sprite VRAM allocation table,
// and fill that free space with (needle | 0x80) so that it can be found and overwritten later by
// spriteVramTableOverwrite.
short spriteVramTableAllocateSpace(short numTiles, short needle) {
	short x;
	outer: for (short i = 0; i <= 0x58 - numTiles; i = cast(short)(x + 1)) {
		for (short j = 0; j < numTiles; j++) {
			x = cast(short)(i + j);
			if (spriteVramTable[i + j] != 0) {
				continue outer;
			}
		}
		for (short j = 0; j < numTiles; j++) {
			x = cast(short)(i + j);
			spriteVramTable[i + j] = cast(ubyte)needle | 0x80;
		}
		return i;
	}
	return -253;
}

/// $C01C11
void spriteVramTableOverwrite(short needle, ubyte tableValue) {
	for (short i = 0; i < 0x58; i++) {
		if (((spriteVramTable[i] & 0xFF) == ((needle & 0xFF) | 0x80)) || (needle == short.min)) {
			spriteVramTable[i] = tableValue;
		}
	}
	debug(spriteVRAM) {
		int numAvailable = 0;
		for (int i = 0; i < spriteVramTable.length; i++) {
			if (spriteVramTable[i] == 0) {
				numAvailable++;
			}
		}
		tracef("Number of sprite VRAM slots available: %d", numAvailable);
	}
}

/// $C01C52
short reserveOverworldSpriteVRAM(short tileWidth, short tileHeight, short needle) {
	short spriteNumTiles = cast(short)((((tileWidth + 1) & 0xFFFE) * ((tileHeight + 1) & 0xFFFE)) / 4);
	short firstTile = spriteVramTableAllocateSpace(spriteNumTiles, needle);
	if (firstTile < 0) {
		return firstTile;
	}
	if ((((tileWidth + 1) & 0xFFFE) != tileWidth) || (((tileHeight + 1) & 0xFFFE) != tileHeight)) {
		short tileCount;
		for (short i = firstTile; i < firstTile + spriteNumTiles; i += tileCount) {
			tileCount = cast(short)(((i + 8) & 0xF8) - i);
			if (firstTile + spriteNumTiles - i < tileCount) {
				tileCount = cast(short)(firstTile + spriteNumTiles - i);
			}
			copyToVRAM(3, cast(ushort)(tileCount * 64), cast(ushort)(overworldSpriteVRAMOffsets[i] + 0x4000), &blankTiles[0]);
			copyToVRAM(3, cast(ushort)(tileCount * 64), cast(ushort)(overworldSpriteVRAMOffsets[i] + 0x4100), &blankTiles[0]);
		}
	}
	return firstTile;
}

/// $C01D38
void prepareSpriteMap(short arg1, short arg2, short flags, const(SpriteMapTemplates)* spriteTemplates) {
	SpriteMap* newSpriteMap = &overworldSpriteMaps.ptr[arg1];
	const(SpriteMap)* templateSpriteMap = &spriteTemplates.spriteMapTemplates[0][0];
	for (short i = 0; i < 2; i++) {
		for (short j = 0; j < spriteTemplates.count; j++) {
			newSpriteMap.yOffset = templateSpriteMap.yOffset;
			newSpriteMap.firstTile = cast(ubyte)overworldSpriteOAMTileNumbers[arg2 + j];
			newSpriteMap.flags = cast(ubyte)((templateSpriteMap.flags & 0xFE) | ((overworldSpriteOAMTileNumbers[arg2 + j] >> 8) & 0xFF) | flags);
			newSpriteMap.xOffset = templateSpriteMap.xOffset;
			newSpriteMap.specialFlags = templateSpriteMap.specialFlags;
			newSpriteMap++;
			templateSpriteMap++;
		}
	}
}

/// $C01DED
short getOverworldSpriteTileSize(short arg1) {
	newSpriteTileWidth = spriteGroupingPointers[arg1].width / 16;
	newSpriteTileHeight = spriteGroupingPointers[arg1].height;
	return spriteGroupingPointers[arg1].size;
}

/// $C01E49
short createEntity(short sprite, short actionScript, short index, short x, short y) {
	tracef("Creating new '%s' entity with script '%s', at %s,%s, index %s", cast(OverworldSprite)sprite, cast(ActionScript)actionScript, x, y, index);
	short result;
	if (debugging != 0) {
		if (sprite == -1) {
			return 0;
		}
	}
	short newEntitySize = getOverworldSpriteTileSize(sprite);
	short spriteMapBeginningIndex = reserveOverworldSpriteVRAM(newSpriteTileWidth, newSpriteTileHeight, index);
	assert(spriteMapBeginningIndex >= 0);
	short newSpriteMapIndex = findFreeSpriteMap(overworldSpriteTemplates[newEntitySize].count * 10);
	assert(newSpriteMapIndex >= 0);
	newEntityPriority = 1;
	prepareSpriteMap(newSpriteMapIndex, spriteMapBeginningIndex, spriteGroupingPointers[sprite].spritemapFlags, &overworldSpriteTemplates[newEntitySize]);
	if (index != -1) {
		entityAllocationMinSlot = index;
		entityAllocationMaxSlot = cast(short)(index + 1);
		result = initEntity(actionScript, x, y);
	} else {
		entityAllocationMinSlot = 0;
		entityAllocationMaxSlot = 0x16;
		result = initEntity(actionScript, x, y);
		spriteVramTableOverwrite(-1, cast(ubyte)(result | 0x80));
	}
	entitySpriteMapPointers[result] = &overworldSpriteMaps[newSpriteMapIndex];
	entitySpriteMapSizes[result] = overworldSpriteTemplates[newEntitySize].count * 5;
	entitySpriteMapBeginningIndices[result] = spriteMapBeginningIndex;
	entityVramAddresses[result] = cast(ushort)(overworldSpriteVRAMOffsets[spriteMapBeginningIndex] + 0x4000);
	entityByteWidths[result] = spriteGroupingPointers[sprite].width * 2;
	entityTileHeights[result] = spriteGroupingPointers[sprite].height;
	//UNKNOWN_30X2_TABLE_31[result] = spriteGroupingPointers[sprite].spriteBank;
	entitySpriteIDs[result] = sprite;
	//EntityGraphicsPointerHigh[result] = &spriteGroupingPointers[sprite];
	//EntityGraphicsPointerLow[result] = &spriteGroupingPointers[sprite];
	entityGraphicsPointers[result] = &spriteGroupingPointers[sprite].sprites[0];
	if ((newSpriteTileHeight & 1) != 0) {
		entityVramAddresses[result] += 0x100;
	}
	entitySizes[result] = spriteGroupingPointers[sprite].size;
	entityHitboxUpDownWidth[result] = spriteGroupingPointers[sprite].hitboxWidthUD;
	entityHitboxUpDownHeight[result] = spriteGroupingPointers[sprite].hitboxHeightUD;
	entityHitboxLeftRightWidth[result] = spriteGroupingPointers[sprite].hitboxWidthLR;
	entityHitboxLeftRightHeight[result] = spriteGroupingPointers[sprite].hitboxHeightLR;
	entityHitboxEnabled[result] = unknownC42AEB[spriteGroupingPointers[sprite].size];
	entityUpperLowerBodyDivide[result] = cast(ushort)((overworldSpriteTemplates[newEntitySize].lowerBodyCount << 8) | (overworldSpriteTemplates[newEntitySize].count - overworldSpriteTemplates[newEntitySize].lowerBodyCount));
	entityEnemySpawnTiles[result] = 0xFFFF;
	entityEnemyIDs[result] = -1;
	entityNPCIDs[result] = 0xFFFF;
	entityCollidedObjects[result] = 0xFFFF;
	entitySurfaceFlags[result] = 0;
	entityUnknown2DC6[result] = 0;
	entityUnknown2D8A[result] = 0;
	entityPathfindingState[result] = 0;
	entityMovementSpeed[result] = 0;
	entityDirections[result] = 0;
	entityObstacleFlags[result] = 0;
	return result;
}

/// $C020F1
void unknownC020F1() {
	freeSpritemap(entitySpriteMapPointers[currentEntitySlot]);
	spriteVramTableOverwrite(currentEntitySlot, 0);
	if ((entityNPCIDs[currentEntitySlot] & 0xF000) == 0x8000) {
		overworldEnemyCount--;
	}
	if (entityEnemyIDs[currentEntitySlot] == EnemyID.magicButterfly) {
		magicButterfly = 0;
	}
	entitySpriteIDs[currentEntitySlot] = -1;
	entityNPCIDs[currentEntitySlot] = 0xFFFF;
}

/// $C02140
void unknownC02140(short arg1) {
	freeSpritemap(entitySpriteMapPointers[arg1]);
	spriteVramTableOverwrite(arg1, 0);
	if ((entityNPCIDs[arg1] & 0xF000) == 0x8000) {
		overworldEnemyCount--;
	}
	if (entityEnemyIDs[arg1] == EnemyID.magicButterfly) {
		magicButterfly = 0;
	}
	entitySpriteIDs[arg1] = -1;
	entityNPCIDs[arg1] = 0xFFFF;
	deleteEntity(arg1);
}

/// $C02194
void unknownC02194() {
	magicButterfly = 0;
	enemySpawnTooManyEnemiesFailureCount = 0;
	overworldEnemyCount = 0;
	for (short i = 0; i < maxEntities; i++) {
		if ((entityScriptTable[i] + 1) > 6) {
			unknownC02140(i);
		}
	}
	for (short i = 0; i < maxEntities; i++) {
		entityCollidedObjects[i] = 0xFFFF;
	}
}

/// $C021E6
void unknownC021E6() {
	magicButterfly = 0;
	enemySpawnTooManyEnemiesFailureCount = 0;
	overworldEnemyCount = 0;
	for (short i = 0; i < maxEntities; i++) {
		if (entityScriptTable[i] + 1 <= 2) {
			continue;
		}
		if (i == partyLeaderEntity) {
			continue;
		}
		unknownC02140(i);
	}
	deleteEntity(partyLeaderEntity);
}

/// $C0222B
void trySpawnNPCs(short x, short y) {
	// Don't spawn NPCs outside the bounds of the map data
	if (cast(ushort)x >= 0x20) {
		return;
	}
	if (cast(ushort)y >= 0x28) {
		return;
	}
	if (spritePlacementPointerTable[y][x] != null) {
		short x24 = spritePlacementPointerTable[y][x].entries;
		const(SpritePlacement)* x0A = &spritePlacementPointerTable[y][x].spritePlacements[0];
		for (short i = 0; i < x24; i++) {
			short x20 = x0A.unknown0;
			short x1E = x0A.unknown3;
			short x1C = x0A.unknown2;
			x0A++;
			if ((globalMapTilesetPaletteData[((x1C / 8) + (y * 32)) / 16][((x1E / 8) + (x * 32)) / 32] / 8 == loadedMapTileCombo) && (unknownC0A21C(x20) == 0)) {
				short x18 = cast(short)((x << 8) + x1E);
				short x16 = cast(short)((y << 8) + x1C);
				short x1A = cast(short)(x18 - bg1XPosition);
				short xreg = cast(short)(x16 - bg1YPosition);
				if (debugging != 0) {
					if ((((padState[0] & (Pad.l | Pad.r)) != 0) || (npcSpawnsEnabled != SpawnControl.offscreenOnly)) && ((cast(ushort)x1A < 0x100) && (cast(ushort)xreg < 0xE0))) {
						continue;
					}
				} else {
					// Prevent NPC from spawning if npcSpawnsEnabled != 1 and it is on screen
					if ((npcSpawnsEnabled != SpawnControl.offscreenOnly) && (cast(ushort)x1A < 0x100) && (cast(ushort)xreg < 0xE0)) {
						continue;
					}
				}
				if (-64 > x1A) {
					continue;
				}
				if (0x140 <= x1A) {
					continue;
				}
				if (-64 > xreg) {
					continue;
				}
				if (0x140 <= xreg) {
					continue;
				}
				x1A = -1;
				if (photographMapLoadingMode == 0) {
					if ((debugging != 0) && (npcConfig[x20].appearanceStyle != NPCConfigFlagStyle.showAlways) && (isDebugViewMapMode() != 0) && ((((npcConfig[x20].appearanceStyle - 2) ^ getEventFlag(npcConfig[x20].eventFlag)) & 1) == 0)) {
						continue;
					} else if ((npcConfig[x20].appearanceStyle != NPCConfigFlagStyle.showAlways) && ((((npcConfig[x20].appearanceStyle - 2) ^ getEventFlag(npcConfig[x20].eventFlag)) & 1) == 0)) {
						continue;
					}
					if (debugging != 0) {
						if ((showNPCFlag == 0) || (npcConfig[x20].type == 3)) {
							x1A = createEntity(npcConfig[x20].sprite, debugViewMapLimitActionscript(npcConfig[x20].actionScript), -1, x18, x16);
						}
					} else {
						if ((showNPCFlag == 0) || (npcConfig[x20].type == 3)) {
							x1A = createEntity(npcConfig[x20].sprite, npcConfig[x20].actionScript, -1, x18, x16);
						}
					}
				} else if (npcConfig[x20].appearanceStyle == NPCConfigFlagStyle.showAlways) {
					x1A = createEntity(npcConfig[x20].sprite, ActionScript.unknown799, -1, x18, x16);
				}
				if (x1A != -1) {
					entityDirections[x1A] = npcConfig[x20].direction;
					entityNPCIDs[x1A] = x20;
				}
			}
		}
	}
}

/// $C0255C
void spawnNPCsRow(short x, short y) {
	short x12 = void;
	short x14 = short.min;
	if (npcSpawnsEnabled == SpawnControl.allDisabled) {
		return;
	}
	version(noUndefinedBehaviour) {} else { // use of uninitialized variable
		if (x12 < 0) {
			return;
		}
	}
	short x10 = y / 32;
	for (short i = cast(short)(x - 2); i != x + 36; i++) {
		if (i < 0) {
			continue;
		}
		x12 = i / 32;
		if (x12 == x14) {
			continue;
		}
		trySpawnNPCs(x12, x10);
		x14 = x12;
	}
}

/// $C025CF
void spawnNPCsColumn(short x, short y) {
	short x10 = void;
	short x_ = short.min;
	if (npcSpawnsEnabled == SpawnControl.allDisabled) {
		return;
	}
	version(noUndefinedBehaviour) {} else { //use of uninitialized variable
		if (x10 < 0) {
			return;
		}
	}
	short x0E = x / 32;
	short x12;
	for (short i = y; i != y + 32; i++) {
		if (i < 0) {
			continue;
		}
		x12 = i / 32;
		if (x12 == x_) {
			continue;
		}
		trySpawnNPCs(x0E, x12);
		x_ = x12;
	}
}

/// $C0263D
short getEncounterGroupID(short x, short y) {
	version(noUndefinedBehaviour) {
		if ((x < 0) || (y < 0)) {
			return 0;
		}
	}
	if ((x >= 128) || (y >= 160)) {
		return 0;
	}
	return mapEnemyPlacement[y][x];
}

/// $C02668
void spawnEnemiesFromGroup(short tileX, short tileY, short encounterGroupID) {
	short group;
	const(BattleGroupEnemy)* groupEnemies;
	version(bugfix) { // out of bounds checking wasn't done before
		if (tileX >= mapDataPerSectorAttributesTable[0].length * 4) {
			return;
		}
		if (tileY >= mapDataPerSectorAttributesTable.length * 2) {
			return;
		}
	}
	if ((debugging != 0) && (debugEnemiesEnabled() != 0) && (rand() < 16)) {
		debug(enemySpawnTracing) tracef("Trying to spawn an enemy (debug): %s, %s, %s", tileX, tileY, encounterGroupID);
		group = EnemyGroup.testEnemies;
		groupEnemies = &battleEntryPointerTable[EnemyGroup.testEnemies].enemies[0];
	} else if ((++enemySpawnCounter & 0xF) == 0) {
		debug(enemySpawnTracing) tracef("Trying to spawn a magic butterfly: %s, %s, %s", tileX, tileY, encounterGroupID);
		short magicButterflyChance = void;
		switch (mapDataPerSectorAttributesTable[(tileY * 8) / 16][(tileX * 8) / 32] & 7) {
			case SpecialGameState.none:
				magicButterflyChance = 2;
				break;
			case SpecialGameState.indoorArea:
				magicButterflyChance = 0;
				break;
			case SpecialGameState.exitMouseUsable:
				magicButterflyChance = 1;
				break;
			case SpecialGameState.useMiniSprites:
				magicButterflyChance = 0;
				break;
			case SpecialGameState.useMagicantSprites:
				magicButterflyChance = 5;
				break;
			case SpecialGameState.useRobotSprites:
				magicButterflyChance = 1;
				break;
			default: break;
		}
		if ((rand() % 100) >= magicButterflyChance) {
			return;
		}
		group = EnemyGroup.magicButterfly;
		spawningEnemyGroup = EnemyGroup.magicButterfly;
		groupEnemies = &battleEntryPointerTable[EnemyGroup.magicButterfly].enemies[0];
	} else if (encounterGroupID != 0) {
		debug(enemySpawnTracing) tracef("Trying to spawn an enemy: %s, %s, %s", tileX, tileY, encounterGroupID);
		if (globalMapTilesetPaletteData[(tileY * 8) / 16][(tileX * 8) / 32] / 8 == loadedMapTileCombo) {
			enemySpawnEncounterID = encounterGroupID;
			short flag = enemyPlacementGroupsPointerTable[encounterGroupID].eventFlag;
			const(EnemyPlacementGroup)* selectedGroup = enemyPlacementGroupsPointerTable[encounterGroupID].groups.ptr;
			enemySpawnChance = enemyPlacementGroupsPointerTable[encounterGroupID].enemySpawnChance;
			short rollAdjustment = 0;
			if ((flag != 0) && (getEventFlag(flag) != 0)) {
				enemySpawnChance = enemyPlacementGroupsPointerTable[encounterGroupID].altEnemySpawnChance;
				if (enemyPlacementGroupsPointerTable[encounterGroupID].enemySpawnChance != 0) {
					rollAdjustment = 8;
				}
			}
			if ((piracyFlag == 0) && (((rand() * 100) >> 8) >= enemySpawnChance)) {
				return;
			}
			short roll = rand() & 7 + rollAdjustment;
			short entrySlot = 0;
			while (true) {
				entrySlot += selectedGroup[0].slotsOccupied;
				if (roll < entrySlot) {
					break;
				}
				selectedGroup++;
			}
			group = selectedGroup[0].groupID;
			spawningEnemyGroup = group;
			groupEnemies = &battleEntryPointerTable[group].enemies[0];
			for (short i = 0; i != partyLeaderEntity; i++) {
				if (entityScriptTable[i] == -1) {
					continue;
				}
				if (group + 0x8000 != entityNPCIDs[i]) {
					continue;
				}
				if (tileY * 128 + tileX == entityEnemySpawnTiles[i]) {
					return;
				}
			}
		}
	}
	version(noUndefinedBehaviour) {
		if (groupEnemies is null) {
			return;
		}
	}
	while ((enemySpawnRemainingEnemyCount = groupEnemies[0].count) != 0xFF) {
		debug(enemySpawnTracing) tracef("Trying to spawn %sx %s", groupEnemies[0].count, cast(EnemyID)groupEnemies[0].enemyID);
		spawningEnemyName = &enemyConfigurationTable[groupEnemies[0].enemyID].name[0];
		short sprite = enemyConfigurationTable[groupEnemies[0].enemyID].overworldSprite;
		spawningEnemySprite = sprite;
		short script = enemyConfigurationTable[groupEnemies[0].enemyID].eventScript;
		if (script == 0) {
			script = ActionScript.unknown019;
		}
		while (enemySpawnRemainingEnemyCount-- != 0) {
			if (groupEnemies[0].enemyID == EnemyID.magicButterfly) {
				if (magicButterfly != 0) {
					continue;
				}
			}
			if (overworldEnemyCount == overworldEnemyMaximum) {
				enemySpawnTooManyEnemiesFailureCount++;
				continue;
			}
			enemySpawnTooManyEnemiesFailureCount = 0;
			short newEntity = createEntity(sprite, script, -1, 0, 0);
			short newEntityX;
			short newEntityY;
			for (short i = 0; i != 20; i++) {
				newEntityX = cast(short)((tileX * 8 + (rand() % enemySpawnRangeWidth)) * 8);
				newEntityY = cast(short)((tileY * 8 + (rand() % enemySpawnRangeHeight)) * 8);
				debug(enemySpawnTracing) tracef("Spawning %s at (%s, %s)", cast(EnemyID)groupEnemies[0].enemyID, newEntityX, newEntityY);
				short positionFlags = getSurfaceFlags(newEntityX, newEntityY, newEntity);
				if ((positionFlags & (SurfaceFlags.solid | SurfaceFlags.unknown2 | SurfaceFlags.ladderOrStairs)) != 0) {
					// can't spawn here, try again
					continue;
				}
				if (unknownC05DE7(positionFlags, newEntity, groupEnemies[0].enemyID) == 0) {
					// this spot is fine, proceed
					goto SpawnSuccess;
				}
			}
			// didn't find a suitable spawn location after 20 tries, so clean up
			unknownC02140(newEntity);
			continue;
			SpawnSuccess:
			entityAbsXTable[newEntity] = newEntityX;
			entityAbsYTable[newEntity] = newEntityY;
			entityNPCIDs[newEntity] = group + 0x8000;
			entityEnemyIDs[newEntity] = groupEnemies[0].enemyID;
			entityEnemySpawnTiles[newEntity] = cast(short)(tileY * 128 + tileX);
			entityPathfindingState[newEntity] = 0;
			entityWeakEnemyValue[newEntity] = rand();
			overworldEnemyCount++;
			if (groupEnemies[0].enemyID == EnemyID.magicButterfly) {
				magicButterfly = 1;
			}
		}
		groupEnemies++;
	}
}

/// $C02A6B
void spawnEnemiesRow(short tileX, short tileY) {
	if (getEventFlag(EventFlag.sysMonsterOff) != 0) {
		return;
	}
	if (getEventFlag(EventFlag.winGiegu) != 0) {
		return;
	}
	if (enemySpawnsEnabled == SpawnControl.allDisabled) {
		return;
	}
	if ((tileY & 7) != 0) {
		return;
	}
	if (((tileY < -16) ? 0 : tileY) >= 0x500) {
		return;
	}
	short baseEnemySectorX = tileX / 8;
	short baseEnemySectorY = ((tileY < -16) ? 0 : tileY) / 8;
	// try to spawn an enemy group for each enemy sector in (X, Y) .. (X + 6, Y), an area 48 tiles wide, 1 tile tall
	for (short i = baseEnemySectorX; baseEnemySectorX + 5 > i; i++) {
		short enemySectorX = i;
		enemySpawnRangeWidth = 8;
		enemySpawnRangeHeight = 8;
		short spawnAttempts = 1;
		AttemptAnotherSpawn:
		short group = getEncounterGroupID(i, baseEnemySectorY);
		short groupNext = getEncounterGroupID(cast(short)(i + 1), baseEnemySectorY);
		if ((group != 0) && (groupNext == group)) {
			enemySpawnRangeWidth += 8;
			i++;
			if (++spawnAttempts != 6) {
				goto AttemptAnotherSpawn;
			}
		}
		while (spawnAttempts-- != 0) {
			spawnEnemiesFromGroup(enemySectorX, baseEnemySectorY, group);
		}
	}
}

/// $C02B55
void spawnEnemiesColumn(short tileX, short tileY) {
	if (getEventFlag(EventFlag.sysMonsterOff) != 0) {
		return;
	}
	if (getEventFlag(EventFlag.winGiegu) != 0) {
		return;
	}
	if (enemySpawnsEnabled == SpawnControl.allDisabled) {
		return;
	}
	if ((tileX & 7) != 0) {
		return;
	}
	if (((tileX < -16) ? 0 : tileX) >= 0x400) {
		return;
	}
	short baseEnemySectorX = ((tileX < -16) ? 0 : tileX) / 8;
	short baseEnemySectorY = tileY / 8;
	// try to spawn an enemy group for each enemy sector in (X, Y) .. (X, Y + 6), an area 1 tile wide, 48 tiles tall
	for (short i = baseEnemySectorY; baseEnemySectorY + 5 > i; i++) {
		short enemySectorY = i;
		enemySpawnRangeWidth = 8;
		enemySpawnRangeHeight = 8;
		short spawnAttempts = 1;
		AttemptAnotherSpawn:
		short group = getEncounterGroupID(baseEnemySectorX, i);
		short groupNext = getEncounterGroupID(baseEnemySectorX, cast(short)(i + 1));
		if ((group != 0) && (groupNext == group)) {
			enemySpawnRangeHeight += 8;
			i++;
			if (++spawnAttempts != 6) {
				goto AttemptAnotherSpawn;
			}
		}
		while (spawnAttempts-- != 0) {
			spawnEnemiesFromGroup(baseEnemySectorX, enemySectorY, group);
		}
	}
}

/// $C02C3E
void enableMushroomizedWalking() {
	if (partyCharacters[gameState.playerControlledPartyMembers[0]].afflictions[1] == Status1.mushroomized) {
		mushroomizedWalkingFlag = 1;
		if (mushroomizationTimer == 0) {
			mushroomizationTimer = 1800;
			mushroomizationModifier = 0;
		}
		if (gameState.walkingStyle == WalkingStyle.bicycle) {
			getOffBicycle();
		}
	} else {
		mushroomizedWalkingFlag = 0;
	}
}

/// $C02C89
void mushroomizationMovementSwap() {
	if (mushroomizationTimer == 0) {
		mushroomizationTimer = 30 * 60;
		mushroomizationModifier = (mushroomizationModifier + 1) & 3;
	}
	mushroomizationTimer--;
	if (mushroomizationModifier == 0) {
		return;
	}
	if (demoFramesLeft != 0) {
		return;
	}
	padPress[0] = (padPress[0] & 0xF0FF) | mushroomizationDirectionRemapTables[mushroomizationModifier - 1][(padPress[0] >> 8) & 0xF];
	padState[0] = (padState[0] & 0xF0FF) | mushroomizationDirectionRemapTables[mushroomizationModifier - 1][(padState[0] >> 8) & 0xF];
}

/// $C02D29
void clearParty() {
	entitySizes[partyLeaderEntity] = 1;
	miniGhostEntityID = -1;
	gameState.leaderPositionIndex = 0;
	gameState.cameraMode = CameraMode.normal;
	gameState.autoScrollFrames = 0;
	gameState.autoScrollOriginalWalkingStyle = 0;
	gameState.partyStatus = PartyStatus.normal;
	gameState.firstPartyMemberEntity = 0x18;
	for (short i = 0; i < 6; i++) {
		gameState.partyMemberIndex[i] = 0;
		hpAlertShown[i] = 0;
	}
	gameState.playerControlledPartyMemberCount = 0;
	gameState.partyCount = 0;
	velocityStore();
	pajamaFlag = getEventFlag(nessPajamaFlag);
}

/// $C02D8F
uint adjustPositionHorizontal(short arg1, uint arg2, short arg3) {
	switch (arg3 & SurfaceFlags.deepWater) {
		case SurfaceFlags.shallowWater:
			return (((horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * ShallowWaterSpeed.combined) / 256) + arg2;
		case SurfaceFlags.deepWater:
			return (((horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * DeepWaterSpeed.combined) / 256) + arg2;
		default:
			if (demoFramesLeft != 0) {
				return horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined + arg2;
			} else if ((gameState.partyStatus == PartyStatus.speedBoost) && (gameState.walkingStyle == 0)) {
				return (((horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * SkipSandwichSpeed.combined) / 256) + arg2;
			}
			return horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined + arg2;
	}
}

/// $C03017
uint adjustPositionVertical(short arg1, uint arg2, short arg3) {
	switch (arg3 & SurfaceFlags.deepWater) {
		case SurfaceFlags.shallowWater:
			return (((verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * ShallowWaterSpeed.combined) / 256) + arg2;
		case SurfaceFlags.deepWater:
			return (((verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * DeepWaterSpeed.combined) / 256) + arg2;
		default:
			if (demoFramesLeft != 0) {
				return verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined + arg2;
			} else if ((gameState.partyStatus == PartyStatus.speedBoost) && (gameState.walkingStyle == 0)) {
				return (((verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined / 256) * SkipSandwichSpeed.combined) / 256) + arg2;
			}
			return verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[arg1].combined + arg2;
	}
}

/// $C032EC
void updatePartyNPCs() {
	short y;
	for (y = 0; (gameState.partyMembers[y] != 0) && (5 > gameState.partyMembers[y]); y++) {}
	gameState.playerControlledPartyMemberCount = cast(ubyte)y;
	if (gameState.partyNPCs[0] != gameState.partyMembers[y]) {
		if (gameState.partyNPCs[1] == gameState.partyMembers[y]) {
			gameState.partyNPCs[0] = gameState.partyNPCs[1];
			gameState.partyNPCHP[0] = gameState.partyNPCHP[1];
			gameState.partyNPCs[1] = gameState.partyMembers[y + 1];
			gameState.partyNPCHP[1] = enemyConfigurationTable[npcAITable[gameState.partyMembers[y + 1]].enemyID].hp;
		} else if (gameState.partyNPCs[0] == gameState.partyMembers[y + 1]) {
			gameState.partyNPCs[1] = gameState.partyNPCs[0];
			gameState.partyNPCHP[1] = gameState.partyNPCHP[0];
			gameState.partyNPCs[0] = gameState.partyMembers[y];
			gameState.partyNPCHP[0] = enemyConfigurationTable[npcAITable[gameState.partyMembers[y]].enemyID].hp;
		} else {
			gameState.partyNPCs[0] = gameState.partyMembers[y];
			gameState.partyNPCHP[0] = enemyConfigurationTable[npcAITable[gameState.partyMembers[y]].enemyID].hp;
			if (gameState.partyNPCs[1] != gameState.partyMembers[y + 1]) {
				gameState.partyNPCs[1] = gameState.partyMembers[y + 1];
				gameState.partyNPCHP[1] = enemyConfigurationTable[npcAITable[gameState.partyMembers[y + 1]].enemyID].hp;
			}
		}
	} else if (gameState.partyNPCs[1] != gameState.partyMembers[y + 1]) {
		gameState.partyNPCs[1] = gameState.partyMembers[y + 1];
		gameState.partyNPCHP[1] = enemyConfigurationTable[npcAITable[gameState.partyMembers[y + 1]].enemyID].hp;
	}
}

/// $C034D6
void updateParty() {
	short[6] local1;
	short[6] local2;
	short[6] local3;
	short[6] local4;
	short partyCount = gameState.partyCount;
	for (short i = 0; i < partyCount; i++) {
		local1[i] = partyCharacters[gameState.playerControlledPartyMembers[i]].positionIndex;
	}
	for (short i = 0; i < partyCount; i++) {
		short local9 = gameState.partyMemberIndex[i];
		if (local9 >= 5) {
			local9 += 0x300;
		} else {
			short x = partyCharacters[entityScriptVar1Table[gameState.partyEntities[i]]].afflictions[0];
			if ((x == Status0.unconscious) || (x == Status0.diamondized)) {
				local9 += 0x100;
			}
		}
		local2[i] = local9;
		local3[i] = gameState.partyEntities[i];
		local4[i] = gameState.playerControlledPartyMembers[i];
	}
	for (short i = 0; partyCount - 1 > i; i++) {
		for (short j = 0; partyCount - 1 > j; j++) {
			short local9 = local2[j];
			short local11 = local2[j + 1];
			if (local9 > local11) {
				local2[j] = local11;
				local2[j + 1] = local9;
				short local6 = local3[j];
				local3[j] = local3[j + 1];
				local3[j + 1] = local6;
				short local11_2 = local4[j];
				local4[j] = local4[j + 1];
				local4[j + 1] = local11_2;
			}
		}
	}
	for (short i = 0; i < partyCount; i++) {
		gameState.partyMemberIndex[i] = cast(ubyte)local2[i];
		gameState.partyEntities[i] = cast(ubyte)local3[i];
		gameState.playerControlledPartyMembers[i] = cast(ubyte)local4[i];
		partyCharacters[i].positionIndex = local1[i];
		entityScriptVar5Table[i] = gameState.partyEntities[i];
	}
	gameState.firstPartyMemberEntity = gameState.partyEntities[0];
	updatePartyNPCs();
	enableMushroomizedWalking();
	loadTextPalette();
}

/// $C0369B
short unknownC0369B(short id) {
	short x18 = 0;
	if (id >= 5) {
		while(true) {
			if (gameState.partyMemberIndex[x18] == 0) {
				break;
			}
			if (gameState.partyMemberIndex[x18] > id) {
				break;
			}
			x18++;
		}
	} else {
		while (true) {
			if (gameState.partyMemberIndex[x18] == 0) {
				break;
			}
			if (5 <=gameState.partyMemberIndex[x18]) {
				break;
			}
			if (gameState.partyMemberIndex[x18] > id) {
				break;
			}
			version(bugfix) {
				if (partyCharacters[entityScriptVar1Table[gameState.partyEntities[gameState.partyMemberIndex[x18] - 1]]].afflictions[0] == Status0.unconscious) {
					break;
				}
			} else { // Vanilla game incorrectly uses the party member index as an entity id
				if (partyCharacters[entityScriptVar1Table[gameState.partyMemberIndex[x18]]].afflictions[0] == Status0.unconscious) {
					break;
				}
			}
			x18++;
		}
	}
	if (gameState.partyMemberIndex[x18] != 0) {
		version(bugfix) { // vanilla game has an underflow error that went unnoticed because the garbage data would immediately get overwritten
			enum sub = 0;
		} else {
			enum sub = 1;
		}
		for (short i = 5; i != x18 - sub; i--) {
			gameState.partyMemberIndex[i] = gameState.partyMemberIndex[i - 1];
			gameState.partyEntities[i] = gameState.partyEntities[i - 1];
			gameState.playerControlledPartyMembers[i] = gameState.playerControlledPartyMembers[i - 1];
		}
	}
	gameState.partyMemberIndex[x18] = cast(ubyte)id;
	gameState.partyCount++;
	newEntityVar0 = cast(short)(id - 1);
	short x1A_2 = characterInitialEntityData[id - 1].unknown6;
	if (entityScriptTable[x1A_2] != -1) {
		x1A_2++;
	}
	gameState.partyEntities[x18] = cast(ubyte)x1A_2;
	newEntityVar1 = cast(short)(x1A_2 - 0x18);
	gameState.playerControlledPartyMembers[x18] = cast(ubyte)newEntityVar1;
	if (gameState.partyCount == 1) {
		partyCharacters[newEntityVar1].positionIndex = gameState.leaderPositionIndex;
	} else {
		short x16 = (x18 == 0) ? gameState.leaderPositionIndex : partyCharacters[entityScriptVar1Table[gameState.partyEntities[x18 - 1]]].positionIndex;
		partyCharacters[newEntityVar1].positionIndex = x16;
	}
	short x = (partyCharacters[newEntityVar1].positionIndex != 0) ? cast(short)(partyCharacters[newEntityVar1].positionIndex - 1) : 0xFF;
	short x18_2 = (gameState.specialGameState != SpecialGameState.useMiniSprites) ? characterInitialEntityData[id - 1].overworldSprite : characterInitialEntityData[id - 1].lostUnderworldSprite;
	createEntity(x18_2, characterInitialEntityData[id - 1].actionScript, x1A_2, playerPositionBuffer[x].xCoord, playerPositionBuffer[x].yCoord);
	entityScreenXTable[x1A_2] = cast(short)(playerPositionBuffer[x].xCoord - bg1XPosition);
	entityScreenYTable[x1A_2] = cast(short)(playerPositionBuffer[x].yCoord - bg1YPosition);
	gameState.firstPartyMemberEntity = characterInitialEntityData[gameState.partyMemberIndex[0] - 1].unknown6;
	unknownC09CD7();
	updatePartyNPCs();
	gameState.firstPartyMemberEntity = gameState.partyEntities[0];
	updateParty();
	entityPreparedXCoordinate = playerPositionBuffer[x].xCoord;
	entityPreparedYCoordinate = playerPositionBuffer[x].yCoord;
	entityPreparedDirection = entityDirections[x1A_2];
	return x1A_2;
}

/// $C03903
void unknownC03903(short id) {
	short i;
	for (i = 0; (gameState.partyMemberIndex[i] != id) && (i != 6); i++) {}
	if (i == 6) {
		return;
	}
	const x02 = gameState.partyEntities[i];
	short j;
	for (j = i; j < 5; j++) {
		gameState.partyMemberIndex[j] = gameState.partyMemberIndex[j + 1];
		gameState.partyEntities[j] = gameState.partyEntities[j + 1];
		gameState.playerControlledPartyMembers[j] = gameState.playerControlledPartyMembers[j + 1];
	}
	if (i == 0) {
		partyCharacters[gameState.playerControlledPartyMembers[0]].positionIndex = entityScriptVar1Table[x02];
	}
	gameState.partyMemberIndex[j] = 0;
	gameState.partyCount--;
	entityPreparedXCoordinate = entityAbsXTable[x02];
	entityPreparedYCoordinate = entityAbsYTable[x02];
	entityPreparedDirection = entityDirections[x02];
	unknownC02140(x02);
	updatePartyNPCs();
	updateParty();
}

/// $C039E5
void setFollowerEntityLocationToLeaderPosition() {
	for (short i = 0; i < 6; i++) {
		if (gameState.partyMemberIndex[i] == 0) {
			continue;
		}
		entityAbsXTable[gameState.partyEntities[i]] = gameState.leaderX.integer;
		entityAbsYTable[gameState.partyEntities[i]] = gameState.leaderY.integer;
		recalculateEntityScreenPosition(gameState.partyEntities[i]);
	}
}

/// $C03A24
void unknownC03A24() {
	gameState.playerControlledPartyMemberCount = 0;
	gameState.partyCount = 0;
	for (short i = 0; i < 6; i++) {
		gameState.partyMemberIndex[i] = 0;
		gameState.playerControlledPartyMembers[i] = 0;
		gameState.partyEntities[i] = 0;
	}
	unread7E5D7E = 1;
	for (short i = 0; i < 6; i++) {
		if (gameState.partyMembers[i] == 0) {
			break;
		}
		unknownC0369B(gameState.partyMembers[i]);
	}
	unread7E5D7E = 0;
	footstepSoundID = cast(short)(gameState.specialGameState * 2);
	footstepSoundIDOverride = 0;
}

/// $C03A94
void unknownC03A94(short arg1) {
	short x1C;
	short x;
	if ((currentTeleportDestinationX | currentTeleportDestinationY) != 0) {
		x1C = cast(short)(currentTeleportDestinationX * 8);
		x = cast(short)(currentTeleportDestinationY * 8);
	} else {
		x1C = gameState.leaderX.integer;
		x = gameState.leaderY.integer;
	}
	short x1A = loadSectorAttributes(x1C, x) & 7;
	gameState.specialGameState = x1A;
	footstepSoundID = cast(short)(x1A * 2);
	footstepSoundIDOverride = 0;
	if (x1A != SpecialGameState.useMiniSprites) {
		gameState.walkingStyle = 0;
	} else {
		gameState.walkingStyle = WalkingStyle.slowest;
	}
	short x18 = currentEntitySlot;
	currentEntitySlot = -1;
	for (short i = 0; i < 6; i++) {
		if (gameState.partyMemberIndex[i] == 0) {
			continue;
		}
		newEntityVar0 = entityScriptVar0Table[gameState.partyEntities[i]];
		newEntityVar1 = entityScriptVar1Table[gameState.partyEntities[i]];
		newEntityVar5 = cast(short)(i * 2);
		short x14 = entitySpriteMapFlags[gameState.partyEntities[i]];
		short x1A_2 = entityCallbackFlags[gameState.partyEntities[i]];
		unknownC02140(gameState.partyEntities[i]);
		movingPartyMemberEntityID = gameState.partyEntities[i];
		short x12;
		if (gameState.specialGameState != SpecialGameState.useMiniSprites) {
			x12 = createEntity(unknownC0780F(gameState.partyMemberIndex[i] - 1, 0, &partyCharacters[i]), characterInitialEntityData[gameState.partyMemberIndex[i] - 1].actionScript, gameState.partyEntities[i], gameState.leaderX.integer, gameState.leaderY.integer);
		} else {
			x12 = createEntity(unknownC0780F(gameState.partyMemberIndex[i] - 1, 10, &partyCharacters[i]), characterInitialEntityData[gameState.partyMemberIndex[i] - 1].actionScript, gameState.partyEntities[i], gameState.leaderX.integer, gameState.leaderY.integer);
		}
		entitySpriteMapFlags[gameState.partyEntities[i]] = x14;
		entityCallbackFlags[gameState.partyEntities[i]] = x1A_2;
		entityDirections[gameState.partyEntities[i]] = arg1;
		entityAnimationFrames[gameState.partyEntities[i]] = 0;
		updateEntitySpriteFrame(x12);
	}
	currentEntitySlot = x18;
	setFollowerEntityLocationToLeaderPosition();
	ladderStairsTileX = 0xFFFF;
	short x02 = pendingInteractions;
	pendingInteractions = 0;
	checkMovementMapCollision(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity, Direction.down);
	pendingInteractions = x02;
	if (ladderStairsTileX != -1) {
		unknownC07526(ladderStairsTileX, ladderStairsTileY);
	}
}

/// $C03C25
void doSectorMusicUpdate() {
	doMapMusicFade = 1;
	loadSectorMusic(gameState.leaderX.integer, gameState.leaderY.integer);
	if (nextMapMusicTrack != currentMapMusicTrack) {
		waitUntilNextFrame();
		changeMapMusic();
	}
	doMapMusicFade = 0;
}

/// $C03C4B
short checkBicycleCollisionFlags() {
	return getCollisionFlags(gameState.leaderX.integer, gameState.leaderY.integer, 12) & (SurfaceFlags.solid | SurfaceFlags.unknown2);
}

/// $C03C5E
void getOnBicycle() {
	if (gameState.partyCount != 1) {
		return;
	}
	if (gameState.partyMemberIndex[0] != 1) {
		return;
	}
	if (disableMusicChanges == 0) {
		changeMusic(Music.bicycle);
	}
	unknownC02140(0x18);
	gameState.specialGameState = SpecialGameState.onBicycle;
	gameState.walkingStyle = WalkingStyle.bicycle;
	partyCharacters[0].positionIndex = 0;
	gameState.leaderPositionIndex = 0;
	newEntityVar0 = 0;
	newEntityVar1 = 0;
	createEntity(OverworldSprite.nessBicycle, ActionScript.partyMemberFollowing, 0x18, entityAbsXTable[partyMemberEntityStart], entityAbsYTable[partyMemberEntityStart]);
	entityCallbackFlags[partyMemberEntityStart] |= EntityCallbackFlags.tickDisabled;
	entityScriptVar7Table[partyMemberEntityStart] |= PartyMemberMovementFlags.unknown12 | PartyMemberMovementFlags.unknown13;
	entityAnimationFrames[partyMemberEntityStart] = 0;
	entityDirections[partyMemberEntityStart] = gameState.leaderDirection;
	setBoundaryBehaviour(0);
	gameState.leaderHasMoved = 1;
	unread7E5DBA = 1;
	inputDisableFrameCounter = 2;
}

/// $C03CFD
void getOffBicycle() {
	if (gameState.walkingStyle != WalkingStyle.bicycle) {
		return;
	}
	setBoundaryBehaviour(1);
	if ((battleMode == BattleMode.noBattle) && (pendingInteractions == 0)) {
		unknownC06A07();
	}
	unknownC02140(0x18);
	gameState.specialGameState = SpecialGameState.none;
	gameState.walkingStyle = 0;
	partyCharacters[0].positionIndex = 0;
	gameState.leaderPositionIndex = 0;
	if (pendingInteractions == 0) {
		oamClear();
		runActionscriptFrame();
		updateScreen();
		waitUntilNextFrame();
	}
	newEntityVar0 = 0;
	newEntityVar1 = 0;
	createEntity(OverworldSprite.ness, ActionScript.partyMemberFollowing, 0x18, entityAbsXTable[partyMemberEntityStart], entityAbsYTable[partyMemberEntityStart]);
	entityAnimationFrames[partyMemberEntityStart] = 0;
	entityDirections[partyMemberEntityStart] = gameState.leaderDirection;
	entityScriptVar7Table[partyMemberEntityStart] |= PartyMemberMovementFlags.unknown12 | PartyMemberMovementFlags.unknown15;
	if (pendingInteractions != 0) {
		entityCallbackFlags[partyMemberEntityStart] |= PartyMemberMovementFlags.unknown14 | PartyMemberMovementFlags.unknown15;
	}
	waitUntilNextFrame();
	waitUntilNextFrame();
	updateEntitySpriteFrame(0x18);
	unread7E5DBA = 0;
	inputDisableFrameCounter = 2;
}

/// $C03E5A
short unknownC03E5A(short characterID) {
	short x;
	version(bugfix) {
		for (x = 0; (x < gameState.partyMemberIndex.length) && (gameState.partyMemberIndex[x] != characterID + 1); x++) {}
	} else {
		for (x = 0; gameState.partyMemberIndex[x] != characterID + 1; x++) {}
	}
	if (x == 0) {
		return -1;
	}
	return chosenFourPtrs[entityScriptVar1Table[gameState.partyEntities[x - 1]]].positionIndex;
}

/// $C03E9D
short unknownC03E9D(short characterID) {
	short x0E = unknownC03E5A(characterID);
	if (x0E < currentPartyMemberTick.positionIndex) {
		x0E += 0x100;
	}
	return cast(short)(x0E - currentPartyMemberTick.positionIndex);
}

/// $C03EC3
short getNewPositionIndex(short characterID, short distance, short arg3, short arg4) {
	short tmp = unknownC03E9D(characterID);
	if (tmp == distance) {
		arg3++;
		entityScriptVar7Table[currentEntitySlot] &= ~PartyMemberMovementFlags.unknown12;
	} else if (tmp > distance) {
		arg3 += arg4;
		entityScriptVar7Table[currentEntitySlot] |= PartyMemberMovementFlags.unknown12;
	}
	return arg3;
}

/// $C03DAA
void unknownC03DAA() {
	entityAnimationFingerprints[currentEntitySlot] = -1;
	entityScriptVar3Table[currentEntitySlot] = 8;
	entityScriptVar2Table[currentEntitySlot] = rand() & 0xF;
	updateEntitySpriteFrame(currentEntitySlot);
	partyCharacters[entityScriptVar1Table[currentEntitySlot]].unknown59 = currentEntitySlot;
	partyCharacters[entityScriptVar1Table[currentEntitySlot]].characterID = entityScriptVar0Table[currentEntitySlot];
	partyCharacters[entityScriptVar1Table[currentEntitySlot]].unknown57 = 0;
	partyCharacters[entityScriptVar1Table[currentEntitySlot]].unknown92 = -1;
	if (partyCharacters[entityScriptVar1Table[currentEntitySlot]].afflictions[0] == Status0.unconscious) {
		entityScriptVar3Table[currentEntitySlot] = 16;
	}
	footstepSoundIgnoreEntity = cast(short)(gameState.firstPartyMemberEntity * 2);
}

/// $C03F1E
void movePartyToLeaderPosition() {
	gameState.leaderPositionIndex = 0;
	PlayerPositionBufferEntry* x = &playerPositionBuffer[0];
	short y = 2;
	while (--y != 0) {
		x.xCoord = gameState.leaderX.integer;
		x.yCoord = gameState.leaderY.integer;
		x.direction = gameState.leaderDirection;
		x.walkingStyle = gameState.walkingStyle;
		x.tileFlags = gameState.troddenTileType;
		playerMovementFlags = 0;
		x.unknown10 = 0;
		x += 255;
	}
	for (short i = 0; i < gameState.partyCount; i++) {
		version(bugfix) {
			if (chosenFourPtrs[gameState.playerControlledPartyMembers[i]] is null) {
				continue;
			}
		}
		chosenFourPtrs[gameState.playerControlledPartyMembers[i]].positionIndex = 0;
		chosenFourPtrs[gameState.playerControlledPartyMembers[i]].unknown65 = 0xFFFF;
		chosenFourPtrs[gameState.playerControlledPartyMembers[i]].unknown55 = 0xFFFF;
		entityAbsXTable[gameState.partyEntities[i]] = gameState.leaderX.integer;
		entityAbsYTable[gameState.partyEntities[i]] = gameState.leaderY.integer;
		entityDirections[gameState.partyEntities[i]] = gameState.leaderDirection;
		entitySurfaceFlags[gameState.partyEntities[i]] = gameState.troddenTileType;
	}
}

/// $C03FA9
void unknownC03FA9(short x, short y, short direction) {
	gameState.leaderX.integer = x;
	gameState.leaderY.integer = y;
	gameState.leaderDirection = direction;
	gameState.troddenTileType = getSurfaceFlags(x, y, gameState.firstPartyMemberEntity);
	unknownC03A94(direction);
	movePartyToLeaderPosition();
	for (short i = 0; i < 6; i++) {
		entityAnimationFingerprints[i + partyMemberEntityStart] = -1;
	}
	miniGhostEntityID = -1;
	currentTeleportDestinationY = 0;
	currentTeleportDestinationX = 0;
	pajamaFlag = getEventFlag(nessPajamaFlag);
	unknownC07B52();
}

/// $C0400E
void centerScreen(short x, short y) {
	refreshMapAtPosition(cast(short)(x - 0x80), cast(short)(y - 0x70));
}

/// $C0402B
void startAutoMovementDemo(DemoEntry* arg1) {
	demoReplayStart(arg1);
}

/// $C0404F
short mapInputToDirection(short style) {
	short result = -1;
	if (pendingInteractions != 0) {
		return -1;
	}
	style = allowedInputDirections[style];
	switch (padState[0] & (Pad.up | Pad.down | Pad.left | Pad.right)) {
		case Pad.up:
			if ((style & DirectionMask.up) != 0) {
				result = Direction.up;
			}
			break;
		case (Pad.up | Pad.right):
			if ((style & DirectionMask.upRight) != 0) {
				result = Direction.upRight;
			}
			break;
		case Pad.right:
			if ((style & DirectionMask.right) != 0) {
				result = Direction.right;
			}
			break;
		case (Pad.down | Pad.right):
			if ((style & DirectionMask.downRight) != 0) {
				result = Direction.downRight;
			}
			break;
		case Pad.down:
			if ((style & DirectionMask.down) != 0) {
				result = Direction.down;
			}
			break;
		case (Pad.down | Pad.left):
			if ((style & DirectionMask.downLeft) != 0) {
				result = Direction.downLeft;
			}
			break;
		case Pad.left:
			if ((style & DirectionMask.left) != 0) {
				result = Direction.left;
			}
			break;
		case (Pad.up | Pad.left):
			if ((style & DirectionMask.upLeft) != 0) {
				result = Direction.upLeft;
			}
			break;
		default: break;
	}
	return result;
}

/// $C04116
short unknownC04116(short direction) {
	short x14 = cast(short)(unknownC3E148[direction] + gameState.leaderX.integer);
	short x04 = cast(short)(unknownC3E158[direction] + gameState.leaderY.integer);
	short x12 = playerIntangibilityFrames;
	playerIntangibilityFrames = 1;
	while (true) {
		short x10 = npcCollisionCheck(x14, x04, gameState.firstPartyMemberEntity);
		if (x10 > 0) {
			interactingNPCID = entityNPCIDs[x10];
			interactingNPCEntity = x10;
			break;
		}
		if ((unknownC05CD7(x14, x04, gameState.firstPartyMemberEntity, direction) & (SurfaceFlags.solid | SurfaceFlags.obscureUpperBody)) != (SurfaceFlags.solid | SurfaceFlags.obscureUpperBody)) {
			break;
		}
		if (unknownC3E148[direction] != 0) {
			x14 += ((unknownC3E148[direction] & 0x8000) != 0) ? -8 : 8;
		}
		if (unknownC3E158[direction] != 0) {
			x04 += ((unknownC3E158[direction] & 0x8000) != 0) ? -8 : 8;
		}
	}
	playerIntangibilityFrames = x12;
	if ((interactingNPCID == -1) || (interactingNPCID == 0)) {
		unknownC4334A(direction);
	}
	return interactingNPCID;
}

/// $C041E3
short unknownC041E3() {
	short x10 = cast(short)(gameState.leaderDirection & 0xFFFE);
	short a = unknownC04116(cast(short)(gameState.leaderDirection & 0xFFFE));
	if ((a != -1) && (a != 0)) {
		return cast(short)(gameState.leaderDirection & 0xFFFE);
	}
	gameState.leaderDirection = (((gameState.leaderDirection & 0xFFFE) + 2) & 7);
	a = unknownC04116(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return gameState.leaderDirection;
	}
	gameState.leaderDirection = ((gameState.leaderDirection + 4) & 7);
	a = unknownC04116(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return gameState.leaderDirection;
	}
	gameState.leaderDirection = ((gameState.leaderDirection - 2) & 7);
	a = unknownC04116(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return gameState.leaderDirection;
	}
	gameState.leaderDirection = x10;
	return -1;
}

/// $C042C2
void faceOppositeLeader(short arg1) {
	entityDirections[arg1] = oppositeCardinals[gameState.leaderDirection];
	unknownC09907(arg1);
	updateEntitySprite(arg1);
}

/// $C04279
ushort findNearbyCheckableTPTEntry() {
	interactingNPCID = -1;
	interactingNPCEntity = -1;
	short x10 = unknownC041E3();
	if ((x10 != -1) && (entityDirections[gameState.firstPartyMemberEntity] != x10)) {
		gameState.leaderDirection = x10;
		entityDirections[gameState.firstPartyMemberEntity] = x10;
		updateEntitySpriteFrame(gameState.firstPartyMemberEntity);
	}
	return interactingNPCID;
}

/// $C042EF
short unknownC042EF(short direction) {
	short x14 = cast(short)(unknownC3E148[direction] + gameState.leaderX.integer);
	short x04 = cast(short)(unknownC3E158[direction] + gameState.leaderY.integer);
	short x12 = playerIntangibilityFrames;
	playerIntangibilityFrames = 1;
	while (true) {
		short x10 = npcCollisionCheck(x14, x04, gameState.firstPartyMemberEntity);
		if (x10 >= 0) {
			interactingNPCID = entityNPCIDs[x10];
			interactingNPCEntity = x10;
			break;
		}
		if ((unknownC05CD7(x14, x04, gameState.firstPartyMemberEntity, direction) & (SurfaceFlags.solid | SurfaceFlags.obscureUpperBody)) != (SurfaceFlags.solid | SurfaceFlags.obscureUpperBody)) {
			break;
		}
		if (unknownC3E148[direction] != 0) {
			x14 += ((unknownC3E148[direction] & 0x8000) != 0) ? -8 : 8;
		}
		if (unknownC3E158[direction] != 0) {
			x04 += ((unknownC3E158[direction] & 0x8000) != 0) ? -8 : 8;
		}
	}
	playerIntangibilityFrames = x12;
	if ((interactingNPCID == 0) || (interactingNPCID == -1)) {
		unknownC065C2(direction);
	}
	return interactingNPCID;
}

/// $C043BC
short unknownC043BC() {
	short x10 = cast(short)(gameState.leaderDirection & 0xFFFE);
	short a = unknownC042EF(cast(short)(gameState.leaderDirection & 0xFFFE));
	if ((a != -1) && (a != 0)) {
		return cast(short)(gameState.leaderDirection & 0xFFFE);
	}
	gameState.leaderDirection = (((gameState.leaderDirection & 0xFFFE) + 2) & 7);
	a = unknownC042EF(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return cast(short)(gameState.leaderDirection & 0xFFFE);
	}
	gameState.leaderDirection = ((gameState.leaderDirection + 4) & 7);
	a = unknownC042EF(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return cast(short)(gameState.leaderDirection & 0xFFFE);
	}
	gameState.leaderDirection = ((gameState.leaderDirection - 2) & 7);
	a = unknownC042EF(gameState.leaderDirection);
	if ((a != -1) && (a != 0)) {
		return cast(short)(gameState.leaderDirection & 0xFFFE);
	}
	gameState.leaderDirection = x10;
	return -1;
}

/// $C04452
ushort findNearbyTalkableTPTEntry() {
	interactingNPCID = -1;
	interactingNPCEntity = -1;
	short x10 = unknownC043BC();
	if ((x10 != -1) && (entityDirections[gameState.firstPartyMemberEntity] != x10)) {
		gameState.leaderDirection = x10;
		entityDirections[gameState.firstPartyMemberEntity] = x10;
		updateEntitySpriteFrame(gameState.firstPartyMemberEntity);
	}
	return interactingNPCID;
}

/// $C0449B
void handleNormalMovement() {
	gameState.leaderHasMoved = 0;
	if (mushroomizedWalkingFlag != 0) {
		mushroomizationMovementSwap();
	}
	short chosenDirection = mapInputToDirection(gameState.walkingStyle);
	if (battleSwirlCountdown != 0) {
		if (--battleSwirlCountdown != 0) {
			npcCollisionCheck(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
		} else {
			battleMode = BattleMode.inBattle;
		}
		return;
	}
	if (chosenDirection == -1) {
		npcCollisionCheck(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
		return;
	}
	if (gameState.walkingStyle == WalkingStyle.stairs) {
		if ((stairsDirection == StairDirection.upRight) || (stairsDirection == StairDirection.downLeft)) {
			if (chosenDirection <= Direction.downRight) {
				chosenDirection = Direction.upRight;
			} else {
				chosenDirection = Direction.downLeft;
			}
		} else {
			if (((chosenDirection - 1) & 7) <= Direction.downRight) {
				chosenDirection = Direction.downRight;
			} else {
				chosenDirection = Direction.upLeft;
			}
		}
		if (chosenDirection < Direction.down) {
			gameState.leaderDirection = Direction.right;
		} else {
			gameState.leaderDirection = Direction.left;
		}
	} else if ((playerMovementFlags & PlayerMovementFlags.dontChangeDirection) == 0) {
		gameState.leaderDirection = chosenDirection;
	}
	playerHasMovedSinceMapLoad++;
	gameState.leaderHasMoved++;
	short x22 = gameState.troddenTileType;
	FixedPoint1616 newX = { combined: adjustPositionHorizontal(chosenDirection, gameState.leaderX.combined, x22) };
	FixedPoint1616 newY = { combined: adjustPositionVertical(chosenDirection, gameState.leaderY.combined, x22) };
	ladderStairsTileX = 0xFFFF;
	short x04;
	if ((playerMovementFlags & PlayerMovementFlags.collisionDisabled) == 0) {
		x04 = checkMovementMapCollision(newX.integer, newY.integer, gameState.firstPartyMemberEntity, chosenDirection);
		if (chosenDirection != finalMovementDirection) {
			newX.combined = adjustPositionHorizontal(finalMovementDirection, gameState.leaderX.combined, x22);
			newY.combined = adjustPositionVertical(finalMovementDirection, gameState.leaderY.combined, x22);
		}
	} else if (demoFramesLeft == 0) {
		x04 = unknownC05FD1(newX.integer, newY.integer, gameState.firstPartyMemberEntity) & 0x3F;
	} else {
		x04 = 0;
	}
	gameState.troddenTileType = x04;
	short x02_2 = 1;
	npcCollisionCheck(newX.integer, newY.integer, gameState.firstPartyMemberEntity);
	if (entityCollidedObjects[partyLeaderEntity] != 0xFFFF) {
		x02_2 = 0;
	}
	if ((x04 & 0xC0) != 0) {
		x02_2 = 0;
	}
	if (ladderStairsTileX != 0xFFFF) {
		x02_2 = unknownC07526(ladderStairsTileX, ladderStairsTileY);
	} else if ((gameState.walkingStyle == WalkingStyle.ladder) || (gameState.walkingStyle == WalkingStyle.rope)) {
		gameState.walkingStyle = WalkingStyle.normal;
	}
	if (x02_2 != 0) {
		gameState.leaderX = newX;
		gameState.leaderY = newY;
	} else {
		gameState.leaderHasMoved = 0;
	}
	if (((frameCounter & 1) == 0) && (activeHotspots[0].mode != 0)) {
		unknownC073C0(0);
	}
	if (((frameCounter & 1) != 0) && (activeHotspots[1].mode != 0)) {
		unknownC073C0(1);
	}
	if ((gameState.walkingStyle == WalkingStyle.ladder) || (gameState.walkingStyle == WalkingStyle.rope)) {
		gameState.leaderX.integer = cast(short)((ladderStairsTileX * 8) + 8);
	}
	if ((debugging != 0) && ((padState[0] & Pad.x) != 0)) {
		gameState.leaderX.integer &= 0xFFF8;
		gameState.leaderY.integer &= 0xFFF8;
	}
}

/// $C0476D
void moveCameraToEntity() {
	short x04 = 0;
	if ((entityAbsXTable[cameraFocusEntity] != gameState.leaderX.integer) || (entityAbsYTable[cameraFocusEntity] != gameState.leaderY.integer) || (entityAbsXFractionTable[cameraFocusEntity] != gameState.leaderX.fraction) || (entityAbsYFractionTable[cameraFocusEntity] != gameState.leaderY.fraction)) {
		x04 = 1;
	}
	gameState.leaderX.integer = entityAbsXTable[cameraFocusEntity];
	gameState.leaderY.integer = entityAbsYTable[cameraFocusEntity];
	gameState.leaderX.fraction = entityAbsXFractionTable[cameraFocusEntity];
	gameState.leaderY.fraction = entityAbsYFractionTable[cameraFocusEntity];
	gameState.leaderDirection = entityDirections[cameraFocusEntity];
	gameState.leaderHasMoved = x04;
}

/// $C047CF
void handleEscalatorMovement() {
	if (enemyHasBeenTouched != 0) {
		return;
	}
	if (battleSwirlCountdown != 0) {
		battleSwirlCountdown--;
		return;
	}
	short direction;
	switch (escalatorEntranceDirection & 0x300) {
		case StairDirection.upLeft:
			direction = Direction.upLeft;
			break;
		case StairDirection.downLeft:
			direction = Direction.downLeft;
			break;
		case StairDirection.upRight:
			direction = Direction.upRight;
			break;
		case StairDirection.downRight:
			direction = Direction.downRight;
			break;
		default:
			break;
	}
	ladderStairsTileX = 0xFFFF;
	checkMovementMapCollision(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity, direction);
	if (ladderStairsTileX != -1) {
		unknownC07526(ladderStairsTileX, ladderStairsTileY);
	}
	if (1 != 0) { //wat
		gameState.leaderX.combined += horizontalMovementSpeeds[WalkingStyle.escalator].directionSpeeds[direction * 4].combined;
		gameState.leaderY.combined += verticalMovementSpeeds[WalkingStyle.escalator].directionSpeeds[direction * 4].combined;
	}
	gameState.leaderHasMoved = 1;
}

/// $C048D3
void handleBicycleMovement(short arg1) {
	FixedPoint1616 x10;
	FixedPoint1616 x14;
	short x1E = mapInputToDirection(gameState.walkingStyle);
	short x02 = x1E;
	if (battleSwirlCountdown != 0) {
		if (--battleSwirlCountdown != 0) {
			npcCollisionCheck(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
			return;
		} else {
			battleMode = BattleMode.inBattle;
			return;
		}
	}
	if ((padPress[0] & Pad.r) != 0) {
		playSfx(Sfx.bicycleBell);
	}
	if (x1E == -1) {
		if (arg1 != 0) {
			x1E = gameState.leaderDirection;
		} else {
			npcCollisionCheck(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
			return;
		}
	}
	if ((x1E & 1) != 0) {
		bicycleDiagonalTurnCounter = 4;
	} else if (bicycleDiagonalTurnCounter != 0) {
		if (--bicycleDiagonalTurnCounter != 0) {
			x1E = gameState.leaderDirection;
		} else if (x02 == -1) {
			x1E = gameState.leaderDirection;
		}
	}
	gameState.leaderDirection = x1E;
	x10.combined = gameState.leaderX.combined + horizontalMovementSpeeds[WalkingStyle.bicycle].directionSpeeds[x1E].combined;
	x14.combined = gameState.leaderY.combined + verticalMovementSpeeds[WalkingStyle.bicycle].directionSpeeds[x1E].combined;
	ladderStairsTileX = 0xFFFF;
	short x1A = unknownC05CD7(x10.integer, x14.integer, 0x18, x1E);
	npcCollisionCheck(x10.integer, x14.integer, gameState.firstPartyMemberEntity);
	if (entityCollidedObjects[partyLeaderEntity] == -1) {
		gameState.leaderHasMoved++;
		playerHasMovedSinceMapLoad++;
		if ((x1A & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
			gameState.leaderHasMoved = 0;
		} else {
			gameState.leaderX.combined = x10.combined;
			gameState.leaderY.combined = x14.combined;
		}
	}
}

/// $C04A7B
void restoreCameraMode() {
	gameState.cameraMode = cameraModeBackup;
	unknownC0D19B();
}

/// $C04A88
void switchToCameraMode3() {
	cameraMode3FramesLeft = 12;
	cameraModeBackup = gameState.cameraMode;
	gameState.cameraMode = CameraMode.unknown3;
	musicEffect(MusicEffect.quickFade);
	overworldStatusSuppression = 1;
}

/// $C04AAD
void unknownC04AAD() {
	if (--cameraMode3FramesLeft != 0) {
		short x10 = mapInputToDirection(gameState.walkingStyle);
		if (x10 == -1) {
			return;
		}
		for (short i = 0x18; i <= 0x1D; i++) {
			if (entityScriptTable[i] == -1) {
				continue;
			}
			if (entityDirections[i] == x10) {
				continue;
			}
			currentPartyMemberTick = &partyCharacters[entityScriptVar1Table[i]];
			if ((playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle == WalkingStyle.rope) || (playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle == WalkingStyle.ladder)) {
				continue;
			}
			entityDirections[i] = x10;
			updateEntitySpriteFrame(i);
		}
		gameState.leaderDirection = x10;
	} else {
		restoreCameraMode();
	}
}

/// $C04B53
void handleSpecialCamera() {
	short x10;
	if (gameState.walkingStyle != WalkingStyle.stairs) {
		x10 = gameState.leaderDirection;
	} else {
		x10 = autoMovementDirection;
	}
	switch (gameState.cameraMode) {
		case CameraMode.autoScroll:
			gameState.leaderX.combined += horizontalMovementSpeeds[gameState.walkingStyle].directionSpeeds[x10].combined;
			gameState.leaderY.combined += verticalMovementSpeeds[gameState.walkingStyle].directionSpeeds[x10].combined;
			if (--gameState.autoScrollFrames == 0) {
				gameState.cameraMode = CameraMode.normal;
				gameState.walkingStyle = gameState.autoScrollOriginalWalkingStyle;
			}
			gameState.leaderHasMoved = 1;
			break;
		case CameraMode.followEntity:
			moveCameraToEntity();
			break;
		case CameraMode.unknown3:
			unknownC04AAD();
			break;
		default:
			break;
	}
}

/// $C04C45
void unknownC04C45() {
	short x14 = gameState.leaderHasMoved;
	gameState.leaderHasMoved = 0;
	if (playerIntangibilityFrames != 0) {
		playerIntangibilityFlash();
		playerIntangibilityFrames--;
	}
	if ((debugging != 0) && ((padState[0] & Pad.x) != 0) && ((frameCounter & 0xF) != 0)) {
		return;
	}
	chosenFourPtrs[entityScriptVar1Table[gameState.firstPartyMemberEntity]].positionIndex = gameState.leaderPositionIndex;
	if (gameState.cameraMode != CameraMode.normal) {
		handleSpecialCamera();
	} else {
		switch (gameState.walkingStyle) {
			case WalkingStyle.escalator:
				handleEscalatorMovement();
				break;
			case WalkingStyle.bicycle:
				handleBicycleMovement(x14);
				break;
			default:
				handleNormalMovement();
				break;
		}
	}
	short x12 = gameState.leaderPositionIndex;
	PlayerPositionBufferEntry* x10 = &playerPositionBuffer[gameState.leaderPositionIndex];
	gameState.troddenTileType = unknownC05F82(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
	if (gameState.leaderHasMoved != 0) {
		x10.xCoord = gameState.leaderX.integer;
		x10.yCoord = gameState.leaderY.integer;
		gameState.leaderPositionIndex = (x12 + 1) & 0xFF;
		centerScreen(gameState.leaderX.integer, gameState.leaderY.integer);
		unread7E4DD4 = 1;
	} else {
		unread7E4DD4 = 0;
	}
	x10.tileFlags = gameState.troddenTileType;
	x10.walkingStyle = gameState.walkingStyle;
	x10.direction = gameState.leaderDirection;
	footstepSoundIDOverride = 0;
	if ((gameState.troddenTileType & 8) != 0) {
		if ((gameState.troddenTileType & 4) != 0) {
			footstepSoundIDOverride = 0x10;
		} else {
			footstepSoundIDOverride = 0x12;
		}
	}
}

/// $C04D78
void partyMemberTick() {
	if (gameState.cameraMode == CameraMode.unknown3) {
		return;
	}
	if (battleSwirlCountdown != 0) {
		return;
	}
	if (enemyHasBeenTouched != 0) {
		return;
	}
	if (battleMode != BattleMode.noBattle) {
		return;
	}
	currentPartyMemberTick = chosenFourPtrs[entityScriptVar1Table[currentEntitySlot]];
	entityDirections[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].direction;
	entitySurfaceFlags[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].tileFlags;
	doPartyMovementFrame(entityScriptVar0Table[currentEntitySlot], playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle, currentEntitySlot);
	if (gameState.leaderHasMoved == 0) {
		if (playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle != WalkingStyle.escalator) {
			return;
		}
	}
	entityAbsXTable[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].xCoord;
	entityAbsYTable[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].yCoord;
	short x1C = 0;
	short x12 = void;
	if (entityScriptVar0Table[currentEntitySlot] + 1 != gameState.partyMemberIndex[0]) {
		switch (playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle) {
			case WalkingStyle.ladder:
			case WalkingStyle.rope:
				x12 = 0x1E;
				break;
			case WalkingStyle.escalator:
				if (gameState.walkingStyle == WalkingStyle.normal) {
					x1C = 0x1;
				} else {
					x12 = 0x1E;
				}
				break;
			case WalkingStyle.stairs:
				x12 = 0x18;
				break;
			default:
				if (gameState.specialGameState == SpecialGameState.useMiniSprites) {
					x12 = 0x8;
				} else {
					x12 = 0xC;
				}
				break;
		}
	}
	currentPartyMemberTick.unknown65 = playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle;
	short x1A;
	if ((entityScriptVar0Table[currentEntitySlot] + 1 != gameState.partyMemberIndex[0]) && (x1C == 0)) {
		//uh oh, x12 may not have been initialized
		x1A = getNewPositionIndex(entityScriptVar0Table[currentEntitySlot], cast(short)(characterSizes[entityScriptVar0Table[currentEntitySlot]] + x12), currentPartyMemberTick.positionIndex, 2);
	} else {
		x1A = cast(short)(currentPartyMemberTick.positionIndex + 1);
		entityScriptVar7Table[currentEntitySlot] &= ~PartyMemberMovementFlags.unknown12;
	}
	currentPartyMemberTick.positionIndex = x1A & 0xFF;
}

/// $C04EF0
void unknownC04EF0() {
	currentPartyMemberTick = chosenFourPtrs[entityScriptVar1Table[currentEntitySlot]];
	entityDirections[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].direction;
	entitySurfaceFlags[currentEntitySlot] = playerPositionBuffer[currentPartyMemberTick.positionIndex].tileFlags;
	doPartyMovementFrame(entityScriptVar0Table[currentEntitySlot], playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle, currentEntitySlot);
}

/// $C04F47
void restoreBackgroundLayers() {
	palettes[0][0] = backgroundColourBackup;
	// re-enable BG1, 2, 3 and OBJ
	mirrorTM = TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1;
	preparePaletteUpload(PaletteUpload.halfFirst);
}

/// $C04F60
void redFlash() {
	if (battleSwirlCountdown != 0) {
		return;
	}
	if (enemyHasBeenTouched != 0) {
		return;
	}
	backgroundColourBackup = palettes[0][0];
	// set background colour to red
	palettes[0][0] = 0x1F;
	// turn off all layers
	mirrorTM = TMTD.none;
	preparePaletteUpload(PaletteUpload.halfFirst);
	scheduleOverworldTask(1, &restoreBackgroundLayers);
}

/// $C04F9F
void tryShowHPAlert(short arg1) {
	short x10 = arg1;
	PartyCharacter* x0E = chosenFourPtrs[gameState.playerControlledPartyMembers[x10]];
	if ((x0E.maxHP * 20) / 100 > x0E.hp.current.integer) {
		if (hpAlertShown[x10] == 0) {
			showHPAlert(cast(short)(x0E.characterID + 1));
		}
		hpAlertShown[x10] = 1;
	} else {
		hpAlertShown[x10] = 0;
	}
}

/// $C04FFE
ushort unknownC04FFE() {
	ushort result = 0;
	ushort x02;
	ushort x04;
	ushort numberCollapsed;
	if (gameState.cameraMode == CameraMode.followEntity) {
		return 1;
	}
	if (overworldStatusSuppression != 0) {
		return 1;
	}
	for(x02 = 0; (gameState.partyMemberIndex[x02] != 0) && (gameState.partyMemberIndex[x02] <= 4); x02++) {
		currentPartyMemberTick = chosenFourPtrs[gameState.playerControlledPartyMembers[x02]];
		const affliction = currentPartyMemberTick.afflictions[0];
		if ((affliction == Status0.unconscious) || (affliction == Status0.diamondized)) {
			continue;
		}
		if (affliction == Status0.poisoned) {
			if (overworldDamageCountdownFrames[x02] == 0) {
				overworldDamageCountdownFrames[x02] = 120;
			} else if (!--overworldDamageCountdownFrames[x02]) {
				x04++;
				currentPartyMemberTick.hp.current.integer -= 10;
				currentPartyMemberTick.hp.target -= 10;
				tryShowHPAlert(x02);
			}
		} else if (((affliction < Status0.nauseous) && ((gameState.troddenTileType & SurfaceFlags.deepWater) == SurfaceFlags.deepWater)) || ((affliction >= Status0.nauseous) && (affliction <= Status0.cold))) {
			if (overworldDamageCountdownFrames[x02] == 0) {
				if (affliction == Status0.nauseous) {
					overworldDamageCountdownFrames[x02] = 120;
				} else {
					overworldDamageCountdownFrames[x02] = 240;
				}
			} else if (!--overworldDamageCountdownFrames[x02]) {
				x04++;
				if (affliction == Status0.nauseous) {
					currentPartyMemberTick.hp.current.integer -= 10;
					currentPartyMemberTick.hp.target -= 10;
				} else { //cold or deep water
					currentPartyMemberTick.hp.current.integer -= 2;
					currentPartyMemberTick.hp.target -= 2;
				}
				tryShowHPAlert(x02);
			}
		}
		if (currentPartyMemberTick.hp.current.integer <= 0) {
			if (affliction != Status0.unconscious) {
				for (short i = 0; i < 6; i++) {
					currentPartyMemberTick.afflictions[i] = 0;
				}
				currentPartyMemberTick.afflictions[0] = Status0.unconscious;
				currentPartyMemberTick.hp.target = 0;
				currentPartyMemberTick.hp.current.integer = 0;
				entityScriptVar3Table[currentPartyMemberTick.unknown59] = 0x10;
				numberCollapsed++;
			}
		} else {
			if (affliction != Status0.diamondized) {
				result += currentPartyMemberTick.hp.current.integer;
			}
		}
	}
	if (x04 != 0) {
		redFlash();
	}
	if (numberCollapsed != 0) {
		partyMembersAliveOverworld = 0;
		updateParty();
		unknownC07B52();
		unfreezeEntities();
	}
	return result;
}

/// $C05200
void partyLeaderTick() {
	if (battleMode != BattleMode.noBattle) {
		return;
	}
	if ((possessedPlayerCount == 0) && (miniGhostEntityID != -1)) {
		unknownC07716();
	} else if (miniGhostEntityID != -1) {
		unknownC0777A();
	}
	if (loadedAnimatedTileCount != 0) {
		animateTileset();
	}
	if (mapPaletteAnimationLoaded != 0) {
		animatePalette();
	}
	if (itemTransformationsLoaded != 0) {
		processItemTransformations();
	}
	unknownC04C45();
	const x = gameState.leaderX.integer >> 8;
	const y = gameState.leaderY.integer >> 8;
	if (((x^lastSectorX) != 0) || ((y^lastSectorY) != 0)) {
		lastSectorX = x;
		lastSectorY = y;
		if (enableAutoSectorMusicChanges) {
			doSectorMusicUpdate();
		}
	}
	if ((dadPhoneTimer == 0) && (gameState.cameraMode != CameraMode.followEntity)) {
		loadDadPhone();
	}
	possessedPlayerCount = 0;
	currentLeaderDirection = gameState.leaderDirection;
	currentLeadingPartyMemberEntity = cast(short)(gameState.firstPartyMemberEntity * 2);
	if (gameState.leaderHasMoved) {
		playerHasDoneSomethingThisFrame = 1;
	}
}

/// $C052AA
short initBattleCommon() {
	fadeOutWithMosaic(1, 1, 0);
	short result = battleRoutine();
	updateParty();
	partyMembersAliveOverworld = 1;
	battleMode = BattleMode.noBattle;
	return result;
}

/// $C052D4
void unknownC052D4(short arg1) {
	short x26 = 0xFF;
	gameState.leaderPositionIndex = 0xFF;
	short x24 = gameState.leaderX.integer;
	short x22 = gameState.leaderY.integer;
	short x20 = gameState.troddenTileType;
	short x1E = gameState.walkingStyle;
	FixedPoint1616 x12 = { combined: adjustPositionHorizontal((arg1 + 4) & 7, gameState.leaderX.combined, gameState.troddenTileType) - gameState.leaderX.combined };
	FixedPoint1616 x16 = { combined: adjustPositionVertical((arg1 + 4) & 7, gameState.leaderY.combined, gameState.troddenTileType) - gameState.leaderY.combined };
	short x1C = 0x100;
	while(x1C != 0) {
		x1C--;
		playerPositionBuffer[x1C].xCoord = x24;
		playerPositionBuffer[x1C].yCoord = x22;
		playerPositionBuffer[x1C].tileFlags = x20;
		playerPositionBuffer[x1C].walkingStyle = x1E;
		playerPositionBuffer[x1C].direction = arg1;
		playerPositionBuffer[x1C].unknown10 = 0;
		x24 += x12.integer;
		x22 += x16.integer;
	}
	for (short i = 0; i < gameState.partyCount; i++) {
		partyCharacters[gameState.playerControlledPartyMembers[i]].positionIndex = x26;
		partyCharacters[gameState.playerControlledPartyMembers[i]].unknown65 = 0xFFFF;
		partyCharacters[gameState.playerControlledPartyMembers[i]].unknown55 = 0xFFFF;
		entityAbsXTable[gameState.partyEntities[i]] = playerPositionBuffer[x26].xCoord;
		entityAbsYTable[gameState.partyEntities[i]] = playerPositionBuffer[x26].yCoord;
		entityDirections[gameState.partyEntities[i]] = playerPositionBuffer[x26].direction;
		entitySurfaceFlags[gameState.partyEntities[i]] = playerPositionBuffer[x26].tileFlags;
		x26 -= 16;
	}
}

/// $C0546B
short unknownC0546B() {
	short x10 = 0;
	for (short i = 0; i != gameState.partyCount; i++) {
		if (gameState.partyMemberIndex[i] > 4) {
			continue;
		}
		x10 += partyCharacters[gameState.partyMemberIndex[i]].level;
	}
	return x10;
}

/// $C054C9
short getCollisionAt(short x, short y) {
	short result = loadedCollisionTiles[y & 0x3F][x & 0x3F];
	if ((result & SurfaceFlags.ladderOrStairs) != 0) {
		ladderStairsTileX = x;
		ladderStairsTileY = y;
	}
	return result;
}

/// $C05503
void checkVerticalUpTileCollision(short arg1, short arg2) {
	ushort x10 = cast(ushort)(loadedCollisionTiles[(checkedCollisionTopY / 8) & 0x3F][(arg1 / 8) & 0x3F] | tempEntitySurfaceFlags);
	short x14 = (arg1 + 7) / 8;
	for (short i = 0; i < hitboxWidths[arg2]; i++) {
		x10 |= loadedCollisionTiles[(checkedCollisionTopY / 8) & 0x3F][x14 & 0x3F];
		x14++;
	}
	tempEntitySurfaceFlags = x10;
}

/// $C0559C
void checkVerticalDownTileCollision(short arg1, short arg2) {
	ushort y = cast(ushort)(loadedCollisionTiles[((((hitboxHeights[arg2] * 8) + checkedCollisionTopY - 1) / 8) & 0x3F)][(arg1 / 8) & 0x3F] | tempEntitySurfaceFlags);
	short x12 = (arg1 + 7) / 8;
	for (short i = 0; i < hitboxWidths[arg2]; i++) {
		y |= loadedCollisionTiles[(((hitboxHeights[arg2] * 8) + checkedCollisionTopY - 1) / 8) & 0x3F][x12 & 0x3F];
		x12++;
	}
	tempEntitySurfaceFlags = y;
}

/// $C05639
void checkHorizontalLeftTileCollision(short arg1, short arg2) {
	ushort x10 = cast(ushort)(loadedCollisionTiles[(arg1 / 8) & 0x3F][(checkedCollisionLeftX / 8) & 0x3F] | tempEntitySurfaceFlags);
	short x12 = (arg1 + 7) / 8;
	for (short i = 0; i < hitboxHeights[arg2]; i++) {
		x10 |= loadedCollisionTiles[x12 & 0x3F][(checkedCollisionLeftX / 8) & 0x3F];
		x12++;
	}
	tempEntitySurfaceFlags = x10;
}

/// $C056D0
void checkHorizontalRightTileCollision(short arg1, short arg2) {
	ushort y = cast(ushort)(loadedCollisionTiles[(arg1 / 8) & 0x3F][(((hitboxWidths[arg2] * 8) + checkedCollisionLeftX - 1) / 8) & 0x3F] | tempEntitySurfaceFlags);
	short x12 = (arg1 + 7) / 8;
	for (short i = 0; i < hitboxHeights[arg2]; i++) {
		y |= loadedCollisionTiles[x12 & 0x3F][(((hitboxWidths[arg2] * 8) + checkedCollisionLeftX - 1) / 8) & 0x3F];
		x12++;
	}
	tempEntitySurfaceFlags = y;
}

/** Runs some collision checks. Checks the tiles at each direction specified by directionMask and returns each check that failed
 * Params:
 * 	directionMask = A set of flags indicating which directions to test. 0b000001 = west, 0b000010 = none, 0b000100 = east, 0b001000 = southwest, 0b010000 = south, 0b100000 = southeast
 * Returns: the directionMask specified, minus the bits that didn't collide
 * Original_Address: $(DOLLAR)C05769
 */
short performCollisionChecks(short directionMask) {
	short result = 0;
	short flagsCombined = 0;
	for (short i = 0; i < 6; i++, result >>= 1, directionMask >>= 1) {
		if ((directionMask & 1) == 0) {
			continue;
		}
		short flags = getCollisionAt((collisionTestCoordDiffsX[i] + checkedCollisionLeftX) / 8, (collisionTestCoordDiffsY[i] + checkedCollisionTopY) / 8);
		flagsCombined |= flags;
		if ((flags & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
			result |= 0x40;
		}
	}
	if (setTempEntitySurfaceFlags == 1) {
		tempEntitySurfaceFlags = flagsCombined;
	}
	return result;
}

/** Runs collision checks for north movement and returns whether it's possible to move northish
 * Returns: -256 if north movement impossible, -1 if possible, a similar Direction otherwise
 * Original_Address: $(DOLLAR)C057E8
 */
short checkNorthMovementMapCollision() {
	tempEntitySurfaceFlags = 0;
	setTempEntitySurfaceFlags++;
	northSouthCollisionTestResult = performCollisionChecks(0b000111); // check west, none, east
	if ((northSouthCollisionTestResult == 0b000111) || (northSouthCollisionTestResult == 0b000010)) { // E/W solid line
		return -256;
	}
	if (northSouthCollisionTestResult == 0) { // All clear
		return -1;
	}
	if (northSouthCollisionTestResult == 0b000001) { // NE/SW solid line, can move northeast alongside it
		return Direction.upRight;
	}
	if (northSouthCollisionTestResult == 0b000100) { // NW/SE solid line, can move northwest alongside it
		return Direction.upLeft;
	}
	if ((northSouthCollisionTestResult == 0b000110) && ((checkedCollisionLeftX & 7) == 0)) { // bottom-left corners of E/W and NW/SE intersections
		return Direction.upLeft;
	}
	return -1;
}

/** Runs collision checks for south movement and returns whether it's possible to move southish
 * Returns: -256 if south movement impossible, -1 if possible, a similar Direction otherwise
 * Original_Address: $(DOLLAR)C0583C
 */
short checkSouthMovementMapCollision() {
	tempEntitySurfaceFlags = 0;
	setTempEntitySurfaceFlags++;
	northSouthCollisionTestResult = performCollisionChecks(0b111000); // check southwest, south, southeast
	// shouldn't that be 0b111000?
	if ((northSouthCollisionTestResult == 0b000111) || (northSouthCollisionTestResult == 0b010000)) { // E/W solid line
		return -256;
	}
	if (northSouthCollisionTestResult == 0) { // All clear
		return -1;
	}
	if (northSouthCollisionTestResult == 0b001000) { // NW/SE solid line, can move southeast alongside it
		return Direction.downRight;
	}
	if (northSouthCollisionTestResult == 0b100000) { // NE/SW solid line, can move southwest alongside it
		return Direction.downLeft;
	}
	if ((northSouthCollisionTestResult == 0b110000) && ((checkedCollisionLeftX & 7) == 0)) { // top-left corners of E/W and NE/SW intersections
		return Direction.downLeft;
	}
	return -1;
}

/** Runs collision checks for west movement and returns whether it's possible to move westish
 * Returns: -1 if impossible, a Direction that we can move in otherwise
 * Original_Address: $(DOLLAR)C05890
 */
short checkWestMovementMapCollision() {
	short result = -1;
	short furtherWestAttempted = 0;
	short extraCollisionResult = 0;
	tempEntitySurfaceFlags = 0;
	setTempEntitySurfaceFlags = 1;
	short collisionResult = performCollisionChecks(0b001001); // check west, southwest
	if (collisionResult == 0) { // see if we can move even further west
		checkedCollisionLeftX -= 4;
		collisionResult = performCollisionChecks(0b001001); //check west, southwest again
		if (collisionResult == 0) {
			return Direction.left;
		}
		furtherWestAttempted = 1;
	}
	if (((collisionResult & 0b001001) == 0b001001) && ((checkedCollisionTopY & 7) != 0)) {
		if (furtherWestAttempted != 0) {
			// though the second check failed, we aren't at a tile boundary yet, so we can move at least a little west
			return Direction.left;
		}
		return -1;
	}
	if ((loadedCollisionTiles[((checkedCollisionTopY - 2) / 8) & 0x3F][((checkedCollisionLeftX - 4) / 8) & 0x3F] & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
		extraCollisionResult |= 0b01; // further northwest
	}
	if ((loadedCollisionTiles[((checkedCollisionTopY + 9) / 8) & 0x3F][((checkedCollisionLeftX - 4) / 8) & 0x3F] & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
		extraCollisionResult |= 0b10; // further southwest
	}
	switch (collisionResult) {
		case 0b001001:
			if (extraCollisionResult == 0b01) {
				result = Direction.downLeft; // NE/SW solid line, can move southwest alongside it
			} else if (extraCollisionResult == 0b10) {
				result = Direction.upLeft; // NW/SE solid line, can move northwest alongside it
			} else if (extraCollisionResult == 0b00) {
				if ((checkedCollisionTopY & 7) < 4) {
					result = Direction.upLeft;
				} else {
					result = Direction.downLeft;
				}
			}
			break;
		case 0b000001:
			if ((extraCollisionResult & 0b10) == 0) { // NE/SW solid line, can move alongside it
				result = Direction.downLeft;
			}
			break;
		case 0b001000:
			if ((extraCollisionResult & 0b01) == 0) {  // NW/SE solid line, can move alongside it
				result = Direction.upLeft;
			}
			break;
		default: break;
	}
	if ((furtherWestAttempted != 0) && (result == -1)) { // we're near the end of a very narrow path westward
		return Direction.left;
	}
	return result;
}

/** Runs collision checks for east movement and returns whether it's possible to move eastish
 * Returns: -1 if impossible, a Direction that we can move in otherwise
 * Original_Address: $(DOLLAR)C059EF
 */
short checkEastMovementMapCollision() {
	short result = -1;
	short furtherEastAttempted = 0;
	short extraCollisionResult = 0;
	tempEntitySurfaceFlags = 0;
	setTempEntitySurfaceFlags = 1;
	short collisionResult = performCollisionChecks(0b100100); // check east, southeast
	if (collisionResult == 0) { // see if we can move even further east
		checkedCollisionLeftX += 4;
		collisionResult = performCollisionChecks(0b100100); // check east, southeast again
		if (collisionResult == 0) {
			return Direction.right;
		}
		furtherEastAttempted = 1;
	}
	if (((collisionResult & 0b100100) == 0b100100) && ((checkedCollisionTopY & 7) != 0)) {
		if (furtherEastAttempted != 0) {
			// though the second check failed, we aren't at a tile boundary yet, so we can move at least a little west
			return Direction.right;
		}
		return -1;
	}
	if ((loadedCollisionTiles[((checkedCollisionTopY - 2) / 8) & 0x3F][((checkedCollisionLeftX + 4) / 8) & 0x3F] & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
		extraCollisionResult |= 0b01; // further northeast
	}
	if ((loadedCollisionTiles[((checkedCollisionTopY + 9) / 8) & 0x3F][((checkedCollisionLeftX + 4) / 8) & 0x3F] & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
		extraCollisionResult |= 0b10; // further southeast
	}
	switch (collisionResult) {
		case 0b100100:
			if (extraCollisionResult == 1) {
				result = Direction.downRight; // NW/SE solid line, can move southeast alongside it
			} else if (extraCollisionResult == 2) {
				result = Direction.upRight; // NE/SW solid line, can move northeast alongside it
			} else if (extraCollisionResult == 0) {
				if ((checkedCollisionTopY & 7) < 4) {
					result = Direction.upRight;
				} else {
					result = Direction.downRight;
				}
			}
			break;
		case 0b000100:
			if ((extraCollisionResult & 2) == 0) {
				result = Direction.downRight; // NW/SE solid line, can move alongside it
			}
			break;
		case 0b100000:
			if ((extraCollisionResult & 1) == 0) {
				result = Direction.upRight; // NE/SW solid line, can move alongside it
			}
			break;
		default: break;
	}
	if ((furtherEastAttempted != 0) && (result == -1)) { // we're near the end of a very narrow path eastward
		return Direction.right;
	}
	return result;
}

/// $C05B4E
short checkDiagonalMovementCollision(short direction) {
	tempEntitySurfaceFlags = 0;
	setTempEntitySurfaceFlags++;
	return (performCollisionChecks(unknownC200D1[direction / 2]) != 0) ? -256 : direction;
}

/** See if movement in a particular direction is possible and return flags
 * Original_Address: $(DOLLAR)C05B7B
 */
short checkMovementMapCollision(short x, short y, short arg3, short direction) {
	notMovingInSameDirectionFaced = 0;
	setTempEntitySurfaceFlags = 0;
	tempEntitySurfaceFlags = 0;
	finalMovementDirection = direction;
	unread7E5DA2 = direction;
	checkedCollisionLeftX = x;
	checkedCollisionTopY = y;
	short collisionResult;
	switch (direction) {
		case Direction.up:
			collisionResult = checkNorthMovementMapCollision();
			if (collisionResult != -1) {
				break;
			}
			short x10 = ladderStairsTileX;
			if ((checkedCollisionTopY & 7) < 5) {
				checkedCollisionTopY -= 4;
				short x0E = checkNorthMovementMapCollision();
				if ((x0E & 0xFF00) != 0xFF00) {
					collisionResult = x0E;
				}
			}
			ladderStairsTileX = x10;
			break;
		case Direction.down:
			collisionResult = checkSouthMovementMapCollision();
			if (collisionResult != -1) {
				break;
			}
			short x10 = ladderStairsTileX;
			if ((checkedCollisionTopY & 7) > 3) {
				checkedCollisionTopY += 4;
				short x0E = checkSouthMovementMapCollision();
				if ((x0E & 0xFF00) != 0xFF00) {
					collisionResult = x0E;
				}
			}
			ladderStairsTileX = x10;
			break;
		case Direction.left:
			collisionResult = checkWestMovementMapCollision();
			break;
		case Direction.right:
			collisionResult = checkEastMovementMapCollision();
			break;
		case Direction.upLeft:
		case Direction.upRight:
		case Direction.downLeft:
		case Direction.downRight:
			collisionResult = checkDiagonalMovementCollision(direction);
			if (collisionResult != -256) {
				collisionResult = direction;
			}
			break;
		default: break;
	}
	if (pendingInteractions != 0) {
		ladderStairsTileX = 0xFFFF;
	}
	if ((collisionResult == -1) || (collisionResult == -256)) {
		return tempEntitySurfaceFlags;
	}
	notMovingInSameDirectionFaced = (collisionResult != direction) ? 1 : 0;
	finalMovementDirection = collisionResult;
	return tempEntitySurfaceFlags & 0x3F;
}

/// $C05CD7
short unknownC05CD7(short arg1, short arg2, short arg3, short direction) {
	tempEntitySurfaceFlags = 0;
	checkedCollisionLeftX = cast(short)(arg1 - unknownC42A1F[entitySizes[arg3]]);
	checkedCollisionTopY = cast(short)(arg2 - unknownC42A41[entitySizes[arg3]] + unknownC42AEB[entitySizes[arg3]]);
	switch(direction) {
		case Direction.upRight:
			checkHorizontalRightTileCollision(checkedCollisionTopY, entitySizes[arg3]);
			goto case;
		case Direction.up:
			checkVerticalUpTileCollision(checkedCollisionLeftX, entitySizes[arg3]);
			break;
		case Direction.downRight:
			checkVerticalDownTileCollision(checkedCollisionLeftX, entitySizes[arg3]);
			goto case;
		case Direction.right:
			checkHorizontalRightTileCollision(checkedCollisionTopY, entitySizes[arg3]);
			break;
		case Direction.downLeft:
			checkHorizontalLeftTileCollision(checkedCollisionTopY, entitySizes[arg3]);
			goto case;
		case Direction.down:
			checkVerticalDownTileCollision(checkedCollisionLeftX, entitySizes[arg3]);
			break;
		case Direction.upLeft:
			checkVerticalUpTileCollision(checkedCollisionLeftX, entitySizes[arg3]);
			goto case;
		case Direction.left:
			checkHorizontalLeftTileCollision(checkedCollisionTopY, entitySizes[arg3]);
			break;
		default: break;
	}
	return tempEntitySurfaceFlags;
}

/// $C05D8B
short getCollisionFlags(short x, short y, short size) {
	short x0E = cast(short)(x - unknownC42A1F[size]);
	checkedCollisionLeftX = x0E;
	checkedCollisionTopY = cast(short)(y - unknownC42A41[size] + unknownC42AEB[size]);
	checkVerticalUpTileCollision(x0E, size);
	checkVerticalDownTileCollision(checkedCollisionLeftX, size);
	checkHorizontalLeftTileCollision(checkedCollisionTopY, size);
	checkHorizontalRightTileCollision(checkedCollisionTopY, size);
	return tempEntitySurfaceFlags;
}

/// $C05DE7
short unknownC05DE7(short arg1, short arg2, short arg3) {
	short x = 0;
	switch (arg1 & 0xC) {
		case 0:
			x = EnemyMovementFlags.canMoveOnLand;
			break;
		case SurfaceFlags.causesSunstroke:
			x = EnemyMovementFlags.canMoveInHeat;
			break;
		case SurfaceFlags.shallowWater:
		case SurfaceFlags.deepWater:
			x = EnemyMovementFlags.canMoveInWater;
			break;
		default: break;
	}
	if ((enemyConfigurationTable[arg3].enemyMovementFlags & x) != 0) {
		return 0;
	}
	return SurfaceFlags.solid;
}

/// $C05E3B
short unknownC05E3B(short arg1) {
	if (testEntityMovementActive() == 0) {
		return -256;
	}
	entityObstacleFlags[arg1] = unknownC05CD7(entityMovementProspectX, entityMovementProspectY, arg1, entityDirections[arg1]) & (SurfaceFlags.solid | SurfaceFlags.unknown2 | SurfaceFlags.ladderOrStairs);
	return entityObstacleFlags[arg1];
}

/// $C05E76
short unknownC05E76() {
	return cast(ubyte)unknownC05E3B(currentEntitySlot);
}

/// $C05E82
short unknownC05E82() {
	short x0E = unknownC05E3B(currentEntitySlot);
	if (x0E == -256) {
		return 0;
	}
	if (x0E != 0) {
		return 0;
	}
	short x04 = unknownC05DE7(x0E, currentEntitySlot, entityEnemyIDs[currentEntitySlot]);
	entityObstacleFlags[currentEntitySlot] |= x04;
	return x04;
}

/// $C05ECE
short unknownC05ECE() {
	if (testEntityMovementActive() == 0) {
		return 0;
	}
	short x02 = unknownC05F82(entityMovementProspectX, entityMovementProspectY, currentEntitySlot) & 0xD0;
	entityObstacleFlags[currentEntitySlot] = x02;
	if (x02 != 0) {
		return 0;
	}
	ushort tmp = x02 | unknownC05DE7(x02, currentEntitySlot, entityEnemyIDs[currentEntitySlot]);
	entityObstacleFlags[currentEntitySlot] = tmp;
	return tmp;
}

/// $C05F33
short getSurfaceFlags(short x, short y, short entityID) {
	const size = entitySizes[entityID];
	tempEntitySurfaceFlags = 0;
	checkedCollisionLeftX = cast(short)(x - unknownC42A1F[size]);
	checkedCollisionTopY = cast(short)(y - unknownC42A41[size] + unknownC42AEB[size]);
	checkHorizontalLeftTileCollision(checkedCollisionTopY, size);
	checkHorizontalRightTileCollision(checkedCollisionTopY, size);
	return tempEntitySurfaceFlags;
}

/// $C05F82
short unknownC05F82(short x, short y, short entityID) {
	tempEntitySurfaceFlags = 0;
	const size = entitySizes[entityID];
	checkedCollisionTopY = cast(short)(y - unknownC42A41[size] + unknownC42AEB[size]);
	checkedCollisionLeftX = cast(short)(x + unknownC42A1F[size]);
	checkVerticalUpTileCollision(checkedCollisionLeftX, size);
	checkVerticalDownTileCollision(checkedCollisionLeftX, size);
	return tempEntitySurfaceFlags;
}

/// $C05FD1
short unknownC05FD1(short arg1, short arg2, short arg3) {
	tempEntitySurfaceFlags = 0;
	tempEntitySurfaceFlags = getCollisionAt(arg1 / 8, (arg2 + 4) / 8);
	return tempEntitySurfaceFlags;
}

/// $C05FF6
short npcCollisionCheck(short x, short y, short arg3) {
	short result = -1;
	if ((entityHitboxEnabled[arg3] != 0) && ((playerMovementFlags & PlayerMovementFlags.collisionDisabled) == 0) && (gameState.walkingStyle != WalkingStyle.escalator) && (demoFramesLeft == 0)) {
		short x18;
		short x04;
		if ((entityDirections[arg3] == Direction.right) || (entityDirections[arg3] == Direction.left)) {
			x18 = entityHitboxLeftRightWidth[arg3];
			x04 = entityHitboxLeftRightHeight[arg3];
		} else {
			x18 = entityHitboxUpDownWidth[arg3];
			x04 = entityHitboxUpDownHeight[arg3];
		}
		x -= x18;
		y -= x04;
		for (short i = 0; i != partyLeaderEntity; i++) {
			if (entityScriptTable[i] == -1) {
				continue;
			}
			if (entityCollidedObjects[i] == 0x8000) {
				continue;
			}
			if ((playerIntangibilityFrames != 0) && (entityNPCIDs[i] + 1 >= 0x8001)){
				continue;
			}
			if (entityHitboxEnabled[i] == 0) {
				continue;
			}
			short yReg;
			short x10;
			if ((entityDirections[i] == Direction.right) || (entityDirections[i] == Direction.left)) {
				yReg = entityHitboxLeftRightWidth[i];
				x10 = entityHitboxLeftRightHeight[i];
			} else {
				yReg = entityHitboxUpDownWidth[i];
				x10 = entityHitboxUpDownHeight[i];
			}
			if (entityAbsYTable[i] - x10 - x04 >= y) {
				continue;
			}
			if (x10 + entityAbsYTable[i] - x10 <= y) {
				continue;
			}
			if (entityAbsXTable[i] - yReg - x18 * 2 >= x) {
				continue;
			}
			if (entityAbsXTable[i] - yReg + yReg * 2 <= x) {
				continue;
			}
			result = i;
			break;
		}

	}
	entityCollidedObjects[partyLeaderEntity] = result;
	return result;
}

/// $C0613C
void unknownC0613C(short arg1, short arg2, short arg3) {
	ushort x1A = 0xFFFF;
	if (entityHitboxEnabled[arg3] != 0) {
		short x18;
		short x04;
		if ((entityDirections[arg3] == Direction.right) || (entityDirections[arg3] == Direction.left)) {
			x18 = entityHitboxLeftRightWidth[arg3];
			x04 = entityHitboxLeftRightHeight[arg3];
		} else {
			x18 = entityHitboxUpDownWidth[arg3];
			x04 = entityHitboxUpDownHeight[arg3];
		}
		short x16 = cast(short)(arg1 - x18);
		short x14 = cast(short)(x18 * 2);
		short x1C = cast(short)(arg2 - x04);
		for (short i = 0; i < maxEntities; i++) {
			if (i == arg3) {
				continue;
			}
			if (i == partyLeaderEntity) {
				continue;
			}
			if (entityScriptTable[i] == -1) {
				continue;
			}
			if (entityCollidedObjects[i] == 0x8000) {
				continue;
			}
			if (entityHitboxEnabled[i] == 0) {
				continue;
			}
			short y;
			short x10;
			if ((entityDirections[i] == Direction.right) || (entityDirections[i] == Direction.left)) {
				y = entityHitboxLeftRightWidth[i];
				x10 = entityHitboxLeftRightHeight[i];
			} else {
				y = entityHitboxUpDownWidth[i];
				x10 = entityHitboxUpDownHeight[i];
			}
			if (entityAbsYTable[i] - x10 - x04 >= x1C) {
				continue;
			}
			if (x10 + entityAbsYTable[i] - x10 <= x1C) {
				continue;
			}
			if (entityAbsXTable[i] - y - x14 >= x16) {
				continue;
			}
			if (entityAbsXTable[i] - y + y * 2 <= x16) {
				continue;
			}
			x1A = i;
			break;
		}
	}
	entityCollidedObjects[arg3] = x1A;
}

/// $C06267
short unknownC06267(short arg1, short arg2, short arg3) {
	short x1A = -1;
	if (entityHitboxEnabled[arg3] != 0) {
		short x02;
		short x16;
		if ((entityDirections[arg3] == Direction.right) || (entityDirections[arg3] == Direction.left)) {
			x02 = entityHitboxLeftRightWidth[arg3];
			x16 = entityHitboxLeftRightHeight[arg3];
		} else {
			x02 = entityHitboxUpDownWidth[arg3];
			x16 = entityHitboxUpDownHeight[arg3];
		}
		short x04 = cast(short)(arg1 - x02);
		short x18 = cast(short)(x02 * 2);
		short x14 = cast(short)(arg2 - x16);
		if (playerIntangibilityFrames == 0) {
			for (short i = 0x18; i < maxEntities; i++) {
				if (entityScriptTable[i] == -1) {
					continue;
				}
				if (entityCollidedObjects[i] == 0x8000) {
					continue;
				}
				if (entityHitboxEnabled[i] == 0) {
					continue;
				}
				short x10;
				short x12;
				if ((entityDirections[i] == Direction.right) || (entityDirections[i] == Direction.left)) {
					x12 = entityHitboxLeftRightWidth[i];
					x10 = entityHitboxLeftRightHeight[i];
				} else {
					x12 = entityHitboxUpDownWidth[i];
					x10 = entityHitboxUpDownHeight[i];
				}
				if (x14 <= entityAbsYTable[i] - x10 - x16) {
					continue;
				}
				if (x14 >= entityAbsYTable[i] - x10 + x10) {
					continue;
				}
				if (x04 <= entityAbsXTable[i] - x12 - x18) {
					continue;
				}
				if (x04 >= entityAbsXTable[i] - x12 + x12 * 2) {
					continue;
				}
				x1A = i;
				goto Unknown26;
			}
		}
		for (short i = 0; i < partyLeaderEntity; i++) {
			if (i == arg3) {
				continue;
			}
			if (entityScriptTable[i] == -1) {
				continue;
			}
			if (entityNPCIDs[i] >= 0x1000) {
				continue;
			}
			if (entityCollidedObjects[i] == 0x8000) {
				continue;
			}
			if (entityHitboxEnabled[i] == 0) {
				continue;
			}
			short x10;
			short x12;
			if ((entityDirections[i] == Direction.right) || (entityDirections[i] == Direction.left)) {
				x12 = entityHitboxLeftRightWidth[i];
				x10 = entityHitboxLeftRightHeight[i];
			} else {
				x12 = entityHitboxUpDownWidth[i];
				x10 = entityHitboxUpDownHeight[i];
			}
			if (x14 <= entityAbsYTable[i] - x10 - x16) {
				continue;
			}
			if (x14 >= entityAbsYTable[i] - x10 + x10 - 1) {
				continue;
			}
			if (x04 <= entityAbsXTable[i] - x12 - x18) {
				continue;
			}
			if (x04 >= entityAbsXTable[i] - x12 + x12 * 2 - 1) {
				continue;
			}
			x1A = i;
			goto Unknown26;
		}
	}
	Unknown26:
	entityCollidedObjects[arg3] = x1A;
	return x1A;
}

/// $C06478
void unknownC06478() {
	if (entityCollidedObjects[currentEntitySlot] == 0x8000) {
		return;
	}
	testEntityMovementSlot(currentEntitySlot);
	unknownC06267(entityMovementProspectX, entityMovementProspectY, currentEntitySlot);
}

/// $C064A6
void unknownC064A6() {
	if (entityCollidedObjects[currentEntitySlot] == 0x8000) {
		return;
	}
	testEntityMovementSlot(currentEntitySlot);
	unknownC0613C(entityMovementProspectX, entityMovementProspectY, currentEntitySlot);
}

/// $C064D4
void unknownC064D4() {
	nextQueuedInteraction = 0;
	currentQueuedInteraction = 0;
	currentQueuedInteractionType = -1;
}

/// $C064E3
void queueInteraction(short arg1, QueuedInteractionPtr arg2) {
	if (arg1 == currentQueuedInteractionType) {
		return;
	}
	tracef("Adding interaction of type %s", arg1);
	queuedInteractions[nextQueuedInteraction].type = arg1;
	queuedInteractions[nextQueuedInteraction].ptr = arg2;
	nextQueuedInteraction = (nextQueuedInteraction + 1) & 3;
	pendingInteractions = 1;
}

/// $C06537
short getLastQueuedInteractionType() {
	return queuedInteractions[currentQueuedInteraction].type;
}

/// $C0654E
QueuedInteractionPtr getLastQueuedInteractionPointer() {
	return queuedInteractions[currentQueuedInteraction].ptr;
}

/// $C06578
void queueEntityCreationRequest(short sprite, short script) {
	entityCreationRequests[entityCreationRequestsCount].sprite = sprite;
	entityCreationRequests[entityCreationRequestsCount].script = script;
	entityCreationRequestsCount++;
}

/// $C065A3
void processEntityCreationRequests() {
	while (entityCreationRequestsCount != 0) {
		entityCreationRequestsCount--;
		createPreparedEntitySprite(entityCreationRequests[entityCreationRequestsCount].sprite, entityCreationRequests[entityCreationRequestsCount].script);
	}
}

/// $C065C2
void unknownC065C2(short direction) {
	short x0E = cast(short)((gameState.leaderX.integer / 8) + interactXOffsets[direction]);
	short x02 = cast(short)((gameState.leaderY.integer / 8) + interactYOffsets[direction]);
	if (direction == Direction.left) {
		x0E--;
	}
	short x = getDoorAt(x0E, x02);
	if (x == -1) {
		x = getDoorAt(cast(short)(x0E + 1), x02);
	}
	if ((x != -1) && (x == 6)) {
		unread7E5DDC = doorFoundType;
		//mapObjectText = doorData[doorFound & 0x7FFF]

		//not sure if this is the correct type...
		mapObjectText = doorFound.entryA.textPtr;
		interactingNPCID = -2;
	}
}

/// $C06662
void screenTransition(short arg1, short arg2) {
	short x02 = screenTransitionConfigTable[arg1].duration == 0xFF ? 900 : screenTransitionConfigTable[arg1].duration;
	unknownC42631(screenTransitionConfigTable[arg1].unknown5, screenTransitionConfigTable[arg1].direction * 4);
	if (arg2 == 1) {
		freezeEntities();
		psiTeleportWaitNFrames(2);
		if (screenTransitionConfigTable[arg1].animationID != 0) {
			startSwirl(screenTransitionConfigTable[arg1].animationID, screenTransitionConfigTable[arg1].animationFlags | AnimationFlags.invert);
		}
		unknownC4954C(screenTransitionConfigTable[arg1].fadeStyle, &palettes[0][0]);
		unknownC496E7(x02, -1);
		for (short i = 0; i < x02; i++) {
			if (paletteUploadMode != PaletteUpload.none) {
				waitUntilNextFrame();
			}
			updateMapPaletteAnimation();
			oamClear();
			unknownC4268A();
			unknownC426C7();
			runActionscriptFrame();
			updateScreen();
			unknownC4A7B0();
			waitUntilNextFrame();
		}
		if (screenTransitionConfigTable[arg1].fadeStyle <= 50) {
			prepareForImmediateDMA();
		} else {
			memset(&palettes[0][0], 0xFF, 0x200);
			preparePaletteUpload(PaletteUpload.full);
			waitUntilNextFrame();
			wipePalettesOnMapLoad = 1;
		}
		unfreezeEntities();
	} else {
		short x1D = (screenTransitionConfigTable[arg1].fadeStyle <= 50) ? 1 : 0;
		if (x1D != 0) {
			fadeIn(1, 1);
		} else {
			unknownC496E7(screenTransitionConfigTable[arg1].secondaryDuration, -1);
		}
		if (screenTransitionConfigTable[arg1].secondaryAnimationID != 0) {
			startSwirl(screenTransitionConfigTable[arg1].secondaryAnimationID, screenTransitionConfigTable[arg1].secondaryAnimationFlags);
		}
		for (short i = 0; i < screenTransitionConfigTable[arg1].secondaryDuration; i++) {
			if (x1D == 0) {
				if (paletteUploadMode != PaletteUpload.none) {
					waitUntilNextFrame();
				}
				updateMapPaletteAnimation();
			}
			oamClear();
			runActionscriptFrame();
			unknownC4A7B0();
			updateScreen();
			waitUntilNextFrame();
			if (i == 1) {
				freezeEntities();
			}
		}
		if (x1D == 0) {
			unknownC49740();
		}
	}
	if (currentGiygasPhase < GiygasPhase.startPraying) {
		disableOvalWindow();
	}
	unfreezeEntities();
	ladderStairsTileY = 0;
	ladderStairsTileX = 0;
}

/// $C068AF
short getScreenTransitionSoundEffect(short transition, short getStart) {
	if (getStart == 0) {
		return screenTransitionConfigTable[transition].endingSoundEffect;
	}
	return screenTransitionConfigTable[transition].startSoundEffect;
}

/// $C068F4
void loadSectorMusic(short x, short y) {
	if (disableMusicChanges != 0) {
		return;
	}
	tracef("Using overworld music entry %s", mapDataPerSectorMusic[y / 128][(x >> 8) & 0xFF]);
	const(OverworldEventMusic)* x0A = &overworldEventMusicPointerTable[mapDataPerSectorMusic[y / 128][(x >> 8) & 0xFF]][0];
	while (x0A.flag != 0) {
		tracef("Trying flag %s for %s", cast(EventFlag)(x0A.flag & 0x7FFF), cast(Music)x0A.music);
		if (getEventFlag(x0A.flag & 0x7FFF) == (x0A.flag > 0x8000) ? 1 : 0) {
			break;
		}
		x0A++;
	}
	tracef("Selected music track: %s", cast(Music)x0A.music);
	loadedMapMusicEntry = x0A;
	nextMapMusicTrack = x0A.music;
	if ((doMapMusicFade == 0) && (x0A.music != currentMapMusicTrack)) {
		musicEffect(MusicEffect.quickFade);
	}
}

/// $C069AF
void changeMapMusic() {
	if (disableMusicChanges != 0) {
		return;
	}
	if (nextMapMusicTrack == currentMapMusicTrack) {
		return;
	}
	currentMapMusicTrack = nextMapMusicTrack;
	changeMusic(nextMapMusicTrack);
	musicEffect(loadedMapMusicEntry.audioEffect);
}

/// $C069ED
void changeMapMusicImmediately() {
	changeMusic(nextMapMusicTrack);
}

/// $C069F7
short unknownC069F7() {
	loadSectorMusic(gameState.leaderX.integer, gameState.leaderY.integer);
	return nextMapMusicTrack;
}

/// $C06A07
void unknownC06A07() {
	loadSectorMusic(gameState.leaderX.integer, gameState.leaderY.integer);
	changeMusic(nextMapMusicTrack);
}

/// $C06A1B
void unknownC06A1B(const(DoorEntryB)* arg1) {
	if (getEventFlag(arg1.eventFlag & 0x7FFF) == (arg1.eventFlag > eventFlagUnset) ? 1 : 0) {
		queueInteraction(InteractionType.unknown0, QueuedInteractionPtr(getTextBlock(arg1.textPtr)));
		ladderStairsTileY = 0;
		ladderStairsTileX = 0;
	}
}

/// $C06A8B
void unknownC06A8B(const(DoorEntryC)*) {
	//you wanted something? too bad!
}

/// $C06A8E
void unknownC06A8E(const(DoorEntryC)*) {
	//nothing
}

/// $C06A91
void unknownC06A91(short arg1) {
	if ((gameState.walkingStyle == WalkingStyle.ladder) || (gameState.walkingStyle == WalkingStyle.rope)) {
		return;
	}
	if (arg1 == 0) {
		gameState.walkingStyle = WalkingStyle.ladder;
	} else {
		gameState.walkingStyle = WalkingStyle.rope;
	}
	gameState.leaderDirection &= 0xFFFE;
	stairsDirection = -1;
}

/// $C06ACA
void unknownC06ACA(const(DoorEntryA)* arg1) {
	if (playerHasDoneSomethingThisFrame == 0) {
		return;
	}
	if (gameState.cameraMode == CameraMode.followEntity) {
		return;
	}
	if (pendingInteractions != 0) {
		return;
	}
	if ((enemyHasBeenTouched | battleSwirlCountdown) != 0) {
		return;
	}
	usingDoor = 1;
	QueuedInteractionPtr ptr = { doorPtr: arg1 };
	queueInteraction(InteractionType.unknown2, cast(QueuedInteractionPtr)ptr);
	playerIntangibilityFlash();
}

/// $C06B21
void spawnBuzzBuzz() {
	displayText(getTextBlock("MSG_EVT_BUNBUNBUN"));
	resolveActiveDeliveries();
}

/// $C06B3D
void removeNonTransitionSurvivingInteractions() {
	short i;
	for (i = 0; (4 > i) && (currentQueuedInteraction != nextQueuedInteraction); currentQueuedInteraction = (currentQueuedInteraction + 1) & 3, i++) {
		if (getLastQueuedInteractionType() != InteractionType.textSurvivesDoorTransition) {
			continue;
		}
		doorInteractions[i] = getLastQueuedInteractionPointer();
	}
	doorInteractions[i].textPtr = null;
	for (short j = 0; doorInteractions[j].textPtr !is null; j++) {
		queueInteraction(InteractionType.textSurvivesDoorTransition, doorInteractions[j]);
	}
}

/// $C06BFF
void doorTransition(const(DoorEntryA)* arg1) {
	if (arg1.textPtr !is null) {
		displayInteractionText(getTextBlock(arg1.textPtr));
	}
	ladderStairsTileY = 0;
	ladderStairsTileX = 0;
	if ((arg1.eventFlag != 0) && (getEventFlag(arg1.eventFlag & 0x7FFF) != (arg1.eventFlag > eventFlagUnset) ? 1 : 0)) {
		usingDoor = 0;
		return;
	}
	for (short i = 1; i <= 10; i++) {
		setEventFlag(i, 0);
	}
	removeNonTransitionSurvivingInteractions();
	playerIntangibilityFlash();
	version(bugfix) {
		if (auto sfx = getScreenTransitionSoundEffect(arg1.transitionStyle, 1)) {
			playSfx(sfx);
		}
	} else {
		playSfx(getScreenTransitionSoundEffect(arg1.transitionStyle, 1));
	}
	if (disabledTransitions != 0) {
		fadeOut(1, 1);
	} else {
		screenTransition(arg1.transitionStyle, 1);
	}
	short x02 = cast(short)(arg1.unknown8 * 8);
	short x04 = cast(short)((arg1.unknown6 & 0x3FFF) * 8);
	if (unknownC3E1D8[arg1.unknown6 >> 14] != 2) {
		x02 += 8;
	}
	if (debugging != 0) {
		if (debugModeNumber != DebugMode.soundMode) {
			loadSectorMusic(x02, x04);
		}
		if (replayModeActive == 0) {
			storePersistentReplayState(arg1.transitionStyle);
		}
	} else {
		loadSectorMusic(x02, x04);
	}
	loadMapAtPosition(x02, x04);
	playerHasMovedSinceMapLoad = 0;
	gameState.walkingStyle = 0;
	unknownC03FA9(x02, x04, unknownC3E1D8[arg1.unknown6 >> 14]);
	if ((debugging != 0) && (replayModeActive == 0)) {
		saveReplaySaveSlot();
	}
	changeMapMusic();
	processEntityCreationRequests();
	playerIntangibilityFlash();
	version(bugfix) {
		if (auto sfx = getScreenTransitionSoundEffect(arg1.transitionStyle, 0)) {
			playSfx(sfx);
		}
	} else {
		playSfx(getScreenTransitionSoundEffect(arg1.transitionStyle, 0));
	}
	if (disabledTransitions != 0) {
		fadeIn(1, 1);
	} else {
		screenTransition(arg1.transitionStyle, 0);
	}
	stairsDirection = -1;
	playerHasDoneSomethingThisFrame = -1;
	spawnBuzzBuzz();
	usingDoor = 0;
}

/// $C06E02
immutable short[4] escalatorEntryOffsetsX = [
	StairDirection.upLeft >> 8: 8,
	StairDirection.upRight >> 8: 0,
	StairDirection.downLeft >> 8: 0,
	StairDirection.downRight >> 8: 8
];

/// $C06E0A
immutable short[4] escalatorExitOffsetsX = [
	StairDirection.upLeft >> 8: 0,
	StairDirection.upRight >> 8: 8,
	StairDirection.downLeft >> 8: 0,
	StairDirection.downRight >> 8: 8
];

/// $C06E12
immutable short[4] stairInputDirectionMap = [Direction.left, Direction.right, Direction.left, Direction.right];

/// $C06E2C
void enterEscalator() {
	gameState.walkingStyle = WalkingStyle.escalator;
	playerMovementFlags = 0;
	gameState.leaderX.integer = escalatorNewX;
	gameState.leaderY.integer = escalatorNewY;
	gameState.leaderY.fraction = 0;
	gameState.leaderX.fraction = 0;
}

/// $C06E4A
void exitEscalator() {
	stairsDirection = -1;
	gameState.walkingStyle = WalkingStyle.normal;
	playerMovementFlags = 0;
	unread7E5DBA = 0;
	gameState.leaderX.integer = escalatorNewX;
	gameState.leaderY.integer = escalatorNewY;
	gameState.leaderY.fraction = 0;
	gameState.leaderX.fraction = 0;
}

/// $C06E6E
void doEscalatorTransition(ushort arg1, short x, short y) {
	if (demoFramesLeft != 0) {
		return;
	}
	clearAutoMovementDemo();
	short xDest;
	if ((arg1 & 0x8000) != 0) { // getting off escalator
		if (gameState.walkingStyle != WalkingStyle.escalator) {
			return;
		}
		gameState.walkingStyle = WalkingStyle.normal;
		playerMovementFlags = PlayerMovementFlags.collisionDisabled | PlayerMovementFlags.dontChangeDirection;
		xDest = cast(short)((x * 8) + escalatorExitOffsetsX[escalatorEntranceDirection >> 8]);
		short frames = recordAutoMovementDemo(gameState.leaderX.integer, gameState.leaderY.integer, xDest, cast(short)(y * 8));
		recordAutoMovementDemoNFramesDirection(stairInputDirectionMap[escalatorEntranceDirection >> 8], 16);
		scheduleOverworldTask(cast(short)(frames + 1), &exitEscalator);
		finishAutoMovementDemoAndStart();
		escalatorEntranceDirection = 0;
		unread7E5DBA = 1;
	} else { // getting on escalator
		if (gameState.walkingStyle == WalkingStyle.escalator) {
			return;
		}
		unread7E5DBA = 1;
		escalatorEntranceDirection = arg1;
		gameState.leaderDirection = stairInputDirectionMap[arg1 >> 8];
		playerMovementFlags = PlayerMovementFlags.collisionDisabled | PlayerMovementFlags.dontChangeDirection;
		xDest = cast(short)((x * 8) + escalatorEntryOffsetsX[arg1 >> 8]);
		scheduleOverworldTask(recordAutoMovementDemo(gameState.leaderX.integer, gameState.leaderY.integer, xDest, cast(short)(y * 8)), &enterEscalator);
		finishAutoMovementDemoAndStart();
	}
	escalatorNewX = xDest;
	escalatorNewY = cast(short)(y * 8);
	stairsDirection = -1;
}

/// $C06F82
void getOnStairs() {
	short x12 = 0;
	if ((stairsDirection == StairDirection.upLeft) || (stairsDirection == StairDirection.upRight)) {
		if (stairsNewY - 1 > gameState.leaderY.integer) {
			x12 = 1;
		}
	} else {
		if (stairsNewY + 1 < gameState.leaderY.integer) {
			x12 = 1;
		}
	}
	if (x12 != 0) {
		gameState.walkingStyle = WalkingStyle.stairs;
		gameState.leaderX.integer = stairsNewX;
		gameState.leaderY.integer = stairsNewY;
		gameState.leaderY.fraction = 0;
		gameState.leaderX.fraction = 0;
	} else {
		scheduleOverworldTask(1, &getOnStairs);
	}
}

/// $C06FED
void getOffStairs() {
	short x12 = 0;
	if ((stairsDirection == StairDirection.upLeft) || (stairsDirection == StairDirection.upRight)) {
		if (stairsNewY < gameState.leaderY.integer) {
			x12 = 1;
		}
	} else {
		if (stairsNewY > gameState.leaderY.integer) {
			x12 = 1;
		}
	}
	if (x12 != 0) {
		stairsDirection = -1;
		gameState.walkingStyle = WalkingStyle.normal;
		playerMovementFlags = 0;
		gameState.leaderX.integer = stairsNewX;
		gameState.leaderY.integer = stairsNewY;
		gameState.leaderY.fraction = 0;
		gameState.leaderX.fraction = 0;
		unread7E5DBA = 0;
	} else {
		scheduleOverworldTask(1, &getOffStairs);
	}
}

/// $C0705F
short unknownC0705F(ushort arg1) {
	short result = 1;
	switch (arg1) {
		case StairDirection.upRight:
			if ((gameState.leaderDirection == 0) || ((gameState.leaderDirection & 3) != 0)) {
				result = 0;
			}
			autoMovementDirection = Direction.right;
			break;
		case StairDirection.upLeft:
			if ((gameState.leaderDirection == 0) || ((gameState.leaderDirection & 3) != 0)) {
				result = 0;
			}
			autoMovementDirection = Direction.left;
			break;
		case StairDirection.downRight:
			if ((gameState.leaderDirection & 7) != 0) {
				result = 0;
			}
			autoMovementDirection = Direction.right;
			break;
		case StairDirection.downLeft:
			if ((gameState.leaderDirection & 7) != 0) {
				result = 0;
			}
			autoMovementDirection = Direction.left;
			break;
		default: break;
	}
	return result;
}

/// $C070CB
void doStairsTransition(ushort direction, short x, short y) {
	if (demoFramesLeft != 0) {
		return;
	}
	clearAutoMovementDemo();
	short xDest;
	short yDest;
	if (gameState.walkingStyle == 0) { //getting on stairs
		if (unknownC0705F(direction) != 0) {
			return;
		}
		gameState.leaderDirection = autoMovementDirection;
		notMovingInSameDirectionFaced = 0;
		playerMovementFlags = PlayerMovementFlags.collisionDisabled | PlayerMovementFlags.dontChangeDirection;
		unread7E5DBA = 1;
		stairsDirection = cast(short)(direction & 0xFF00);
		xDest = cast(short)((x * 8) + staircaseStartOffsetX[direction >> 8]);
		yDest = cast(short)((y * 8) + staircaseStartOffsetY[direction >> 8]);
		short frames = recordAutoMovementDemo(gameState.leaderX.integer, gameState.leaderY.integer, xDest, yDest);
		if (frames == 0) {
			frames++;
		}
		recordAutoMovementDemoNFramesDirection(staircaseEntryDirections[direction >> 8], 6);
		scheduleOverworldTask(frames, &getOnStairs);
	} else { //getting off stairs
		xDest = cast(short)((x * 8) + staircaseEndOffsetX[direction >> 8]);
		yDest = cast(short)((y * 8) + staircaseEndOffsetY[direction >> 8]);
		short frames = recordAutoMovementDemo(gameState.leaderX.integer, gameState.leaderY.integer, xDest, yDest);
		if (frames == 0) {
			frames++;
		}
		recordAutoMovementDemoNFramesDirection(staircaseExitDirections[direction >> 8], 12);
		scheduleOverworldTask(frames, &getOffStairs);
	}
	stairsNewX = xDest;
	stairsNewY = yDest;
	finishAutoMovementDemoAndStart();
}

/// $C071E5
void disableHotspot(short arg1) {
	activeHotspots[arg1 - 1].mode = 0;
	gameState.activeHotspotModes[arg1 - 1] = 0;
}

/// $C07213
void reloadHotspots() {
	for (short i = 0; i < 2; i++) {
		if (gameState.activeHotspotModes[i] == 0) {
			continue;
		}
		activeHotspots[i].mode = gameState.activeHotspotModes[i];
		activeHotspots[i].x1 = cast(ushort)(mapHotspots[gameState.activeHotspotIDs[i]].x1 * 8);
		activeHotspots[i].y1 = cast(ushort)(mapHotspots[gameState.activeHotspotIDs[i]].y1 * 8);
		activeHotspots[i].x2 = cast(ushort)(mapHotspots[gameState.activeHotspotIDs[i]].x2 * 8);
		activeHotspots[i].y2 = cast(ushort)(mapHotspots[gameState.activeHotspotIDs[i]].y2 * 8);
		activeHotspots[i].pointer = gameState.activeHotspotPointers[i];
	}
}

/// $C072CF
void activateHotspot(short arg1, short arg2, const(ubyte)* arg3) {
	short x;
	if ((gameState.leaderX.integer > mapHotspots[arg2].x1) && (gameState.leaderX.integer < mapHotspots[arg2].x2) && (gameState.leaderY.integer > mapHotspots[arg2].y1) && (gameState.leaderY.integer < mapHotspots[arg2].y2)) {
		x = 1;
	} else {
		x = 2;
	}
	activeHotspots[arg1 - 1].mode = x;
	activeHotspots[arg1 - 1].x1 = cast(ushort)(mapHotspots[arg2].x1 * 8);
	activeHotspots[arg1 - 1].y1 = cast(ushort)(mapHotspots[arg2].y1 * 8);
	activeHotspots[arg1 - 1].x2 = cast(ushort)(mapHotspots[arg2].x2 * 8);
	activeHotspots[arg1 - 1].y2 = cast(ushort)(mapHotspots[arg2].y2 * 8);
	activeHotspots[arg1 - 1].pointer = arg3;
	gameState.activeHotspotModes[arg1 - 1] = cast(ubyte)x;
	gameState.activeHotspotIDs[arg1 - 1] = cast(ubyte)arg2;
	gameState.activeHotspotPointers[arg1 - 1] = arg3;
}

/// $C073C0
void unknownC073C0(short arg1) {
	// don't ask. I don't know either
	if ((nextQueuedInteraction ^ nextQueuedInteraction) != 0) {
		return;
	}
	if (psiTeleportDestination != 0) {
		return;
	}
	short x12 = activeHotspots[arg1].mode;
	if (x12 == 1) {
		if ((gameState.leaderX.integer >= activeHotspots[arg1].x1) && (gameState.leaderX.integer < activeHotspots[arg1].x2) && (gameState.leaderY.integer >= activeHotspots[arg1].y1) && (gameState.leaderY.integer < activeHotspots[arg1].y2)) {
			return;
		}
	} else {
		if ((gameState.leaderX.integer <= activeHotspots[arg1].x1) || (gameState.leaderX.integer >= activeHotspots[arg1].x2) || (gameState.leaderY.integer <= activeHotspots[arg1].y1) || (gameState.leaderY.integer >= activeHotspots[arg1].y2)) {
			return;
		}
	}
	activeHotspots[arg1].mode = 0;
	queueInteraction(InteractionType.unknown9, QueuedInteractionPtr(activeHotspots[arg1].pointer));
	gameState.activeHotspotModes[arg1] = 0;
}

/// $C07477
byte getDoorAt(short x, short y) {
	const(SectorDoors)* x0A = &doorConfig[y / 32][x / 32];
	if (x0A.length == 0) {
		return -1;
	}
	const(DoorConfig)* x06 = &x0A.doors[0];
	for (short i = x0A.length; i != 0; x06++, i--) {
		if (x06.unknown1 != (x % 32)) {
			continue;
		}
		if (x06.unknown0 != (y % 32)) {
			continue;
		}
		doorFound = x06.doorPtr;
		doorFoundType = x06.type;
		return x06.type;
	}
	return -1;
}

/// $C07526
short unknownC07526(short x, short y) {
	version(noUndefinedBehaviour) {
		short x0E = 1;
	} else {
		short x0E = void;
	}
	switch (getDoorAt(x, y)) {
		case DoorType.switch_:
			unknownC06A1B(doorFound.entryB);
			x0E = 0;
			break;
		case DoorType.ropeLadder:
			unknownC06A91(doorFound.direction);
			x0E = 1;
			break;
		case DoorType.door:
			unknownC06ACA(doorFound.entryA);
			x0E = 0;
			break;
		case DoorType.escalator:
			doEscalatorTransition(doorFound.direction, x, y);
			x0E = 0;
			break;
		case DoorType.stairway:
			doStairsTransition(doorFound.direction, x, y);
			x0E = 1;
			break;
		case DoorType.object:
		case DoorType.type7:
			unknownC06A8B(doorFound.entryC);
			x0E = 0;
			break;
		case DoorType.person:
			unknownC06A8E(doorFound.entryC);
			x0E = 0;
			break;
		default: break;
	}
	return x0E;
}

/// $C075DD
void processQueuedInteractions() {
	QueuedInteractionPtr ptr = queuedInteractions[currentQueuedInteraction].ptr;
	currentQueuedInteractionType = queuedInteractions[currentQueuedInteraction].type;
	currentQueuedInteraction = (currentQueuedInteraction + 1) & 3;
	playerIntangibilityFrames &= 0xFFFE;
	playerIntangibilityFlash();
	tracef("Processing interaction of type %s", currentQueuedInteractionType);
	switch(currentQueuedInteractionType) {
		case InteractionType.unknown2:
			doorTransition(ptr.doorPtr);
			break;
		case InteractionType.textSurvivesDoorTransition:
			displayInteractionText(ptr.textPtr);
			if (ptr.textPtr == getTextBlock("MSG_SYS_PAPA_2H")) {
				dadPhoneTimer = 0x697;
				dadPhoneQueued = 0;
			}
			break;
		case InteractionType.unknown0:
		case InteractionType.unknown8:
		case InteractionType.unknown9:
			displayInteractionText(ptr.textPtr);
			break;
		default: break;
	}
	pendingInteractions = (currentQueuedInteraction != nextQueuedInteraction) ? 1 : 0;
	currentQueuedInteractionType = -1;
}

/// $C0769C
void restorePartyStatus() {
	gameState.partyStatus = PartyStatus.normal;
	for (short i = 0x18; i <= 0x1D; i++) {
		entityScriptVar3Table[i] = 8;
	}
}

/// $C076C8
void boostPartySpeed(short duration) {
	if (gameState.partyStatus == PartyStatus.speedBoost) {
		return;
	}
	gameState.partyStatus = PartyStatus.speedBoost;
	for (short i = 0x18; i <= 0x1D; i++) {
		entityScriptVar3Table[i] = 5;
	}
	scheduleOverworldTask(duration, &restorePartyStatus);
}

/// $C07716
void unknownC07716() {
	if ((entityCallbackFlags[gameState.firstPartyMemberEntity] & (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled)) != 0) {
		return;
	}
	if ((entitySpriteMapFlags[gameState.firstPartyMemberEntity] & SpriteMapFlags.drawDisabled) != 0) {
		return;
	}
	if (gameState.cameraMode == CameraMode.followEntity) {
		return;
	}
	miniGhostEntityID = createEntity(OverworldSprite.miniGhost, ActionScript.unknown786, -1, 0, 0);
	entityAnimationFrames[miniGhostEntityID] = -1;
	entityScreenYTable[miniGhostEntityID] = -256;
	entityAbsYTable[miniGhostEntityID] = -256;
	entityAbsXTable[miniGhostEntityID] = -256;
}

/// $C0777A
void unknownC0777A() {
	unknownC02140(miniGhostEntityID);
	miniGhostEntityID = -1;
}

/// $C0778A
void unknownC0778A() {
	if ((entityCallbackFlags[gameState.firstPartyMemberEntity] & (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled)) != 0) {
		entityAnimationFrames[currentEntitySlot] = -1;
		return;
	}
	auto x0E = unknownC41FFF(miniGhostAngle, 0x3000);
	entityAbsXTable[currentEntitySlot] = cast(short)(gameState.leaderX.integer + (x0E.x >> 8));
	entityAbsYTable[currentEntitySlot] = cast(short)(gameState.leaderY.integer - 8 + (x0E.y >> 10));
	miniGhostAngle += 0x300;
	entityAnimationFrames[currentEntitySlot] = 0;
}

/// $C0780F
short unknownC0780F(short characterID, short walkingStyle, PartyCharacter* character) {
	short y = 0;
	if ((characterID == 0) && (disabledTransitions == 0) && (pajamaFlag != 0)) {
		return OverworldSprite.nessInPajamas;
	}
	if (movingPartyMemberEntityID != -1) {
		entityOverlayFlags[movingPartyMemberEntityID] = EntityOverlayFlags.none;
	}
	if (gameState.partyStatus == PartyStatus.burnt) {
		if (gameState.specialGameState != SpecialGameState.useMiniSprites) {
			return 0xD;
		} else {
			return 0x25;
		}
	}
	switch (character.afflictions[0]) {
		case Status0.unconscious:
			y = 1;
			break;
		case Status0.diamondized:
			if (gameState.specialGameState != SpecialGameState.useMiniSprites) {
				return 0xC;
			}
			return 0x24;
		case Status0.nauseous:
			if (movingPartyMemberEntityID != -1) {
				entityOverlayFlags[movingPartyMemberEntityID] |= EntityOverlayFlags.sweating;
			}
			break;
		default: break;
	}
	switch (character.afflictions[1]) {
		case Status1.mushroomized:
			if (movingPartyMemberEntityID != -1) {
				entityOverlayFlags[movingPartyMemberEntityID] |= EntityOverlayFlags.mushroom;
			}
			break;
		case Status1.possessed:
			possessedPlayerCount++;
			break;
		default: break;
	}
	if (gameState.specialGameState == SpecialGameState.onBicycle) {
			return 7;
	} else if (gameState.specialGameState == SpecialGameState.useMagicantSprites) {
		if (character.characterID == 0) {
			return 6;
		}
	}
	if (y == 0) {
		switch (walkingStyle) {
			case 0:
			case WalkingStyle.escalator:
			case WalkingStyle.stairs:
				y = 0;
				break;
			case WalkingStyle.ghost:
				y = 1;
				break;
			case WalkingStyle.ladder:
				y = 2;
				break;
			case WalkingStyle.rope:
				y = 3;
				break;
			default: break;
		}
	}
	if (gameState.specialGameState == SpecialGameState.useMiniSprites) {
		y += 4;
		entityOverlayFlags[movingPartyMemberEntityID] = EntityOverlayFlags.none;
	} else if ((gameState.specialGameState == SpecialGameState.useRobotSprites) && (y == 0)) {
		y += 6;
	}
	if (gameState.partyStatus == PartyStatus.speedBoost) {
		entityScriptVar3Table[movingPartyMemberEntityID] = 5;
	} else if (character.afflictions[0] == Status0.unconscious) {
		entityScriptVar3Table[movingPartyMemberEntityID] = 16;
	} else if ((entitySurfaceFlags[movingPartyMemberEntityID] & 0xC) == 0xC) {
		entityScriptVar3Table[movingPartyMemberEntityID] = 24;
	} else if ((entitySurfaceFlags[movingPartyMemberEntityID] & 8) == 8) {
		entityScriptVar3Table[movingPartyMemberEntityID] = 16;
	} else {
		entityScriptVar3Table[movingPartyMemberEntityID] = 8;
	}
	if (character.afflictions[0] == Status0.paralyzed) {
		entityScriptVar3Table[movingPartyMemberEntityID] = 56;
	}
	return partyCharacterGraphicsTable[characterID][y];
}

/// $C079EC
short unknownC079EC(short arg1) {
	short x = 0;
	if ((arg1 & 0x20) != 0) {
		x = 1;
	} else if ((arg1 & 0x40) != 0) {
		return OverworldSprite.humanDiamondized;
	}
	short a = partyCharacterGraphicsTable[(arg1 & 0x1F) - 1][x];
	return (a == 1) ? OverworldSprite.nessPosing : a;
}

/// $C07A31
void unknownC07A31(short arg1, short arg2) {
	if ((arg2 & 0x80) == 0) {
		return;
	}
	entityOverlayFlags[arg1] |= EntityOverlayFlags.mushroom;
}

/// $C07A56
void doPartyMovementFrame(short characterID, short walkingStyle, short entityID) {
	const short x04 = entityID;
	short x02 = walkingStyle;
	const short x16 = walkingStyle;
	const short x14 = characterID;
	movingPartyMemberEntityID = x04;
	short x12 = unknownC0780F(x14, x02, currentPartyMemberTick);
	if (x12 == -1) {
		entityAnimationFrames[x04] = x12;
	} else {
		auto x0E = spriteGroupingPointers[x12];
		entityGraphicsPointers[x04] = &x0E.sprites[0];
		//UNKNOWN_30X2_TABLE_31[x04] = x0E.spriteBank;
		entityWalkingStyles[x04] = x02;
		if (walkingStyle != currentPartyMemberTick.unknown55) {
			currentPartyMemberTick.unknown55 = x16;
			entityScriptVar7Table[x04] |= PartyMemberMovementFlags.unknown15;
		}
		if ((gameState.leaderHasMoved != 0) && (x16 != 0xC)) {
			entityScriptVar7Table[x04] &= ~(PartyMemberMovementFlags.unknown15 | PartyMemberMovementFlags.unknown14 | PartyMemberMovementFlags.unknown13);
		} else {
			entityScriptVar7Table[x04] |= (PartyMemberMovementFlags.unknown14 | PartyMemberMovementFlags.unknown13);
		}
	}
	if (gameState.cameraMode == CameraMode.followEntity) {
		entityScriptVar7Table[x04] |= PartyMemberMovementFlags.unknown12;
	}
}

/// $C07B52
void unknownC07B52() {
	ushort x14 = partyCharacters[0].positionIndex;
	for (ushort x12 = 0x18; x12 < 0x1E; x12++) {
		ushort x04 = x12;
		ushort x10 = x12;
		if (entityScriptTable[x04] != -1) {
			entityCallbackFlags[x04] |= (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled);
			currentPartyMemberTick = &partyCharacters[entityScriptVar1Table[x04]];
			if ((gameState.firstPartyMemberEntity == x12) || (currentPartyMemberTick.positionIndex == x14)) {
				doPartyMovementFrame(entityScriptVar0Table[x12], gameState.walkingStyle, x12);
				entityAbsXTable[x12] = gameState.leaderX.integer;
				entityAbsYTable[x12] = gameState.leaderY.integer;
				if (gameState.partyCount != 1) {
					entityDirections[x12] = gameState.leaderDirection;
				}
			} else {
				doPartyMovementFrame(entityScriptVar0Table[x12], playerPositionBuffer[currentPartyMemberTick.positionIndex].walkingStyle, x12);
				entityAbsXTable[x10] = playerPositionBuffer[currentPartyMemberTick.positionIndex].xCoord;
				entityAbsYTable[x10] = playerPositionBuffer[currentPartyMemberTick.positionIndex].yCoord;
				entityDirections[x10] = playerPositionBuffer[currentPartyMemberTick.positionIndex].direction;
			}
			entityScreenXTable[x12] = cast(short)(entityAbsXTable[x12] - bg1XPosition);
			entityScreenYTable[x12] = cast(short)(entityAbsYTable[x12] - bg1YPosition);
			updateEntitySpriteFrame(x12);
		}
	}
}

/** Do a single frame of intangibility flashing
 * Original_Address: $(DOLLAR)C07C5B
 */
void playerIntangibilityFlash() {
	if (playerIntangibilityFrames == 0) {
		return;
	}
	for (short i = 0x18; i < 0x1E; i++) {
		entitySpriteMapFlags[i] &= ~SpriteMapFlags.drawDisabled;
	}
}

/// $C08000
void start() {
	dmaQueueIndex = 0;

	INIDISP = 0x80;
	mirrorINIDISP = 0x80;

	// clearing the heap would happen here

	currentHeapAddress = &heap[0][0];
	heapBaseAddress = &heap[0][0];
	unused7E2402 = -1;
	randA = 0x1234;
	randB = 0x5678;
	nextFrameBufferID = 1;
	irqCallback = &defaultIRQCallback;
	renderFirstFrame();
	gameInit();
}

void irqNMICommon() {
	// a read from RDNMI is required on real hardware during NMI, apparently
	//ubyte __unused = RDNMI;
	HDMAEN = 0;
	INIDISP = 0x80;
	newFrameStarted++;
	frameCounter++;
	if (nextFrameDisplayID != 0) {
		handleOAMDMA(0, 4, ((nextFrameDisplayID - 1) != 0) ? (&oam2) : (&oam1), 0x220, 0);
		dmaBytesCopied += 0x220;
	}
	if (paletteUploadMode != PaletteUpload.none) {
		// In the original game's source code, we would only DMA part of
		// the palette to save cycles. With the power of modern computers,
		// we can afford to copy 512 bytes always instead of only 256.
		paletteUploadMode = PaletteUpload.none;
		handleCGRAMDMA(0, 0x22, &palettes, 0x200, 0);
		dmaBytesCopied += 0x0200;
	}
	if ((fadeParameters.step != 0) && (--fadeDelayFramesLeft < 0)) {
		fadeDelayFramesLeft = fadeParameters.delay;
		ubyte a = cast(byte)((mirrorINIDISP & 0xF) + fadeParameters.step);
		if ((a & 0x80) != 0) { // underflowed
			mirrorHDMAEN = 0;
			a = 0x80;
		} else {
			if (a < 16) {
				goto Unknown6;
			}
			// overflowed
			a = 15;
		}
		fadeParameters.step = 0;
		Unknown6:
		mirrorINIDISP = a;
	}
	INIDISP = mirrorINIDISP;
	MOSAIC = mirrorMOSAIC;
	BG12NBA = mirrorBG12NBA;
	// mirrorWH2 is loaded into Y for no reason here... and then immediately
	// replaced with a constant which is written to WH2/3.
	// This has the effect of disabling the 2nd window.
	WH2 = 0xFF;
	WH3 = 0x00;
	for (short i = lastCompletedDMAIndex; i != dmaQueueIndex; i++) {
		handleVRAMDMA(dmaTable[dmaQueue[i].mode].dmap, dmaTable[dmaQueue[i].mode].bbad, dmaQueue[i].source, dmaQueue[i].size, dmaQueue[i].destination, dmaTable[dmaQueue[i].mode].vmain);
	}
	lastCompletedDMAIndex = dmaQueueIndex;
	if (nextFrameDisplayID != 0) {
		if (nextFrameDisplayID - 1 == 0) {
			setBGOffsetX(1, bg1XPositionBuffer[0]);
			setBGOffsetY(1, bg1YPositionBuffer[0]);
			setBGOffsetX(2, bg2XPositionBuffer[0]);
			setBGOffsetY(2, bg2YPositionBuffer[0]);
			setBGOffsetX(3, bg3XPositionBuffer[0]);
			setBGOffsetY(3, bg3YPositionBuffer[0]);
			setBGOffsetX(4, bg4XPositionBuffer[0]);
			setBGOffsetY(4, bg4YPositionBuffer[0]);
		} else {
			setBGOffsetX(1, bg1XPositionBuffer[1]);
			setBGOffsetY(1, bg1YPositionBuffer[1]);
			setBGOffsetX(2, bg2XPositionBuffer[1]);
			setBGOffsetY(2, bg2YPositionBuffer[1]);
			setBGOffsetX(3, bg3XPositionBuffer[1]);
			setBGOffsetY(3, bg3YPositionBuffer[1]);
			setBGOffsetX(4, bg4XPositionBuffer[1]);
			setBGOffsetY(4, bg4YPositionBuffer[1]);
			evenBG1XPosition = bg1XPosition;
			evenBG1YPosition = bg1YPosition;
		}
	}
	nextFrameDisplayID = 0;
	if ((mirrorINIDISP & 0x80) == 0) {
		TM = mirrorTM;
		TD = mirrorTD;
		HDMAEN = mirrorHDMAEN;
		handleHDMA();
	}
	dmaBytesCopied = 0;
	if (inIRQCallback == 0) {
		inIRQCallback = 1;
		executeIRQCallback();
		inIRQCallback = 0;
	}

	if (heapBaseAddress == &heap[0]) {
		heapBaseAddress = &heap[1][0];
		currentHeapAddress = &heap[1][0];
	} else {
		heapBaseAddress = &heap[0][0];
		currentHeapAddress = &heap[0][0];
	}

	dmaTransferFlag = 0;
	unread7E00AB = 0;
	timer++;
}

/// $C083B8
void demoRecordingEnd() {
	demoRecordingFlags = 0;
}

/// $C083C1
void demoRecordingStart(DemoEntry* arg1) {
	demoWriteDestination = arg1;
	demoLastInput = padState[0];
	demoSameInputFrames = 1;
	demoRecordingFlags |= DemoRecordingFlags.recordingEnabled;
}

/// $C083E3
void demoReplayStart(DemoEntry* arg1) {
	if ((demoRecordingFlags & DemoRecordingFlags.playbackEnabled) != 0) {
		return;
	}
	if (arg1.frames == 0) {
		demoRecordingEnd();
	}
	demoFramesLeft = arg1.frames;
	demoInitialPadState = arg1.padState;
	demoReadSource = arg1;
	padRaw[0] = arg1.padState;
	padRaw[1] = arg1.padState;
	demoRecordingFlags |= DemoRecordingFlags.playbackEnabled;
}

/// $C0841B
short testSRAMSize() {
	//original code tested how large SRAM was by writing to areas beyond retail SRAM and comparing to a value guaranteed to be in SRAM
	//if SRAM is retail-sized, these areas would just be mirrors of the existing SRAM
	return lastSRAMBank;
}

/// $C0841B
void readJoypad() {
	if (demoRecordingFlags == 0) {
		goto l1;
	}
	if ((demoRecordingFlags & DemoRecordingFlags.playbackEnabled) == 0) {
		goto l1;
	}
	if (--demoFramesLeft != 0) {
		return;
	}
	demoReadSource++;
	if (demoReadSource[0].frames == 0) {
		goto l0;
	}
	demoFramesLeft = demoReadSource[0].frames;
	padRaw[0] = demoReadSource[0].padState;
	padRaw[1] = demoReadSource[0].padState;
	return;

	l0:
	demoRecordingFlags &= ~DemoRecordingFlags.playbackEnabled;

	l1:
	padRaw[1] = getControllerState(1);
	padRaw[0] = getControllerState(0);
}

/// $C08456
void demoRecordButtons() {
	if ((demoRecordingFlags & DemoRecordingFlags.recordingEnabled) == 0) {
		return;
	}
	if ((padRaw[0] | padRaw[1]) == demoLastInput) {
		demoSameInputFrames++;
		if (demoSameInputFrames != 0xFF) {
			return;
		}
	}
	demoWriteDestination.frames = cast(ubyte)demoSameInputFrames;
	demoWriteDestination.padState = demoLastInput;
	demoWriteDestination++;
	demoLastInput = padRaw[0] | padRaw[1];
	demoSameInputFrames = 0;
	demoSameInputFrames++;
	demoWriteDestination.frames = 0;
	if (demoWriteDestination !is null) { //not sure about this... but what is BPL on a pointer supposed to mean?
		return;
	}
	demoRecordingFlags &= ~DemoRecordingFlags.recordingEnabled;
}

/// $C08496
void unknownC08496() {
	while ((HVBJOY & 1) == 1) {}
	readJoypad();
	demoRecordButtons();

	short x = 1;
	while (x >= 0) {
		version(configurable) {
			padTemp = padRaw[x];
		} else {
			padTemp = padRaw[x] & 0xFFF0; //mask off the nonexistent buttons
		}

		padPress[x] = (padState[x] ^ 0xFFFF) & padTemp;

		bool eq = (padTemp == padState[x]);
		padState[x] = padTemp;

		if (!eq) {
			padHeld[x] = padPress[x];
			padTimer[x] = 20;
		} else {
			if (padTimer[x] != 0) {
				padTimer[x]--;
				padHeld[x] = 0;
			} else {
				padHeld[x] = padState[x];
				padTimer[x] = 3;
			}
		}

		x--;
	}

	if (debugging == 0) {
		padState[0] |= padState[1];
		padHeld[0] |= padHeld[1];
		padPress[0] |= padPress[1];
	}
	if (padPress[0] != 0) {
		playerHasDoneSomethingThisFrame++;
	}
}

/// $C08518
void executeIRQCallback() {
	irqCallback();
}

/// $C0851B
void defaultIRQCallback() {
	//nothing
}

/// $C0851C
void setIRQCallback(void function() arg1) {
	irqCallback = arg1;
}

/// $C08522
void resetIRQCallback() {
	irqCallback = &defaultIRQCallback;
}

/// $C0856B
void preparePaletteUpload(short arg1) {
	paletteUploadMode = cast(ubyte)arg1;
}

/// $C085B7 - Copy data to VRAM in chunks of 0x1200
void copyToVRAM2(ubyte mode, ushort count, ushort address, const(ubyte)* data) {
	dmaCopyMode = mode;
	while (dmaBytesCopied != 0) { waitForInterrupt(); }
	dmaCopyRAMSource = data;
	dmaCopyVRAMDestination = address;
	if (count >= 0x1201) {
		dmaCopySize = 0x1200;
		while (count >= 0x1201) {
			while (dmaBytesCopied != 0) { waitForInterrupt(); }
			copyToVRAMCommon();
			dmaCopyRAMSource += 0x1200;
			dmaCopyVRAMDestination += 0x900;
			count -= 0x1200;
		}
	}
	dmaCopySize = count;
	while (dmaBytesCopied != 0) { waitForInterrupt(); }
	copyToVRAMCommon();
	while (dmaBytesCopied != 0) { waitForInterrupt(); }
}

/// $C08616 - Copy data to VRAM
void copyToVRAM(ubyte mode, ushort count, ushort address, const(ubyte)* data) {
	dmaCopyMode = mode;
	dmaCopySize = count;
	dmaCopyRAMSource = data;
	dmaCopyVRAMDestination = address;
	copyToVRAMCommon();
}
// this actually splits the address into bank/address parameters, but we don't need that
void copyToVRAMAlt(ubyte mode, ushort count, ushort address, const(ubyte)* data) {
	copyToVRAM(mode, count, address, data);
}

void copyToVRAMCommon() {
	copyToVRAMInternal();
}

/// $C0865F
void copyToVRAMInternal() {
	debug(printVRAMDMA) tracef("Copying %s bytes to $%04X, mode %s", dmaCopySize, dmaCopyVRAMDestination, dmaCopyMode);
	// if ((mirrorINIDISP & 0x80) != 0) {
	// 	ushort tmp92 = cast(ushort)(dmaCopySize + dmaBytesCopied);
	// 	if (tmp92 >= 0x1201) {
	// 		while (dmaBytesCopied != 0) { waitForInterrupt(); }
	// 		tmp92 = dmaCopySize;
	// 	}
	// 	dmaBytesCopied = tmp92;
	// 	unknown7E00A5 = lastCompletedDMAIndex;
	// 	dmaQueue[dmaQueueIndex].mode = dmaCopyMode;
	// 	dmaQueue[dmaQueueIndex].size = dmaCopySize;
	// 	dmaQueue[dmaQueueIndex].source = dmaCopyRAMSource;
	// 	dmaQueue[dmaQueueIndex].destination = dmaCopyVRAMDestination;
	// 	if (dmaQueueIndex + 1 == unknown7E00A5) {
	// 		while (dmaQueueIndex + 1 == lastCompletedDMAIndex) {}
	// 	}
	// 	dmaQueueIndex++;
	// } else {
		// Since we send a complete image of VRAM to the console every frame, we
		// can just overwrite our local VRAM copy - no need to delay
		handleVRAMDMA(dmaTable[dmaCopyMode / 3].dmap, dmaTable[dmaCopyMode / 3].bbad, dmaCopyRAMSource, dmaCopySize, dmaCopyVRAMDestination, dmaTable[dmaCopyMode / 3].vmain);
		currentHeapAddress = heapBaseAddress;
		dmaTransferFlag = 0;
	// }
}

/// $C086DE
void* sbrk(ushort i) {
	while (true) {
		if (i + currentHeapAddress - heap[0].length < heapBaseAddress) {
			void* result = currentHeapAddress;
			currentHeapAddress += i;
			return result;
		}
		while (newFrameStarted != 0) { waitForInterrupt(); }
		newFrameStarted = 0;
	}
}

/// $C08726
void prepareForImmediateDMA() {
	mirrorINIDISP = 0x80;
	mirrorHDMAEN = 0;
	fadeParameters.step = 0;
	newFrameStarted = 0;
	while (newFrameStarted != 0) { waitForInterrupt(); }
	HDMAEN = 0;
}

/// $C08744
void setForceBlank() {
	mirrorINIDISP = 0x80;
	newFrameStarted = 0;
	while (newFrameStarted != 0) { waitForInterrupt(); }
}

/// $C08715
void enableNMIJoypad() {
	mirrorNMITIMEN |= 0x81;
	NMITIMEN = mirrorNMITIMEN;
}

/// $C08756
void waitUntilNextFrame() {
	// if ((mirrorNMITIMEN & 0xB0) != 0) {
	// 	while (newFrameStarted == 0) {}
	// 	newFrameStarted = 0;
	// } else {
	// 	while (HVBJOY < 0) {}
	// 	while (HVBJOY >= 0) {}
	// }
	waitForInterrupt();
	newFrameStarted = 0;
	unknownC08496();
}

/// $C0878B
void waitNFrames(ubyte arg1) {
	do {
		nextFrameDisplayID++;
		waitUntilNextFrame();
	} while (--arg1 != 0);
}

/// $C0879D
void setINIDISP(ubyte arg1) {
	mirrorINIDISP = arg1 & 0x8F;
}

/// $C087AB
void unknownC087AB(ubyte arg1) {
	mirrorMOSAIC = (((mirrorINIDISP ^ 0xFF) << 4) & 0xF0) | arg1;
}

/// $C087CE
void fadeInWithMosaic(short arg1, short arg2, short arg3) {
	fadeParameters.step = 0;
	mirrorINIDISP = 0;
	while(true) {
		mirrorMOSAIC = 0;
		if (mirrorINIDISP + arg1 >= 0x0F) {
			break;
		}
		setINIDISP(cast(ubyte)(mirrorINIDISP + arg1));
		if (arg3 != 0) {
			unknownC087AB(cast(ubyte)arg3);
		}
		waitNFrames(cast(ubyte)arg2);
	}
	setINIDISP(0xF);
}

/// $C08814
void fadeOutWithMosaic(short arg1, short arg2, short arg3) {
	fadeParameters.step = 0;
	while (true) {
		mirrorMOSAIC = 0;
		if ((mirrorINIDISP & 0x80) != 0) {
			break;
		}
		if (mirrorINIDISP - arg1 < 0) {
			break;
		}
		setINIDISP(cast(ubyte)(mirrorINIDISP - arg1));
		if (arg3 != 0) {
			unknownC087AB(cast(ubyte)arg3);
		}
		waitNFrames(cast(ubyte)arg2);
	}
	setINIDISP(0x80);
	mirrorHDMAEN = 0;
	newFrameStarted = 0;
	while (newFrameStarted != 0) { waitForInterrupt(); }
	HDMAEN = 0;
}

/// $C0886C
void fadeIn(ubyte arg1, ubyte arg2) {
	fadeParameters.step = arg1;
	fadeParameters.delay = arg2;
	fadeDelayFramesLeft = arg2;
}

/// $C0887A
void fadeOut(ubyte arg1, ubyte arg2) {
	fadeParameters.step = cast(ubyte)((arg1^0xFF) + 1);
	fadeParameters.delay = arg2;
	fadeDelayFramesLeft = arg2;
}

/// $C0888B
void unknownC0888B() {
	while (true) {
		if (fadeParameters.step == 0) {
			return;
		}
		oamClear();
		updateScreen();
		waitUntilNextFrame();
	}
}

/// $C088B1
void oamClear() {
	priority0SpriteOffset = 0;
	priority1SpriteOffset = 0;
	priority2SpriteOffset = 0;
	priority3SpriteOffset = 0;
	if (nextFrameBufferID - 1 == 0) {
		oamAddr = &oam1.mainTable[0];
		oamEndAddr = &oam1.mainTable.ptr[128];
		oamHighTableAddr = &oam1.highTable[0];
		oamHighTableBuffer = 0x80;
		for (short i = 0; i < 128; i++) { //original code has this loop unrolled
			oam1.mainTable[i].yCoord = 224;
		}
	} else {
		oamAddr = &oam2.mainTable[0];
		oamEndAddr = &oam2.mainTable.ptr[128];
		oamHighTableAddr = &oam2.highTable[0];
		oamHighTableBuffer = 0x80;
		for (short i = 0; i < 128; i++) { //original code has this loop unrolled
			oam2.mainTable[i].yCoord = 224;
		}
	}
}

/// $C088A5
ushort setSpritemapBank(ushort arg1) {
	ushort tmp = spritemapBank;
	spritemapBank = arg1;
	return tmp;
}

/// $C08B19
void renderFirstFrame() {
	unread7E0009 = 0;
	oamClear();
	updateScreen();
}

/// $C08B26
void updateScreen() {
	renderSpritesToOAM();
	if (false /+Actually tests if the DBR is 0xFF, which should never happen+/) while(true) {}
	ubyte oamHighTableBufferTmp = oamHighTableBuffer;
	if (oamHighTableBufferTmp != 0x80) {
		// Shift right by two until a bit carries out
		// ...or, shift right by two until a bit is in position 2,
		// then do an extra shift after (so the bit in spot 2 shifts out)
		while ((oamHighTableBufferTmp & 2) == 0) {
			oamHighTableBufferTmp >>= 2;
		}
		oamHighTableBufferTmp >>= 2;
	}
	*oamHighTableAddr = oamHighTableBufferTmp;
	bg1XPositionBuffer[nextFrameBufferID - 1] = bg1XPosition;
	bg1YPositionBuffer[nextFrameBufferID - 1] = bg1YPosition;
	bg2XPositionBuffer[nextFrameBufferID - 1] = bg2XPosition;
	bg2YPositionBuffer[nextFrameBufferID - 1] = bg2YPosition;
	bg3XPositionBuffer[nextFrameBufferID - 1] = bg3XPosition;
	bg3YPositionBuffer[nextFrameBufferID - 1] = bg3YPosition;
	bg4XPositionBuffer[nextFrameBufferID - 1] = bg4XPosition;
	bg4YPositionBuffer[nextFrameBufferID - 1] = bg4YPosition;
	nextFrameDisplayID = nextFrameBufferID;
	nextFrameBufferID ^= 3;
}

/// $C08B8E
void renderSpritesToOAM() {
	if (unused7E2402 == 0) {
		unknownC08C53();
	}
	for (short i = 0; i < priority0SpriteOffset / 2; i++) {
		spritemapBank = priority0SpriteMapBanks[i];
		renderSpriteToOAM(priority0SpriteMaps[i], priority0SpriteX[i], priority0SpriteY[i]);
	}
	if (unused7E2402 == 1) {
		unknownC08C53();
	}
	for (short i = 0; i < priority1SpriteOffset / 2; i++) {
		spritemapBank = priority1SpriteMapBanks[i];
		renderSpriteToOAM(priority1SpriteMaps[i], priority1SpriteX[i], priority1SpriteY[i]);
	}
	if (unused7E2402 == 2) {
		unknownC08C53();
	}
	for (short i = 0; i < priority2SpriteOffset / 2; i++) {
		spritemapBank = priority2SpriteMapBanks[i];
		renderSpriteToOAM(priority2SpriteMaps[i], priority2SpriteX[i], priority2SpriteY[i]);
	}
	if (unused7E2402 == 3) {
		unknownC08C53();
	}
	for (short i = 0; i < priority3SpriteOffset / 2; i++) {
		spritemapBank = priority3SpriteMapBanks[i];
		renderSpriteToOAM(priority3SpriteMaps[i], priority3SpriteX[i], priority3SpriteY[i]);
	}
}

/// $C08C53 - It's hard to guess what this one did
void unknownC08C53() {
	//You Get: Nothing
}

/// $C08C54
void drawSpriteF(const(SpriteMap)* spriteMap, short x, short y) {
	drawSprite(spriteMap, x, y);
}

/// $C08C58
void drawSprite(const(SpriteMap)* spriteMap, short x, short y)
	in(spriteMap !is null, "Spritemap must not be null")
{
	addPriorityXSpriteFuncs[currentSpriteDrawingPriority](spriteMap, x, y);
}

/// $C08C65
immutable void function(const(SpriteMap)*, short, short)[4] addPriorityXSpriteFuncs = [
	&addPriority0Sprite,
	&addPriority1Sprite,
	&addPriority2Sprite,
	&addPriority3Sprite,
];

/// $C08C6D
void addPriority0Sprite(const(SpriteMap)* spriteMap, short x, short y)
	in(spriteMap !is null, "Trying to add a null spritemap")
{
	priority0SpriteMaps[priority0SpriteOffset / 2] = spriteMap;
	priority0SpriteX[priority0SpriteOffset / 2] = x;
	priority0SpriteY[priority0SpriteOffset / 2] = y;
	priority0SpriteMapBanks[priority0SpriteOffset / 2] = spritemapBank;
	priority0SpriteOffset += 2;
}

/// $C08C87
void addPriority1Sprite(const(SpriteMap)* spriteMap, short x, short y)
	in(spriteMap !is null, "Trying to add a null spritemap")
{
	priority1SpriteMaps[priority1SpriteOffset / 2] = spriteMap;
	priority1SpriteX[priority1SpriteOffset / 2] = x;
	priority1SpriteY[priority1SpriteOffset / 2] = y;
	priority1SpriteMapBanks[priority1SpriteOffset / 2] = spritemapBank;
	priority1SpriteOffset += 2;
}

/// $C08CA1
void addPriority2Sprite(const(SpriteMap)* spriteMap, short x, short y)
	in(spriteMap !is null, "Trying to add a null spritemap")
{
	priority2SpriteMaps[priority2SpriteOffset / 2] = spriteMap;
	priority2SpriteX[priority2SpriteOffset / 2] = x;
	priority2SpriteY[priority2SpriteOffset / 2] = y;
	priority2SpriteMapBanks[priority2SpriteOffset / 2] = spritemapBank;
	priority2SpriteOffset += 2;
}

/// $C08CBB
void addPriority3Sprite(const(SpriteMap)* spriteMap, short x, short y)
	in(spriteMap !is null, "Trying to add a null spritemap")
{
	priority3SpriteMaps[priority3SpriteOffset / 2] = spriteMap;
	priority3SpriteX[priority3SpriteOffset / 2] = x;
	priority3SpriteY[priority3SpriteOffset / 2] = y;
	priority3SpriteMapBanks[priority3SpriteOffset / 2] = spritemapBank;
	priority3SpriteOffset += 2;
}

/// $C08CD5 - Draw a SpriteMap list into the OAM buffer
void renderSpriteToOAM(const(SpriteMap)* arg1, short xbase, short ybase) {
	short xpos;
	short ypos;
	ubyte abyte;
	bool carry;
	const(SpriteMap)* y = arg1;
	OAMEntry* x = oamAddr;
	if (x >= oamEndAddr) {
		return;
	}
	//some DBR manipulation was here
	for(;;y++){
		assert(y, "Null sprite?");
		ypos = cast(byte)y.yOffset;
		if (ypos == 0x80) {
			// This is -1 since we do y++ due to continue
			y = y.nextMap - 1;
			continue;
		}
		ypos += ybase - 1;
		if ((ypos >= 0xE0) || (ypos < -32)) {
			if (y.specialFlags >= 0x80) {
				break;
			}
			continue;
		}
		x.startingTile = y.firstTile;
		x.flags = y.flags;
		xpos = cast(byte)y.xOffset;
		xpos += xbase;
		x.xCoord = cast(byte)xpos;
		if (xpos >= 0x100 || xpos < -0x100) {
			if (y.specialFlags >= 0x80) {
				break;
			}
			continue;
		}
		abyte = cast(ubyte)(xpos>>8);
		ROL(abyte, carry);
		oamHighTableBuffer = ROR(oamHighTableBuffer, carry);
		abyte = y.specialFlags;
		ROR(abyte, carry);
		oamHighTableBuffer = ROR(oamHighTableBuffer, carry);
		if (carry) {
			oamHighTableAddr[0] = oamHighTableBuffer;
			oamHighTableAddr++;
			oamHighTableBuffer = 0x80;
		}
		x.yCoord = cast(ubyte)ypos;
		x++;
		if (y.specialFlags >= 0x80 || x >= oamEndAddr) {
			break;
		}
	}
	oamAddr = x;
}

/// $C08D79
void setBGMODE(ubyte arg1) {
	mirrorBGMODE &= 0xF0;
	mirrorBGMODE |= arg1;
	BGMODE = mirrorBGMODE;
}

/// $C08D92
void setOAMSize(ubyte arg1) {
	mirrorOBSEL = arg1;
	OBSEL = arg1;
}

/// $C08D9E
void setBG1VRAMLocation(ubyte arg1, ushort arg2, ushort arg3) {
	mirrorBG1SC = arg1 & 3;
	mirrorBG1SC |= ((arg2 >> 8) & 0xFC);
	BG1SC = mirrorBG1SC;
	mirrorBG12NBA &= 0xF0;
	bg1XPosition = 0;
	bg1YPosition = 0;
	mirrorBG12NBA |= (arg3 >> 12);
	BG12NBA = mirrorBG12NBA;
}

/// $C08DDE
void setBG2VRAMLocation(ubyte arg1, ushort arg2, ushort arg3) {
	mirrorBG2SC = arg1 & 3;
	mirrorBG2SC |= ((arg2 >> 8) & 0xFC);
	BG2SC = mirrorBG2SC;
	mirrorBG12NBA &= 0xF;
	bg2XPosition = 0;
	bg2YPosition = 0;
	mirrorBG12NBA |= ((arg3 >> 8) & 0xF0);
	BG12NBA = mirrorBG12NBA;
}

/// $C08E1C
void setBG3VRAMLocation(ubyte arg1, ushort arg2, ushort arg3) {
	mirrorBG3SC = arg1 & 3;
	mirrorBG3SC |= ((arg2 >> 8) & 0xFC);
	BG3SC = mirrorBG3SC;
	mirrorBG34NBA &= 0xF0;
	bg3XPosition = 0;
	bg3YPosition = 0;
	mirrorBG34NBA |= (arg3 >> 12);
	BG34NBA = mirrorBG34NBA;
}

/// $C08E5C
void setBG4VRAMLocation(ubyte arg1, ushort arg2, ushort arg3) {
	mirrorBG4SC = arg1 & 3;
	mirrorBG4SC |= ((arg2 >> 8) & 0xFC);
	BG4SC = mirrorBG4SC;
	mirrorBG34NBA &= 0xF;
	bg4XPosition = 0;
	bg4YPosition = 0;
	mirrorBG34NBA |= ((arg3 >> 8) & 0xF0);
	BG34NBA = mirrorBG34NBA;
}

/// $C08E9A
ubyte rand() {
	ushort tmp = ror(cast(ushort)((cast(ushort)(randA << 8) >> 8) * (randB & 0xFF)), 2);
	randB = cast(ushort)(((randA << 8) | (randB & 0xFF)) + 0x6D);
	ushort tmp2 = ror(cast(ushort)((tmp & 3) + randA), 1);
	if (((tmp & 3 + randA) & 1) != 0) {
		tmp2 |= 0x8000;
	}
	randA = tmp2;
	return ror(tmp, 2) & 0xFF;
}

/// $C08F8B
void waitDMAFinished() {
	ubyte a = dmaQueueIndex;
	while (lastCompletedDMAIndex != a) { waitForInterrupt(); }
}

/// $C08F98
immutable UnknownC08F98Entry[4] unknownC08F98 = [
	UnknownC08F98Entry(0xFE80, 0x0100, 0x0200, 0x0000),
	UnknownC08F98Entry(0x0000, 0x0100, 0x0300, 0x0080),
	UnknownC08F98Entry(0x0000, 0x0200, 0x0200, 0x0000)
];

/// $C08FB0
immutable DMATableEntry[18] dmaTable = [
	DMATableEntry(0x01, 0x18, 0x80), /// A -> B
	DMATableEntry(0x09, 0x18, 0x80), /// A -> B
	DMATableEntry(0x00, 0x18, 0x00), /// A -> B
	DMATableEntry(0x08, 0x18, 0x00), /// A -> B
	DMATableEntry(0x00, 0x19, 0x80), /// A -> B
	DMATableEntry(0x08, 0x19, 0x80), /// A -> B
	DMATableEntry(0x81, 0x39, 0x80), /// B -> A
	DMATableEntry(0x80, 0x39, 0x00), /// B -> A
	DMATableEntry(0x80, 0x3A, 0x80), /// B -> A
	DMATableEntry(0x01, 0x18, 0x81), /// A -> B
	DMATableEntry(0x09, 0x18, 0x81), /// A -> B
	DMATableEntry(0x00, 0x18, 0x01), /// A -> B
	DMATableEntry(0x08, 0x18, 0x01), /// A -> B
	DMATableEntry(0x00, 0x19, 0x81), /// A -> B
	DMATableEntry(0x08, 0x19, 0x81), /// A -> B
	DMATableEntry(0x81, 0x39, 0x81), /// B -> A
	DMATableEntry(0x80, 0x39, 0x01), /// B -> A
	DMATableEntry(0x80, 0x3A, 0x81), /// B -> A
];

/// $C08FE6 - unused. these bytes happen to correspond to XBA / TYA opcodes, however
immutable ubyte[2] unknownC08FE6 = [ 0xEB, 0x98 ];

/// $C0927C
void unknownC0927C() {
	actionScriptDrawCallback = &actionScriptDrawEntities;
	firstEntity = -1;
	entityNextEntityTable[29] = -1;
	entityScriptNextScripts[69] = -1;
	lastEntity = 0;
	lastAllocatedScript = 0;
	short x = 56;
	do {
		entityNextEntityTable[x / 2] = cast(short)(x + 2);
		x -= 2;
	} while (x >= 0);

	x = 136;
	do {
		entityScriptNextScripts[x / 2] = cast(short)(x + 2);
		x -= 2;
	} while (x >= 0);

	x = 58;
	do {
		entityScriptTable[x / 2] = -1;
		x -= 2;
	} while (x >= 0);

	x = 58;
	do {
		entitySpriteMapFlags[x / 2] = 0;
		entityTickCallbacks[x / 2] = null;
		entityCallbackFlags[x / 2] = 0;
		x -= 2;
	} while (x >= 0);

	x = 6;
	do {
		entityBGHorizontalOffsetHigh[x / 2] = 0;
		entityBGVerticalOffsetHigh[x / 2] = 0;
		entityBGHorizontalVelocityLow[x / 2] = 0;
		entityBGHorizontalVelocityHigh[x / 2] = 0;
		entityBGVerticalVelocityLow[x / 2] = 0;
		entityBGVerticalVelocityHigh[x / 2] = 0;
		entityBGHorizontalOffsetLow[x / 2] = 0;
		entityBGVerticalOffsetLow[x / 2] = 0;
		entityDrawPriority[x / 2] = 0;
		x -= 2;
	} while (x >= 0);
	clearEntityDrawSortingTable();
	disableActionscript = 0;
}

/// $C09279
void unknownC09279() {
	assert(0, "Not used");
}

/// $C092F5
short initEntityWipe(short actionScript, short x, short y) {
	newEntityPosZ = 0;
	newEntityVar0 = 0;
	newEntityVar1 = 0;
	newEntityVar2 = 0;
	newEntityVar3 = 0;
	newEntityVar4 = 0;
	newEntityVar5 = 0;
	newEntityVar6 = 0;
	newEntityVar7 = 0;
	newEntityPriority = 0;
	entityAllocationMinSlot = 0;
	entityAllocationMaxSlot = 0x1E;
	return initEntity(actionScript, x, y);
}

/// $C09321
short initEntity(short actionScript, short x, short y) {
	entityAllocationMinSlot *= 2;
	entityAllocationMaxSlot *= 2;
	bool allocationFailed;
	short newEntity = allocateEntity(allocationFailed);
	if (allocationFailed) {
		return 0;
	}
	tracef("Initializing entity slot %s with %s at %s,%s", newEntity / 2, cast(ActionScript)actionScript, x, y);
	bool __ignored;
	short newScript = allocateScript(__ignored);
	entityScriptIndexTable[newEntity / 2] = newScript;
	entityScriptNextScripts[newScript / 2] = -1;
	entityMoveCallbacks[newEntity / 2] = &updateActiveEntityPosition2D;
	entityScreenPositionCallbacks[newEntity / 2] = &updateScreenPositionBG12D;
	entityDrawCallbacks[newEntity / 2] = &unknownC0A3A4;
	entityScriptVar0Table[newEntity / 2] = newEntityVar0;
	entityScriptVar1Table[newEntity / 2] = newEntityVar1;
	entityScriptVar2Table[newEntity / 2] = newEntityVar2;
	entityScriptVar3Table[newEntity / 2] = newEntityVar3;
	entityScriptVar4Table[newEntity / 2] = newEntityVar4;
	entityScriptVar5Table[newEntity / 2] = newEntityVar5;
	entityScriptVar6Table[newEntity / 2] = newEntityVar6;
	entityScriptVar7Table[newEntity / 2] = newEntityVar7;
	entityDrawPriority[newEntity / 2] = newEntityPriority;
	entityAbsXFractionTable[newEntity / 2] = 0x8000;
	entityAbsYFractionTable[newEntity / 2] = 0x8000;
	entityAbsZFractionTable[newEntity / 2] = 0x8000;
	entityScreenXTable[newEntity / 2] = x;
	entityAbsXTable[newEntity / 2] = x;
	entityScreenYTable[newEntity / 2] = y;
	entityAbsYTable[newEntity / 2] = y;
	entityAbsZTable[newEntity / 2] = newEntityPosZ;
	newEntity = appendActiveEntity(newEntity);
	//Unreachable code?
	/+
	unknownC09C99();
	short newScript2 = allocateScript(__ignored);
	entityScriptIndexTable[newEntity / 2] = newScript2;
	entityScriptNextScripts[newScript2 / 2] = -1;
	+/
	entityScriptTable[newEntity / 2] = actionScript;
	entityAnimationFrames[newEntity / 2] = -1;
	entityDeltaXFractionTable[newEntity / 2] = 0;
	entityDeltaXTable[newEntity / 2] = 0;
	entityDeltaYFractionTable[newEntity / 2] = 0;
	entityDeltaYTable[newEntity / 2] = 0;
	entityDeltaZFractionTable[newEntity / 2] = 0;
	entityDeltaZTable[newEntity / 2] = 0;
	return unknownC092F5Unknown4(&actionScriptScriptPointers[actionScript][0], newEntity);
}

short setEntityActionScript(const(ubyte)* pc, short entityID) {
	return setEntityActionScriptByOffset(pc, cast(short)(entityID * 2));
}
short setEntityActionScriptByOffset(const(ubyte)* pc, short entityIndex) {
	assert (entityScriptTable[entityIndex / 2] >= 0);
	entityIndex = unknownC09C99(entityIndex);
	bool __ignored;
	short newScript = allocateScript(__ignored);
	entityScriptIndexTable[entityIndex / 2] = newScript;
	entityScriptNextScripts[newScript / 2] = -1;
	return unknownC092F5Unknown4(pc, entityIndex);
}

short unknownC092F5Unknown4(const(ubyte)* pc, short entityIndex) {
	clearSpriteTickCallback(entityIndex);
	entityProgramCounters[entityScriptIndexTable[entityIndex / 2] / 2] = pc;
	entityScriptSleepFrames[entityScriptIndexTable[entityIndex / 2] / 2] = 0;
	entityScriptStackPosition[entityScriptIndexTable[entityIndex / 2] / 2] = 0;
	return entityIndex / 2;
}
//actually part of the previous function normally, but whatever
void movementNOP() {
	//nothin
}

/// $C0943C
void freezeEntities() {
	if (firstEntity < 0) {
		return;
	}
	auto x = firstEntity;
	do {
		entityCallbackFlags[x / 2] |= (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled);
		x = entityNextEntityTable[x / 2];
	} while(x >= 0);
}

/// $C09451
void unfreezeEntities() {
	short x = firstEntity;
	while (x >= 0) {
		entityCallbackFlags[x / 2] &= 0xFFFF ^ (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled);
		x = entityNextEntityTable[x / 2];
	}
}

/// $C09466
void runActionscriptFrame() {
	version(extra) {
		if (breakActionscript) {
			actionScriptDrawCallback();
			return;
		}
	}
	if (disableActionscript != 0) {
		return;
	}
	// jump to slowrom goes here

	// make sure that if we somehow end up calling this function recursively
	// that we don't end up running scripts again
	disableActionscript = 1;
	if (firstEntity < 0) {
		disableActionscript = 0;
		return;
	}
	actionScriptScriptOffset = 0;
	unread86 = 0;
	short x = firstEntity;
	do {
		currentActiveEntityOffset = x;
		currentEntityOffset = x;
		currentEntitySlot = x;
		currentEntitySlot /= 2;
		nextActiveEntity = entityNextEntityTable[currentEntitySlot];
		runEntityScripts(nextActiveEntity,x);
	} while ((x = nextActiveEntity) >= 0);
	if (firstEntity < 0) {
		disableActionscript = 0;
		return;
	}
	x = firstEntity;
	do {
		currentEntitySlot = x;
		currentEntitySlot /= 2;
		currentActiveEntityOffset = x;
		if ((entityCallbackFlags[currentEntitySlot] & EntityCallbackFlags.moveDisabled) == 0) {
			entityMoveCallbacks[currentEntitySlot]();
		}
		entityScreenPositionCallbacks[currentEntitySlot]();
		x = entityNextEntityTable[currentActiveEntityOffset / 2];
	} while(x >= 0);
	actionScriptDrawCallback();
	disableActionscript = 0;
}

/// $C09466
void runEntityScripts(short a, short x) {
	if ((entityCallbackFlags[x / 2] & EntityCallbackFlags.moveDisabled) == 0) {
		short y = entityScriptIndexTable[x / 2];
		do {
			currentEntityScriptOffset = y;
			currentScriptOffset = y;
			currentScriptSlot = y / 2;
			actionScriptCurrentScript = entityScriptNextScripts[y / 2];
			runEntityScript();
			y = actionScriptCurrentScript;
		} while (y > 0);
		x = currentActiveEntityOffset;
	}
	if ((entityCallbackFlags[x / 2] & EntityCallbackFlags.tickDisabled) == 0) {
		currentEntityTickCallback = entityTickCallbacks[x / 2];
		callEntityTickCallback();
	}
}

/// $C09506
void runEntityScript() {
	if (entityScriptSleepFrames[currentEntityScriptOffset / 2] != 0) {
		entityScriptSleepFrames[currentEntityScriptOffset / 2]--;
		return;
	}
	const(ubyte)* ystart, y = entityProgramCounters[currentEntityScriptOffset / 2];
	//ActionScript82 = EntityProgramCounterBanks[currentEntityScriptOffset / 2];
	actionScriptStack = &entityScriptStacks[currentEntityScriptOffset / 2][0];
	do {
		ystart = y;
		ubyte a = (y++)[actionScriptScriptOffset];
		debug(actionscript) printActionscriptCommand(currentEntitySlot, ystart);
		if (a < 0x70) {
			y = movementControlCodesPointerTable[a](y);
		} else {
			actionScriptVar90 = a;
			entityScriptSleepFrames[currentEntityScriptOffset / 2] = a & 0xF;
			y = movementControlCodesPointerTable[0x45 + ((actionScriptVar90 & 0x70) >> 4)](y);
		}
		version(extra) {
			if (entityExtra[currentEntitySlot].breakpoint) {
				breakActionscript = 1;
				entityProgramCounters[currentEntityScriptOffset / 2] = y;
				// don't decrease sleep frames here, might cause underflow
				return;
			}
		}
	} while (entityScriptSleepFrames[currentEntityScriptOffset / 2] == 0);
	entityProgramCounters[currentEntityScriptOffset / 2] = y;
	//EntityProgramCounterBanks[currentEntityScriptOffset / 2] = ActionScript82;
	entityScriptSleepFrames[currentEntityScriptOffset / 2]--;
}

immutable const(ubyte)* function(const(ubyte)*)[77] movementControlCodesPointerTable = [
	&actionScriptCommand00,
	&actionScriptCommand01,
	&actionScriptCommand02,
	&actionScriptCommand03,
	&actionScriptCommand04,
	&actionScriptCommand05,
	&actionScriptCommand06,
	&actionScriptCommand07,
	&actionScriptCommand08,
	&actionScriptCommand09,
	&actionScriptCommand0A,
	&actionScriptCommand0B,
	&actionScriptCommand0C,
	&actionScriptCommand0D,
	&actionScriptCommand0E,
	&actionScriptCommand0F,
	&actionScriptCommand10,
	&actionScriptCommand11,
	&actionScriptCommand12,
	&actionScriptCommand13,
	&actionScriptCommand14,
	&actionScriptCommand15,
	&actionScriptCommand16,
	&actionScriptCommand17,
	&actionScriptCommand18,
	&actionScriptCommand19,
	&actionScriptCommand1A,
	&actionScriptCommand1B,
	&actionScriptCommand1C,
	&actionScriptCommand1D,
	&actionScriptCommand1E,
	&actionScriptCommand1F,
	&actionScriptCommand20,
	&actionScriptCommand21,
	&actionScriptCommand22,
	&actionScriptCommand23,
	&actionScriptCommand24,
	&actionScriptCommand25,
	&actionScriptCommand26,
	&actionScriptCommand27,
	&actionScriptCommand28,
	&actionScriptCommand29,
	&actionScriptCommand2A,
	&actionScriptCommand2B,
	&actionScriptCommand2C,
	&actionScriptCommand2D,
	&actionScriptCommand2E,
	&actionScriptCommand2F,
	&actionScriptCommand30,
	&actionScriptCommand31,
	&actionScriptCommand32,
	&actionScriptCommand33,
	&actionScriptCommand34,
	&actionScriptCommand35,
	&actionScriptCommand36,
	&actionScriptCommand37,
	&actionScriptCommand38,
	&actionScriptCommand39,
	&actionScriptCommand3A,
	&actionScriptCommand3B45,
	&actionScriptCommand3C46,
	&actionScriptCommand3D47,
	&actionScriptCommand3E48,
	&actionScriptCommand3F49,
	&actionScriptCommand404A,
	&actionScriptCommand414B,
	&actionScriptCommand424C,
	&actionScriptCommand43,
	&actionScriptCommand44,
	&actionScriptCommand3B45,
	&actionScriptCommand3C46,
	&actionScriptCommand3D47,
	&actionScriptCommand3E48,
	&actionScriptCommand3F49,
	&actionScriptCommand404A,
	&actionScriptCommand414B,
	&actionScriptCommand424C,
];

/// $C095F2 - [00] - End
const(ubyte)* actionScriptCommand00(const(ubyte)* y) {
	deleteEntityOffset(currentActiveEntityOffset);
	entityScriptSleepFrames[currentEntityScriptOffset / 2] = -1;
	actionScriptCurrentScript = -1;
	return y;
}

/// $C09603 - [01 XX] - Loop XX times
const(ubyte)* actionScriptCommand01(const(ubyte)* y) {
	return actionScriptCommand0124Common(y[actionScriptScriptOffset], currentEntityScriptOffset, y + 1);
}
const(ubyte)* actionScriptCommand0124Common(short a, short x, const(ubyte)* y) {
	actionScriptVar90 = a;
	actionScriptLastRead = y;
	actionScriptStack[entityScriptStackPosition[x / 2] / 3].pc = y;
	actionScriptStack[entityScriptStackPosition[x / 2] / 3].counter = cast(ubyte)a;
	entityScriptStackPosition[x / 2] += 3;
	return y;
}

/// $C09620 - [24] - Loop (Tempvar)
const(ubyte)* actionScriptCommand24(const(ubyte)* y) {
	return actionScriptCommand0124Common(entityScriptTempvars[currentEntityScriptOffset / 2], currentEntityScriptOffset, y);
}

/// $C09627 - [02] - Loop End
const(ubyte)* actionScriptCommand02(const(ubyte)* y) {
	actionScriptLastRead = y;
	if (--actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3 - 1].counter == 0) {
		entityScriptStackPosition[currentEntityScriptOffset / 2] -= 3;
		return actionScriptLastRead;
	}
	return actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3 - 1].pc;
}

/// $C09649 - [19 NEARPTR] - Short Jump
const(ubyte)* actionScriptCommand19(const(ubyte)* y) {
	return *cast(const(ubyte)**)&y[actionScriptScriptOffset];
}

/// $C0964D - [03 PTR] - Long Jump
const(ubyte)* actionScriptCommand03(const(ubyte)* y) {
	return *cast(const(ubyte)**)&y[actionScriptScriptOffset];
}

/// $C09658 - [1A NEARPTR] - Short Call
const(ubyte)* actionScriptCommand1A(const(ubyte)* y) {
	const(ubyte)* result = *cast(const(ubyte)**)&y[actionScriptScriptOffset];
	actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3].pc = y + (const(ubyte)*).sizeof;
	entityScriptStackPosition[currentEntityScriptOffset / 2] += 3;
	return result;
}

/// $C0966F - [1B] - Short Return
const(ubyte)* actionScriptCommand1B(const(ubyte)* y) {
	if (entityScriptStackPosition[currentEntityScriptOffset / 2] == 0) {
		return actionScriptCommand0C(null);
	} else {
		entityScriptStackPosition[currentEntityScriptOffset / 2] -= 3;
		return actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3].pc;
	}
}

/// $C09685 - [04 PTR] - Long Call
const(ubyte)* actionScriptCommand04(const(ubyte)* y) {
	const(ubyte)* result = *cast(const(ubyte)**)&y[actionScriptScriptOffset];
	actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3].pc = y + (const(ubyte)*).sizeof;
	entityScriptStackPosition[currentEntityScriptOffset / 2] += 3;
	return result;
}

/// $C096AA - [05] - Long Return
const(ubyte)* actionScriptCommand05(const(ubyte)* y) {
	if (entityScriptStackPosition[currentEntityScriptOffset / 2] == 0) {
		return actionScriptCommand0C(null);
	} else {
		entityScriptStackPosition[currentEntityScriptOffset / 2] -= 3;
		return actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3].pc;
	}
}

/// $C096C3 - [06 XX] - Pause XX frames
const(ubyte)* actionScriptCommand06(const(ubyte)* y) {
	entityScriptSleepFrames[currentEntityScriptOffset / 2] = y[actionScriptScriptOffset];
	return y + 1;
}

/// $C096CF - [3B/45 XX] - Set Animation Frame
const(ubyte)* actionScriptCommand3B45(const(ubyte)* y) {
	entityAnimationFrames[currentActiveEntityOffset / 2] = y[actionScriptScriptOffset] == 0xFF ? -1 : y[actionScriptScriptOffset];
	return y + 1;
}

/// $C096E3 - [28 XXXX] - Set X
const(ubyte)* actionScriptCommand28(const(ubyte)* y) {
	entityAbsXTable[currentActiveEntityOffset / 2] = *cast(short*)&y[actionScriptScriptOffset];
	entityAbsXFractionTable[currentActiveEntityOffset / 2] = 0x8000;
	return y + 2;
}

/// $C096F3 - [29 XXXX] - Set Y
const(ubyte)* actionScriptCommand29(const(ubyte)* y) {
	entityAbsYTable[currentActiveEntityOffset / 2] = *cast(short*)&y[actionScriptScriptOffset];
	entityAbsYFractionTable[currentActiveEntityOffset / 2] = 0x8000;
	return y + 2;
}

/// $C09703 - [2A XXXX] - Set Z
const(ubyte)* actionScriptCommand2A(const(ubyte)* y) {
	entityAbsZTable[currentActiveEntityOffset / 2] = *cast(short*)&y[actionScriptScriptOffset];
	entityAbsZFractionTable[currentActiveEntityOffset / 2] = 0x8000;
	return y + 2;
}

/// $C09713
const(ubyte)* actionScriptCommand3F49(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	y += 2;
	entityDeltaXFractionTable[currentActiveEntityOffset / 2] = cast(ushort)(actionScriptVar90 << 8);
	entityDeltaXTable[currentActiveEntityOffset / 2] = actionScriptVar90 >> 8;
	return y;
}

/// $C09731
const(ubyte)* actionScriptCommand404A(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	y += 2;
	entityDeltaYFractionTable[currentActiveEntityOffset / 2] = cast(ushort)(actionScriptVar90 << 8);
	entityDeltaYTable[currentActiveEntityOffset / 2] = actionScriptVar90 >> 8;
	return y;
}

/// $C0974F
const(ubyte)* actionScriptCommand414B(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	y += 2;
	entityDeltaZFractionTable[currentActiveEntityOffset / 2] = cast(ushort)(actionScriptVar90 << 8);
	entityDeltaZTable[currentActiveEntityOffset / 2] = actionScriptVar90 >> 8;
	return y;
}

/// $C0976D
const(ubyte)* actionScriptCommand2E(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	auto i = currentActiveEntityOffset / 2;
	auto param = FixedPoint1616(cast(ushort)(actionScriptVar90 << 8), cast(short)(actionScriptVar90 >> 8));
	auto prev = FixedPoint1616(entityDeltaXFractionTable[i], entityDeltaXTable[i]);
	prev.combined += param.combined;
	entityDeltaXFractionTable[i] = prev.fraction;
	entityDeltaXTable[i] = prev.integer;
	return y + 2;
}

/// $C09792
const(ubyte)* actionScriptCommand2F(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	auto i = currentActiveEntityOffset / 2;
	auto param = FixedPoint1616(cast(ushort)(actionScriptVar90 << 8), cast(short)(actionScriptVar90 >> 8));
	auto prev = FixedPoint1616(entityDeltaYFractionTable[i], entityDeltaYTable[i]);
	prev.combined += param.combined;
	entityDeltaYFractionTable[i] = prev.fraction;
	entityDeltaYTable[i] = prev.integer;
	return y + 2;
}

/// $C097B7
const(ubyte)* actionScriptCommand30(const(ubyte)* y) {
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	auto i = currentActiveEntityOffset / 2;
	auto param = FixedPoint1616(cast(ushort)(actionScriptVar90 << 8), cast(short)(actionScriptVar90 >> 8));
	auto prev = FixedPoint1616(entityDeltaZFractionTable[i], entityDeltaZTable[i]);
	prev.combined += param.combined;
	entityDeltaZFractionTable[i] = prev.fraction;
	entityDeltaZTable[i] = prev.integer;
	return y + 2;
}

/// $C097DC
const(ubyte)* actionScriptCommand31(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	entityBGHorizontalOffsetLow[x] = *cast(short*)&y[actionScriptScriptOffset];
	entityBGHorizontalOffsetHigh[x] = 0;
	return y + 2;
}

/// $C097EF
const(ubyte)* actionScriptCommand32(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	entityBGVerticalOffsetLow[x] = *cast(short*)&y[actionScriptScriptOffset];
	entityBGVerticalOffsetHigh[x] = 0;
	return y + 2;
}

/// $C09802
const(ubyte)* actionScriptCommand33(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	entityBGHorizontalVelocityHigh[x] = cast(short)((actionScriptVar90 & 0xFF) << 8);
	entityBGHorizontalVelocityLow[x] = cast(short)((actionScriptVar90 & 0x8000) ? ((actionScriptVar90 & 0xFF00) | 0xFF) : (actionScriptVar90 & 0xFF00));
	return y + 2;
}

/// $C09826
const(ubyte)* actionScriptCommand34(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	entityBGVerticalVelocityHigh[x] = cast(short)((actionScriptVar90 & 0xFF) << 8);
	entityBGVerticalVelocityLow[x] = cast(short)((actionScriptVar90 & 0x8000) ? ((actionScriptVar90 & 0xFF00) | 0xFF) : (actionScriptVar90 & 0xFF00));
	return y + 2;
}

/// $C0984A
const(ubyte)* actionScriptCommand35(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	entityBGHorizontalVelocityHigh[x] += (actionScriptVar90 & 0xFF) << 8;
	entityBGHorizontalVelocityLow[x] += (actionScriptVar90 & 0x8000) ? ((actionScriptVar90 & 0xFF00) | 0xFF) : (actionScriptVar90 & 0xFF00);
	return y + 2;
}

/// $C09875
const(ubyte)* actionScriptCommand36(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = *cast(short*)&y[actionScriptScriptOffset];
	entityBGVerticalVelocityHigh[x] += (actionScriptVar90 & 0xFF) << 8;
	entityBGVerticalVelocityLow[x] += (actionScriptVar90 & 0x8000) ? ((actionScriptVar90 & 0xFF00) | 0xFF) : (actionScriptVar90 & 0xFF00);
	return y + 2;
}

/// $C098A0
const(ubyte)* actionScriptCommand2B(const(ubyte)* y) {
	entityAbsXTable[currentActiveEntityOffset / 2] += *cast(short*)&y[actionScriptScriptOffset];
	return y + 2;
}

/// $C098AE
const(ubyte)* actionScriptCommand2C(const(ubyte)* y) {
	entityAbsYTable[currentActiveEntityOffset / 2] += *cast(short*)&y[actionScriptScriptOffset];
	return y + 2;
}

/// $C098BC
const(ubyte)* actionScriptCommand2D(const(ubyte)* y) {
	entityAbsZTable[currentActiveEntityOffset / 2] += *cast(short*)&y[actionScriptScriptOffset];
	return y + 2;
}

/// $C098CA
const(ubyte)* actionScriptCommand37(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	entityBGHorizontalOffsetLow[x] += *cast(short*)&y[actionScriptScriptOffset];
	return y + 2;
}

/// $C098DE
const(ubyte)* actionScriptCommand38(const(ubyte)* y) {
	ubyte x = (y++)[actionScriptScriptOffset];
	entityBGVerticalOffsetLow[x] += *cast(short*)&y[actionScriptScriptOffset];
	return y + 2;
}

/// $C098F2
const(ubyte)* actionScriptCommand39(const(ubyte)* y) {
	entityDeltaXFractionTable[currentActiveEntityOffset / 2] = 0;
	entityDeltaXTable[currentActiveEntityOffset / 2] = 0;
	entityDeltaYFractionTable[currentActiveEntityOffset / 2] = 0;
	entityDeltaYTable[currentActiveEntityOffset / 2] = 0;
	entityDeltaZFractionTable[currentActiveEntityOffset / 2] = 0;
	entityDeltaZTable[currentActiveEntityOffset / 2] = 0;
	return y;
}

/// $C09907
void unknownC09907(short arg1) {
	entityDeltaXFractionTable[arg1] = 0;
	entityDeltaXTable[arg1] = 0;
	entityDeltaYFractionTable[arg1] = 0;
	entityDeltaYTable[arg1] = 0;
	entityDeltaZFractionTable[arg1] = 0;
	entityDeltaZTable[arg1] = 0;
}

/// $C0991C
const(ubyte)* actionScriptCommand3A(const(ubyte)* y) {
	entityBGHorizontalVelocityHigh[y[actionScriptScriptOffset]] = 0;
	entityBGHorizontalVelocityLow[y[actionScriptScriptOffset]] = 0;
	entityBGVerticalVelocityHigh[y[actionScriptScriptOffset]] = 0;
	entityBGVerticalVelocityLow[y[actionScriptScriptOffset]] = 0;
	return y + 1;
}

/// $C09931
const(ubyte)* actionScriptCommand43(const(ubyte)* y) {
	entityDrawPriority[currentActiveEntityOffset / 2] = (y++)[actionScriptScriptOffset];
	return y;
}

/// $C0993D
const(ubyte)* actionScriptCommand424C(const(ubyte)* y) {
	alias Func = short function(short a, ref const(ubyte)* y);
	Func f = *cast(Func*)&y[actionScriptScriptOffset];
	actionScriptLastRead = y + Func.sizeof;
	entityScriptTempvars[currentEntityScriptOffset / 2] = f(entityScriptTempvars[currentEntityScriptOffset / 2], actionScriptLastRead);
	return actionScriptLastRead;
}

/// $C0995D
const(ubyte)* actionScriptCommand0A(const(ubyte)* y) {
	if (entityScriptTempvars[currentEntityScriptOffset / 2] == 0) {
		return *cast(const(ubyte)**)&y[actionScriptScriptOffset];
	}
	return y + (const(ubyte)*).sizeof;
}

/// $C0996B
const(ubyte)* actionScriptCommand0B(const(ubyte)* y) {
	if (entityScriptTempvars[currentEntityScriptOffset / 2] != 0) {
		return *cast(const(ubyte)**)&y[actionScriptScriptOffset];
	}
	return y + (const(ubyte)*).sizeof;
}

/// $C09979
const(ubyte)* actionScriptCommand10(const(ubyte)* y) {
	actionScriptVar90 = entityScriptTempvars[currentEntityScriptOffset / 2];
	actionScriptLastRead = y + 1;
	if (y[actionScriptScriptOffset] <= actionScriptVar90) {
		return actionScriptLastRead + y[actionScriptScriptOffset] * (const(ubyte)*).sizeof;
	} else {
		return (cast(const(ubyte)**)actionScriptLastRead)[actionScriptVar90];
	}
}

/// $C0999E
const(ubyte)* actionScriptCommand11(const(ubyte)* y) {
	actionScriptVar90 = entityScriptTempvars[currentEntityScriptOffset / 2];
	actionScriptLastRead = y + 1;
	if (y[actionScriptScriptOffset] <= actionScriptVar90) {
		return actionScriptLastRead + y[actionScriptScriptOffset] * (const(ubyte)*).sizeof;
	} else {
		actionScriptStack[entityScriptStackPosition[currentEntityScriptOffset / 2] / 3].pc = actionScriptLastRead + y[actionScriptScriptOffset] * (const(ubyte)*).sizeof;
		entityScriptStackPosition[currentEntityScriptOffset / 2] += 3;
		return (cast(const(ubyte)**)actionScriptLastRead)[actionScriptVar90];
	}
}

/// $C099C3
const(ubyte)* actionScriptCommand0C(const(ubyte)* y) {
	actionScriptLastRead = y;
	return actionScriptCommand0C13Common(currentEntityScriptOffset);
}
const(ubyte)* actionScriptCommand0C13Common(short y) {
	ushort regY = unknownC09D12(currentActiveEntityOffset, y);
	entityScriptSleepFrames[regY / 2] = -1;
	if (entityScriptIndexTable[currentActiveEntityOffset / 2] < 0) {
		actionScriptCommand00(null);
	}
	return actionScriptLastRead;
}

/// $C099DD
const(ubyte)* actionScriptCommand07(const(ubyte)* y) {
	actionScriptLastRead = y;
	bool carry;
	short regY = allocateScript(carry);
	if (!carry) {
		actionScriptCurrentScript = regY;
		entityScriptNextScripts[regY / 2] = entityScriptNextScripts[currentEntityScriptOffset / 2];
		entityScriptNextScripts[currentEntityScriptOffset / 2] = regY;
		entityScriptStackPosition[regY / 2] = 0;
		entityScriptSleepFrames[regY / 2] = 0;
		entityProgramCounters[regY / 2] = *cast(const(ubyte)**)&y[actionScriptScriptOffset];
		///blah blah blah bank
		return y + (const(ubyte)*).sizeof;
	}
	return y + (const(ubyte)*).sizeof;
}

/// $C09A0E
const(ubyte)* actionScriptCommand13(const(ubyte)* y) {
	actionScriptLastRead = y;
	if (entityScriptNextScripts[currentEntityScriptOffset / 2] >= 0) {
		return actionScriptCommand0C13Common(entityScriptNextScripts[currentEntityScriptOffset / 2]);
	}
	return actionScriptLastRead;
}

/// $C09A1A
const(ubyte)* actionScriptCommand08(const(ubyte)* y) {
	entityTickCallbacks[currentActiveEntityOffset / 2] = *cast(void function()*)&y[actionScriptScriptOffset];
	entityCallbackFlags[currentActiveEntityOffset / 2] = 0;
	y += (const(ubyte)*).sizeof;
	//banks!
	return y;
}

/// $C09A2E
const(ubyte)* actionScriptCommand09(const(ubyte)* y) {
	entityScriptSleepFrames[currentEntityScriptOffset / 2] = -1;
	return y - 1;
}

/// $C09A38
const(ubyte)* actionScriptCommand3C46(const(ubyte)* y) {
	entityAnimationFrames[currentActiveEntityOffset / 2]++;
	return y;
}

/// $C09A3E
const(ubyte)* actionScriptCommand3D47(const(ubyte)* y) {
	entityAnimationFrames[currentActiveEntityOffset / 2]--;
	return y;
}

/// $C09A44
const(ubyte)* actionScriptCommand3E48(const(ubyte)* y) {
	entityAnimationFrames[currentActiveEntityOffset / 2] += cast(byte)y[actionScriptScriptOffset];
	return y + 1;
}

/// $C09A5C
const(ubyte)* actionScriptCommand18(const(ubyte)* y) {
	actionScriptVar8CMemory = *cast(ushort**)&y[actionScriptScriptOffset];
	y += (ushort*).sizeof;
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = (y++)[actionScriptScriptOffset];
	unknownC09ABD[x]();
	return y;
}

/// $C09A87
const(ubyte)* actionScriptCommand14(const(ubyte)* y) {
	return actionScriptCommand0D14Common(cast(ushort*)&entityScriptVarTables[y[actionScriptScriptOffset]][currentActiveEntityOffset / 2], y);
}

/// $C09A97
const(ubyte)* actionScriptCommand27(const(ubyte)* y) {
	return actionScriptCommand0D27Common(cast(ushort*)&entityScriptTempvars[currentEntityScriptOffset / 2], y);
}

/// $C09A9F
const(ubyte)* actionScriptCommand0D(const(ubyte)* y) {
	return actionScriptCommand0D14Common(*cast(ushort**)y[actionScriptScriptOffset], y + (ushort*).sizeof - 1);
}

const(ubyte)* actionScriptCommand0D14Common(ushort* a, const(ubyte)* y) {
	return actionScriptCommand0D27Common(a, y + 1);
}
const(ubyte)* actionScriptCommand0D27Common(ushort* a, const(ubyte)* y) {
	actionScriptVar8CMemory = a;
	ubyte x = (y++)[actionScriptScriptOffset];
	actionScriptVar90 = *(cast(short*)&y[actionScriptScriptOffset]);
	y += 2;
	unknownC09ABD[x]();
	return y;
}

/// $C09ABD
immutable void function()[4] unknownC09ABD = [
	&unknownC09AC5,
	&unknownC09ACC,
	&unknownC09AD3,
	&unknownC09ADB,
];

/// $C09AC5
void unknownC09AC5() {
	actionScriptVar8CMemory[0] &= actionScriptVar90;
}

/// $C09ACC
void unknownC09ACC() {
	actionScriptVar8CMemory[0] |= actionScriptVar90;
}

/// $C09AD3
void unknownC09AD3() {
	actionScriptVar8CMemory[0] += actionScriptVar90;
}

/// $C09ADB
void unknownC09ADB() {
	actionScriptVar8CMemory[0] ^= actionScriptVar90;
}

/// $C09AE2
const(ubyte)* actionScriptCommand0E(const(ubyte)* y) {
	entityScriptVarTables[y[actionScriptScriptOffset]][currentActiveEntityOffset / 2] = *cast(short*)&y[1 + actionScriptScriptOffset];
	return y + 3;
}

/// $C09AF9
short*[8] entityScriptVarTables = [
	&entityScriptVar0Table[0],
	&entityScriptVar1Table[0],
	&entityScriptVar2Table[0],
	&entityScriptVar3Table[0],
	&entityScriptVar4Table[0],
	&entityScriptVar5Table[0],
	&entityScriptVar6Table[0],
	&entityScriptVar7Table[0],
];

/// $C09B09
const(ubyte)* actionScriptCommand0F(const(ubyte)* y) {
	clearSpriteTickCallback(currentActiveEntityOffset);
	return y;
}

/// $C09B0F - [12 NEARPTR XX] - Write XX to memory
const(ubyte)* actionScriptCommand12(const(ubyte)* y) {
	*(*cast(ubyte**)&y[actionScriptScriptOffset]) = y[(ubyte*).sizeof + actionScriptScriptOffset];
	return y + (ubyte*).sizeof + ubyte.sizeof;
}

/// $C09B1F - [15 NEARPTR XXXX] - Write XXXX to memory
const(ubyte)* actionScriptCommand15(const(ubyte)* y) {
	*(*cast(ushort**)&y[actionScriptScriptOffset]) = *cast(ushort*)&y[(ushort*).sizeof + actionScriptScriptOffset];
	return y + (ushort*).sizeof + ushort.sizeof;
}

/// $C09B2C - [16 NEARPTR] - Break if false
const(ubyte)* actionScriptCommand16(const(ubyte)* y) {
	if (entityScriptTempvars[currentEntityScriptOffset / 2] == 0) {
		y = *cast(const(ubyte)**)&y[actionScriptScriptOffset];
		entityScriptStackPosition[currentEntityScriptOffset / 2] -= 3;
		return y;
	}
	return y + (const(ubyte)*).sizeof;
}

/// $C09B44 - [17 NEARPTR] - Break if true
const(ubyte)* actionScriptCommand17(const(ubyte)* y) {
	if (entityScriptTempvars[currentEntityScriptOffset / 2] != 0) {
		y = *cast(const(ubyte)**)&y[actionScriptScriptOffset];
		entityScriptStackPosition[currentEntityScriptOffset / 2] -= 3;
		return y;
	}
	return y + (const(ubyte)*).sizeof;
}

/// $C09B4D - [1C PTR] - Set Spritemap
const(ubyte)* actionScriptCommand1C(const(ubyte)* y) {
	// The only stuff that uses this command uses a double pointer for its spritemaps
	entitySpriteMapPointers[currentActiveEntityOffset / 2] = null;
	entitySpriteMapPointersDptr[currentActiveEntityOffset / 2] = *cast(const(SpriteMap*)**)&y[actionScriptScriptOffset];
	y += (const(SpriteMap*)*).sizeof;
	return y;
}

/// $C09B61 - [1D XXXX] - Write word to tempvar
const(ubyte)* actionScriptCommand1D(const(ubyte)* y) {
	entityScriptTempvars[currentEntityScriptOffset / 2] = *cast(ushort*)&y[actionScriptScriptOffset];
	return y + ushort.sizeof;
}

/// $C09B6B - [1E NEARPTR] - Write data at address to tempvar
const(ubyte)* actionScriptCommand1E(const(ubyte)* y) {
	entityScriptTempvars[currentEntityScriptOffset / 2] = *(*cast(ushort**)&y[actionScriptScriptOffset]);
	return y + (ushort*).sizeof;
}

/// $C09B79 - [1F XX] - Write tempvar to var
const(ubyte)* actionScriptCommand1F(const(ubyte)* y) {
	ubyte x = y[actionScriptScriptOffset];
	actionScriptVar8CMemory = cast(ushort*)entityScriptVarTables[x];
	actionScriptVar8CMemory[0] = entityScriptTempvars[currentEntityScriptOffset / 2];
	return y + 1;
}

/// $C09B91 - [20 XX] - Write var to tempvar
const(ubyte)* actionScriptCommand20(const(ubyte)* y) {
	entityScriptTempvars[currentEntityScriptOffset / 2] = (cast(ushort*)entityScriptVarTables[y[actionScriptScriptOffset]])[currentActiveEntityOffset / 2];
	return y + 1;
}

/// $C09BA9 - [44] - Sleep for $tempvar frames
const(ubyte)* actionScriptCommand44(const(ubyte)* y) {
	if (entityScriptTempvars[currentEntityScriptOffset / 2] != 0) {
		entityScriptSleepFrames[currentEntityScriptOffset / 2] = entityScriptTempvars[currentEntityScriptOffset / 2];
	}
	return y;
}

/// $C09BB4 - [21 XX] - Sleep for var XX frames
const(ubyte)* actionScriptCommand21(const(ubyte)* y) {
	entityScriptSleepFrames[currentEntityScriptOffset / 2] = (cast(ushort*)entityScriptVarTables[y[actionScriptScriptOffset]])[currentActiveEntityOffset / 2];
	return y + 1;
}

/// $C09BCC - [26 XX] - Set Animation Frame to Var XX
const(ubyte)* actionScriptCommand26(const(ubyte)* y) {
	entityAnimationFrames[currentActiveEntityOffset / 2] = entityScriptVarTables[(y++)[actionScriptScriptOffset]][currentActiveEntityOffset / 2];
	return y;
}

/// $C09BE4 - [22 NEARPTR] - Set Draw Callback
const(ubyte)* actionScriptCommand22(const(ubyte)* y) {
	entityDrawCallbacks[currentActiveEntityOffset / 2] = *cast(void function(short, short)*)&y[actionScriptScriptOffset];
	y += (void function(short)).sizeof;
	return y;
}

/// $C09BEE - [23 NEARPTR] - Set Position Change Callback
const(ubyte)* actionScriptCommand23(const(ubyte)* y) {
	entityScreenPositionCallbacks[currentActiveEntityOffset / 2] = *cast(void function()*)&y[actionScriptScriptOffset];
	y += (void function()).sizeof;
	return y;
}

/// $C09BF8 - [25 NEARPTR] - Set Physics Callback
const(ubyte)* actionScriptCommand25(const(ubyte)* y) {
	entityMoveCallbacks[currentActiveEntityOffset / 2] = *cast(void function()*)&y[actionScriptScriptOffset];
	y += (void function()).sizeof;
	return y;
}

/// $C09C02 - allocates an entity slot
short allocateEntity(out bool flag) {
	if (lastAllocatedScript < 0) {
		flag = true;
		return -1; //actually just whatever was in the X register when called
	}
	if (lastEntity < 0) {
		flag = true;
		return -1; //actually just whatever was in the X register when called
	}
	short x = lastEntity;
	short y = -1;
	while (true) {
		if ((x >= entityAllocationMinSlot) && (x < entityAllocationMaxSlot)) {
			break;
		}
		y = x;
		if (entityNextEntityTable[x / 2] < 0) {
			flag = true;
			return x;
		}
		x = entityNextEntityTable[x / 2];
	}
	if (y >= 0) {
		entityNextEntityTable[y / 2] = entityNextEntityTable[x / 2];
		flag = false;
		return x;
	} else {
		lastEntity = entityNextEntityTable[x / 2];
		flag = false;
		return x;
	}
}

/// $C09C35
void deleteEntity(short entity) {
	deleteEntityOffset(cast(short)(entity * 2));
}

/// $C09C3B
//note: arg1 is passed via X register
void deleteEntityOffset(short offset) {
	tracef("Deleting entity %s", offset / 2);
	if (entityScriptTable[offset / 2] >= 0) {
		entityScriptTable[offset / 2] = -1;
		clearSpriteTickCallback(offset);
		short x = unknownC09C99(offset);
		short a = lastAllocatedScript;
		deleteActiveEntry(a, x);
		unknownC09C8F(x);
	}
}

/// $C09C57
short appendActiveEntity(short index) {
	entityNextEntityTable[index / 2] = -1;
	if (firstEntity >= 0) {
		short x, y = firstEntity;
		while ((x = entityNextEntityTable[y / 2]) >= 0) { y = x; }
		entityNextEntityTable[y / 2] = index;
		return index;
	} else {
		firstEntity = index;
		return index;
	}
}

/// $C09C73
void deleteActiveEntry(short a, short entry) {
	short foundEntry = searchNextEntityTable(entry);
	if (foundEntry != -1) {
		entityNextEntityTable[foundEntry / 2] = entityNextEntityTable[entry / 2];
	} else {
		firstEntity = entityNextEntityTable[entry / 2];
	}
	if (entry == nextActiveEntity) {
		nextActiveEntity = a;
	}
}

/// $C09C8F
void unknownC09C8F(short x) {
	entityNextEntityTable[x / 2] = lastEntity;
	lastEntity = x;
}

/// $C09C99
short unknownC09C99(short offset) {
	if (entityScriptIndexTable[offset / 2] < 0) {
		return offset;
	}
	short lastAllocatedScriptCopy = lastAllocatedScript;
	short x = offset;
	short a = entityScriptIndexTable[x / 2];
	lastAllocatedScript = a;
	do {
		x = a;
		a = entityScriptNextScripts[x / 2];
	} while(a >= 0);
	entityScriptNextScripts[x / 2] = lastAllocatedScriptCopy;
	return offset;
}

/// $C09CB5
short searchNextEntityTable(short needle) {
	short tmp = needle;
	short foundEntry = -1;
	tmp = firstEntity;
	do {
		if (tmp == needle) {
			return foundEntry;
		}
		foundEntry = tmp;
		tmp = entityNextEntityTable[tmp / 2];
	} while(true);
}

/// $C09CD7
void unknownC09CD7() {
	short a = -32768;
	short x = lastEntity;
	while (x >= 0) {
		short y = entityNextEntityTable[x / 2];
		entityNextEntityTable[x / 2] = a;
		x = y;
	}
	x = 0x3A;
	short y = -1;
	do {
		if (entityNextEntityTable[x / 2] == -32768) {
			entityNextEntityTable[x / 2] = y;
			y = x;
		}
		x -= 2;
	} while (x >= 0);
	lastEntity = y;
}

/// $C09D03 - allocates a script slot
short allocateScript(out bool flag) {
	short result = lastAllocatedScript;
	if (result < 0) {
		flag = true;
		return result;
	}
	lastAllocatedScript = entityScriptNextScripts[result / 2];
	flag = false;
	return result;
}

/// $C09D12
ushort unknownC09D12(short x, short y) {
	unknownC09D1F(x, y);
	entityScriptNextScripts[y / 2] = lastAllocatedScript;
	lastAllocatedScript = y;
	return y;
}

/// $C09D1F
void unknownC09D1F(short x, short y) {
	short tmpX;
	y = unknownC09D3E(x, y, tmpX);
	if (tmpX != -1) {
		entityScriptNextScripts[tmpX / 2] = entityScriptNextScripts[y / 2];
	} else {
		entityScriptIndexTable[x / 2] = entityScriptNextScripts[y / 2];
	}
	if (y == actionScriptCurrentScript) {
		actionScriptCurrentScript = entityScriptNextScripts[y / 2];
	}
}

/// $C09D3E
short unknownC09D3E(short x, short y, out short finalX) {
	short tmpY = y;
	y = entityScriptIndexTable[x / 2];
	x = -1;
	while (true) {
		if (y == tmpY) {
			break;
		}
		x = y;
		y = entityScriptNextScripts[x / 2];
	}
	finalX = x;
	return tmpY;
}

/// $C09D86
ushort movementDataRead8(ref const(ubyte)* arg1) {
	ushort a = arg1[actionScriptScriptOffset];
	arg1++;
	return a;
}

/// $C09D94
ushort movementDataRead16(ref const(ubyte)* arg1) {
	ushort a = *cast(const(ushort)*)&arg1[actionScriptScriptOffset];
	arg1 += 2;
	return a;
}

/// $C09D99 - Same as movementDataRead16, but with a short return
ushort movementDataRead16Copy(ref const(ubyte)* arg1) {
	ushort a = *cast(const(ushort)*)&arg1[actionScriptScriptOffset];
	arg1 += 2;
	return a;
}

/// does not exist in original game
void* movementDataReadPtr(ref const(ubyte)* arg1) {
	void* a = *cast(void**)&arg1[actionScriptScriptOffset];
	arg1 += (void*).sizeof;
	return a;
}

/// does not exist in original game
string movementDataReadString(ref const(ubyte)* arg1) {
	string a = *cast(string*)&arg1[actionScriptScriptOffset];
	arg1 += string.sizeof;
	return a;
}

/// $C09D9E
void callEntityTickCallback() {
	currentEntityTickCallback();
}

/// $C09DA1
void clearSpriteTickCallback(short index) {
	entityTickCallbacks[index / 2] = &movementNOP;
	entityCallbackFlags[index / 2] = 0;
}

/// $C09E71
short unknownC09E71(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16Copy(arg2);
	// initEntityWipe takes 3 arguments but this code only prepares one of them...
	short x = void;
	actionScriptLastRead = arg2;
	return initEntityWipe(tmp, x, cast(short)actionScriptLastRead);
}

/// Tests if the active entity is moving somewhere. Stores possible destination in entityMovementProspectX/Y
/// Returns: number of axes movement is occurring on
/// Original_Address: $(DOLLAR)C09EFF
short testEntityMovementActive() {
	return testEntityMovementCommon(currentEntityOffset);
}

/// Tests if the active entity(?) is moving somewhere. Stores possible destination in entityMovementProspectX/Y. Unused
/// Returns: number of axes movement is occurring on
/// Original_Address: $(DOLLAR)C09EFF
short testEntityMovementUnusedEntry() {
	return testEntityMovementCommon(currentActiveEntityOffset);
}

/// Tests if an arbitrary entity is moving somewhere. Stores possible destination in entityMovementProspectX/Y
/// Params: id = entity ID
/// Returns: number of axes movement is occurring on
/// Original_Address: $(DOLLAR)C09EFF
short testEntityMovementSlot(short id) {
	return testEntityMovementCommon(cast(short)(id * 2));
}

/// Tests if an active entity (offset) is moving somewhere. Stores possible destination in entityMovementProspectX/Y
/// Returns: number of axes movement is occurring on
/// Params: offset = entity offset (ID * 2)
/// Mutates:
///	entityMovementProspectX = X coordinate that the entity is attempting to move to
///	entityMovementProspectY = Y coordinate that the entity is attempting to move to
/// Original_Address: $(DOLLAR)C09EFF
//note: arg1 was X register originally
short testEntityMovementCommon(short offset) {
	short axes = 0;
	entityMovementProspectX = cast(short)((fullEntityAbsX(offset / 2).combined + fullEntityDeltaX(offset / 2).combined) >> 16);
	if (entityMovementProspectX != entityAbsXTable[offset / 2]) {
		axes++;
	}
	entityMovementProspectY = cast(short)((fullEntityAbsY(offset / 2).combined + fullEntityDeltaY(offset / 2).combined) >> 16);
	if (entityMovementProspectY != entityAbsYTable[offset / 2]) {
		axes++;
	}
	return axes;
}

/// $C09F3B
void unknownC09F3BUnusedEntry() {
	currentEntityOffset = -1;
	backupEntityCallbackFlagsAndDisable();
}

/// Backs up all entity callback flags and freezes each active entity
/// Original_Address: $(DOLLAR)C09F3B
void backupEntityCallbackFlagsAndDisable() {
	for (short i = 0; i != maxEntities * 2; i += 2) {
		entityCallbackFlagsBackup[i / 2] = entityCallbackFlags[i / 2];
	}
	if (firstEntity < 0) {
		return;
	}
	short x = firstEntity;
	while (true) {
		if (x != currentEntityOffset) {
			entityCallbackFlags[x / 2] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
		}
		x = entityNextEntityTable[x / 2];
		if (x <= 0) {
			break;
		}
	}
}

/// Restores entity callback flags from backup
/// Original_Address: $(DOLLAR)C09F71
void restoreEntityCallbackFlags() {
	for (short i = 0; i != maxEntities * 2; i += 2) {
		entityCallbackFlags[i / 2] = entityCallbackFlagsBackup[i / 2];
	}
}

/// $C09F82
short chooseRandom(short, ref const(ubyte)* arg1) {
	actionScriptVar90 = arg1[actionScriptScriptOffset];
	actionScriptLastRead = arg1 + 1;
	const tmp = actionScriptLastRead;
	actionScriptLastRead += actionScriptVar90 * 2;
	return (cast(const(short)*)tmp)[rand() % actionScriptVar90];
}

/// $C09FA8
short actionScriptGenerateRandomAngle() {
	return cast(short)(rand() << 8);
}

/// $C09FAE
void actionScriptFadeIn(short, ref const(ubyte)* arg1) {
	ubyte a = (arg1++)[actionScriptScriptOffset];
	ubyte b = (arg1++)[actionScriptScriptOffset];
	fadeIn(a, b);
}

/// $C09FC8
void updateActiveEntityPosition2D() {
	updateEntityPosition2D(currentActiveEntityOffset);
}

/// $C09FB0
void updateEntityPosition2D(short arg1) {
	short i = arg1 / 2;
	FixedPoint1616 newPosition;

	newPosition.combined = fullEntityAbsX(i).combined + fullEntityDeltaX(i).combined;
	entityAbsXTable[i] = newPosition.integer;
	entityAbsXFractionTable[i] = newPosition.fraction;

	newPosition.combined = fullEntityAbsY(i).combined + fullEntityDeltaY(i).combined;
	entityAbsYTable[i] = newPosition.integer;
	entityAbsYFractionTable[i] = newPosition.fraction;
}

/// $C09FAE
void actionScriptFadeOut(short, ref const(ubyte)* arg1) {
	ubyte a = (arg1++)[actionScriptScriptOffset];
	ubyte b = (arg1++)[actionScriptScriptOffset];
	fadeOut(a, b);
}

/// $C09F??
void actionScriptNoPhysics() {
	//nothing!
}

/// $C09FF1
void updateEntityPosition3D() {
	updateActiveEntityPosition2D();
	FixedPoint1616 newPosition;

	newPosition.combined = fullEntityAbsZ(currentActiveEntityOffset / 2).combined + fullEntityDeltaZ(currentActiveEntityOffset / 2).combined;
	entityAbsZFractionTable[currentActiveEntityOffset / 2] = newPosition.fraction;
	entityAbsZTable[currentActiveEntityOffset / 2] = newPosition.integer;
	unknownC0C7DB();
}

/// $C0A00C
void updateEntityPosition3DIgnoreSurface() {
	updateActiveEntityPosition2D();
	entityAbsZFractionTable[currentActiveEntityOffset / 2] += entityDeltaZFractionTable[currentActiveEntityOffset / 2];
	entityAbsZTable[currentActiveEntityOffset / 2] += entityDeltaZTable[currentActiveEntityOffset / 2];
}

/// $C0A023
void updateScreenPositionBG12D() {
	entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg1XPosition);
	entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg1YPosition);
}

/// $C0A039
void unknownC0A039() {
	//nothing
}

/// $C0A03A
void updateScreenPositionBG13D() {
	entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg1XPosition);
	entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg1YPosition - entityAbsZTable[currentActiveEntityOffset / 2]);
}

/// $C0A055
void updateScreenPositionBG32D() {
	entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg3XPosition);
	entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg3YPosition);
}

/// $C0A06C
void moveRelativeToBG3() {
	entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg3XPosition);
	entityAbsXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg3XPosition);
	entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg3YPosition);
	entityAbsYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg3YPosition);
}

/// $C0A0A0
void updateScreenPositionBG13DDupe() {
	entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg3XPosition);
	entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg3YPosition - entityAbsZTable[currentActiveEntityOffset / 2]);
}

/// $C0A0BB
void updateEntityPositionAbsolute() {
	entityScreenXTable[currentActiveEntityOffset / 2] = entityAbsXTable[currentActiveEntityOffset / 2];
	entityScreenYTable[currentActiveEntityOffset / 2] = entityAbsYTable[currentActiveEntityOffset / 2];
}

/// $C0A0CA
void actionScriptDrawEntity(short entityOffset) {
	assert(entityOffset >= 0);
	currentActiveEntityOffset = cast(ushort)(entityOffset * 2);
	unknownC0A0E3(currentActiveEntityOffset, (entityOffset * 2) < 0);
}

/// $C0A0E3
void unknownC0A0E3(short arg1, bool overflowed) {
	if (((entitySpriteMapFlags[arg1 / 2] & SpriteMapFlags.drawDisabled) != 0) || overflowed) {
		return;
	}
	actionScriptSpritemap = entitySpriteMapPointers[arg1 / 2];
	if (entityAnimationFrames[arg1 / 2] >= 0) {
		entityDrawCallbacks[arg1 / 2](entityAnimationFrames[arg1 / 2], arg1);
	}
}

/// $C0A0FA
void unknownC0A0FA(short arg1, short arg2) {
	spritemapBank = actionScriptSpritemapBank;
	currentSpriteDrawingPriority = entityDrawPriority[arg2 / 2];
	// This uses a double pointer to the spritemap, indexed by the animation frame.
	// Don't use the value in 8C!
	drawSprite(entitySpriteMapPointersDptr[arg2 / 2][arg1], entityAbsXTable[arg2 / 2], entityAbsYTable[arg2 / 2]);
}

/// $C0A11C
void checkHardware() {
	//AntiPiracyScratchSpace = 0x30;
	//AntiPiracyMirrorTest = 0x31;
	if (false/*AntiPiracyScratchSpace != AntiPiracyMirrorTest*/) {
		displayAntiPiracyScreen();
	}
	if ((STAT78 & 0x10) != 0) {
		displayFaultyGamepakScreen();
	}
}

/// $C0A1??
short loadMapBlockF(short x, short y) {
	return loadMapBlock(x, y);
}

/// Loads the map block at (x,y)
/// Params:
///	x = X coordinate of the block
///	y = Y coordinate of the block
/// Mutates:
///	cachedMapBlockX = cached X coordinate
///	cachedMapBlockY = cached Y coordinate
/// Original_Address: $(DOLLAR)C0A156
short loadMapBlock(short x, short y) {
	if ((x | y) < 0) {
		return -1;
	}
	if ((x == cachedMapBlockX) && (y == cachedMapBlockY)) {
		return cachedMapBlock;
	}
	cachedMapBlockX = x;
	cachedMapBlockY = y;

	ushort tmp1 = mapBlockArrangements[8 + !!(y & 4)][((y / 8) * 256) | x];
	ushort upperBits;
	switch (y & 7) {
		case 3:
		case 7:
			tmp1 /= 4;
			goto case;
		case 2:
		case 6:
			tmp1 /= 4;
			goto case;
		case 1:
		case 5:
			tmp1 /= 4;
			goto case;
		case 0:
		case 4:
			upperBits = (tmp1 & 3) * 256;
			break;
		default: assert(0);
	}
	ushort tmp = mapBlockArrangements[y & 7][((y / 8) * 256) | x];
	cachedMapBlock = (cast(ubyte)tmp) | upperBits;
	return cachedMapBlock;
}

unittest {
	if (romDataLoaded) {
		assert(loadMapBlock(0xF8, 0x2C) == 0xA7);
	}
}

/// $C0A1F2
void copyMapPaletteFrame(short arg1) {
	const(ubyte)* source = cast(const(ubyte)*)animatedMapPaletteBuffers[arg1];
	ubyte* destination = cast(ubyte*)&palettes[2][0];
	short bytesLeft = 0xBF;
	while (--bytesLeft >= 0) {
		*(destination++) = *(source++);
	}
	paletteUploadMode = PaletteUpload.halfFirst;
}

__gshared const ubyte*[8] animatedMapPaletteBuffers;

/// $C0A21C
short unknownC0A21C(short arg1) {
	short y = firstEntity;
	while (y >= 0) {
		if (arg1 == entityNPCIDs[y / 2]) {
			return arg1;
		}
		y = entityNextEntityTable[y / 2];
	}
	return 0;
}

/// $C0A254
void recalculateEntityScreenPosition(short arg1) {
	entityScreenXTable[arg1] = cast(short)(entityAbsXTable[arg1] - bg1XPosition);
	entityScreenYTable[arg1] = cast(short)(entityAbsYTable[arg1] - bg1YPosition);
}

/// $C0A26B
void unknownC0A26B() {
	if ((currentActiveEntityOffset == currentLeadingPartyMemberEntity) || ((entityScriptVar7Table[currentActiveEntityOffset / 2] & 0) != 0) || (notMovingInSameDirectionFaced != 0) || (entityDirections[currentActiveEntityOffset / 2] != currentLeaderDirection) || (unknownC0A350[entityDirections[currentActiveEntityOffset / 2]](currentLeadingPartyMemberEntity) * 2 != 0)) {
		entityScreenXTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsXTable[currentActiveEntityOffset / 2] - bg1XPosition);
		entityScreenYTable[currentActiveEntityOffset / 2] = cast(short)(entityAbsYTable[currentActiveEntityOffset / 2] - bg1YPosition);
	}
	//return currentActiveEntityOffset;
}

/// $C0A2AB
immutable short[6] unknownC0A2AB = [ 0, 17, 32, 47, 62, 77 ];

/// $C0A2B7
short unknownC0A2B7(short arg1) {
	short a = entityScreenXTable[arg1 / 2] ^ entityScreenXTable[currentActiveEntityOffset / 2];
	if (a != 0) {
		return a;
	}
	a = cast(short)(entityAbsYTable[arg1 / 2] - entityAbsYTable[currentActiveEntityOffset / 2]);
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	a -= unknownC0A2AB[entityScriptVar5Table[currentActiveEntityOffset / 2] / 2];
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	if (a == 0) {
		return a;
	}
	return cast(short)(a - 1);
}

/// $C0A2E1
short unknownC0A2E1(short arg1) {
	short a = entityScreenYTable[arg1 / 2] ^ entityScreenYTable[currentActiveEntityOffset / 2];
	if (a != 0) {
		return a;
	}
	a = cast(short)(entityAbsXTable[arg1 / 2] - entityAbsXTable[currentActiveEntityOffset / 2]);
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	a -= unknownC0A2AB[entityScriptVar5Table[currentActiveEntityOffset / 2] / 2];
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	if (a == 0) {
		return a;
	}
	return cast(short)(a - 1);
}

/// $C0A30B
immutable short[6] unknownC0A30B = [ 0, 11, 22, 32, 43, 54 ];

/// $C0A317
short unknownC0A317(short arg1) {
	short a = cast(short)(entityAbsXTable[arg1 / 2] - entityAbsXTable[currentActiveEntityOffset / 2]);
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	short actionScriptVar00s = a;
	if (actionScriptVar00s < unknownC0A30B[entityScriptVar5Table[currentActiveEntityOffset / 2] / 2]) {
		return actionScriptVar00s;
	}
	a = cast(short)(entityAbsYTable[arg1 / 2] - entityAbsYTable[currentActiveEntityOffset / 2]);
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	a -= actionScriptVar00s;
	if (a == 0) {
		return a;
	}
	if (a < 0) {
		a = cast(short)-cast(int)a;
	}
	return cast(short)(a - 1);
}

/// $C0A350
immutable short function(short)[8] unknownC0A350 = [
	&unknownC0A2B7,
	&unknownC0A317,
	&unknownC0A2E1,
	&unknownC0A317,
	&unknownC0A2B7,
	&unknownC0A317,
	&unknownC0A2E1,
	&unknownC0A317,
];

/// $C0A360
void unknownC0A360() {
	if (entityPathfindingState[currentActiveEntityOffset / 2] >= 0) {
		if ((entityObstacleFlags[currentActiveEntityOffset / 2] & 0xD0) != 0) {
			actionScriptCommand39(null);
			return;
		} else if ((entityCollidedObjects[currentActiveEntityOffset / 2] & 0x8000) == 0) {
			return;
		}
	}
	unknownC0A37ACommon(currentActiveEntityOffset);
}

/// $C0A37A
void unknownC0A37A() {
	unknownC0A37ACommon(currentActiveEntityOffset);
}

void unknownC0A37ACommon(short arg1) {
	updateEntityPosition2D(arg1);
	unknownC0C7DB();
}

/// $C0A384
void unknownC0A384() {
	if (entityPathfindingState[currentActiveEntityOffset / 2] >= 0) {
		if ((entityObstacleFlags[currentActiveEntityOffset / 2] & 0xD0) != 0) {
			actionScriptCommand39(null);
			return;
		} else if ((entityCollidedObjects[currentActiveEntityOffset / 2] & 0x8000) == 0) {
			return;
		}
	}
	unknownC0A384Common(currentActiveEntityOffset);
}

// unused
void unknownC0A384Alt() {
	unknownC0A384Common(currentActiveEntityOffset);
}

void unknownC0A384Common(short arg1) {
	updateEntityPosition2D(arg1);
}

/// $C0A3A4
// originally handwritten assembly, id was actually an offset
void unknownC0A3A4(short, short id) {
	if ((entityCurrentDisplayedSprites[id / 2] !is null) && ((entityCurrentDisplayedSprites[id / 2].lsb & 1) != 0)) {
		actionScriptSpritemap += entitySpriteMapSizes[id / 2] / 5;
	}
	ubyte upperBodyPriority = 3 << 4;
	ubyte lowerBodyPriority = 3 << 4;
	if ((entitySurfaceFlags[id / 2] & SurfaceFlags.obscureLowerBody) != 0) {
		lowerBodyPriority = 2 << 4;
	}
	if ((entitySurfaceFlags[id / 2] & SurfaceFlags.obscureUpperBody) != 0) {
		upperBodyPriority = 2 << 4;
	}
	byte y = -1;
	for (ubyte i = entityUpperLowerBodyDivide[id / 2] >> 8; (--i & 0x80) == 0; ) {
		y++;
		(cast()actionScriptSpritemap[y]).flags = (actionScriptSpritemap[y].flags & 0xCF) | upperBodyPriority;
	}
	for (ubyte i = entityUpperLowerBodyDivide[currentActiveEntityOffset / 2] & 0xFF; (--i & 0x80) == 0; ) {
		y++;
		(cast()actionScriptSpritemap[y]).flags = (actionScriptSpritemap[y].flags & 0xCF) | lowerBodyPriority;
	}
	spritemapBank = actionScriptSpritemapBank;
	currentSpriteDrawingPriority = entityDrawPriority[currentActiveEntityOffset / 2];
	if ((entityDrawPriority[currentActiveEntityOffset / 2] & DrawPriority.parent) != 0) {
		// if parent bit is set, use parent entity's draw priority
		currentSpriteDrawingPriority = entityDrawPriority[currentSpriteDrawingPriority & 0x3F];
		// clear the priority unless otherwise requested
		if ((entityDrawPriority[currentActiveEntityOffset / 2] & DrawPriority.dontClearIfParent) == 0) {
			entityDrawPriority[currentActiveEntityOffset / 2] = 0;
		}
	}
	unknownC0AC43();
	spritemapBank = actionScriptSpritemapBank;
	drawSprite(actionScriptSpritemap, entityScreenXTable[currentActiveEntityOffset / 2], entityScreenYTable[currentActiveEntityOffset / 2]);
}

/// $C0A443
//what a mess
void unknownC0A443() {
	ubyte actionScriptVar00 = (playerHasMovedSinceMapLoad + currentEntitySlot >> 3) & 1;
	ubyte actionScriptVar02 = cast(ubyte)((entityDirections[currentActiveEntityOffset / 2] * 2) | actionScriptVar00);
	if (((entityWalkingStyles[currentActiveEntityOffset / 2] >> 8) | ((entityWalkingStyles[currentActiveEntityOffset / 2] &0xFF) << 8) | actionScriptVar02) == entityAnimationFingerprints[currentActiveEntityOffset / 2]) {
		return;
	}
	entityAnimationFingerprints[currentActiveEntityOffset / 2] = cast(short)((entityWalkingStyles[currentActiveEntityOffset / 2] >> 8) | ((entityWalkingStyles[currentActiveEntityOffset / 2] &0xFF) << 8) | actionScriptVar02);

	updateEntitySpriteCurrentCommon();
}

/// $C0A472
void updateEntitySpriteCurrentFrameCounter() {
	useSecondSpriteFrame = (frameCounter >> 3) & 1;
	updateEntitySpriteCurrentCommon();
}
void updateEntitySpriteCurrent() {
	updateEntitySpriteByFrameVarCommon(currentActiveEntityOffset);
}
void updateEntitySprite(short arg1) {
	updateEntitySpriteByFrameVarCommon(cast(short)(arg1 * 2));
}
void updateEntitySpriteByFrameVarCommon(short arg1) {
	useSecondSpriteFrame = entityAnimationFrames[arg1 / 2];
	updateEntitySpriteOffset(arg1);
}
void updateEntitySpriteCurrentFrame0() {
	useSecondSpriteFrame = 0;
	// BUG: The result is never checked. The game uses the stack address to determine whether or not to update the sprite.
	// The function fails to update sprites in several cases anyway, so there's nothing that needs to be fixed here...
	unknownC0C711();
	if (1 != 0) {
		updateEntitySpriteCurrentCommon();
	}
}
void updateEntitySpriteCurrentFrame1() {
	useSecondSpriteFrame = 1;
	// see above
	unknownC0C711();
	if (1 != 0) {
		updateEntitySpriteCurrentCommon();
	}
}
void updateEntitySpriteCurrentFrame0Forced() {
	useSecondSpriteFrame = 0;
	updateEntitySpriteCurrentCommon();
}
void updateEntitySpriteCurrentCommon() {
	updateEntitySpriteOffset(currentActiveEntityOffset);
}
void updateEntitySpriteOffset(short arg1) {
	ubyte actionScriptVar00 = cast(ubyte)(entityTileHeights[arg1 / 2]);
	dmaCopySize = entityByteWidths[arg1 / 2];
	dmaCopyVRAMDestination = entityVramAddresses[arg1 / 2];
	//x04 = EnttiyGraphicsPointerHigh[arg1 / 2]
	OverworldSpriteGraphics* x02 = entityGraphicsPointers[arg1 / 2];
	assert(x02 !is null, "No sprite to update!");
	if (spriteDirectionMappings4Direction[entityDirections[arg1 / 2]] != 0) {
		for (short i = spriteDirectionMappings4Direction[entityDirections[arg1 / 2]]; i > 0; i--) {
			x02 += 2;
		}
	}
	if (useSecondSpriteFrame != 0) {
		x02 += 1;
	}
	if (((x02.lsb & 2) == 0) && (entitySurfaceFlags[arg1 / 2] & SurfaceFlags.shallowWater) != 0) {
		dmaCopyMode = 3;
		dmaCopyRAMSource = &blankTiles;
		uploadSpriteTileRow();
		if (--actionScriptVar00 == 0) {
			return;
		}
		if ((entitySurfaceFlags[arg1 / 2] & SurfaceFlags.causesSunstroke) != 0) {
			uploadSpriteTileRow();
			if (--actionScriptVar00 == 0) {
				return;
			}
		}
	}
	entityCurrentDisplayedSprites[arg1 / 2] = x02;
	//Original code:
	//dmaCopyRAMSource = cast(void*)((*x02) & 0xFFF0);
	//dmaCopyRAMSource + 2 = UNKNOWN_30X2_TABLE_31[arg1 / 2];
	dmaCopyRAMSource = sprites[x02.id].ptr;
	dmaCopyMode = 0;
	while (true) {
		uploadSpriteTileRow();
		if (--actionScriptVar00 == 0) {
			return;
		}
		dmaCopyRAMSource += dmaCopySize;
	}
}

/// $C0A56E
void uploadSpriteTileRow() {
	if (((((dmaCopySize / 2) + dmaCopyVRAMDestination - 1) ^ dmaCopyVRAMDestination) & 0x100) != 0) {
		const(void)* dmaCopyRAMSourceCopy = dmaCopyRAMSource;
		ushort dmaCopySizeCopy = dmaCopySize;
		ushort dmaCopyVRAMDestinationCopy = dmaCopyVRAMDestination;
		dmaCopySize = cast(ushort)((((dmaCopyVRAMDestination + 0x100) & 0xFF00) - dmaCopyVRAMDestination) * 2);
		copyToVRAMCommon();
		dmaCopyRAMSource += dmaCopySize;
		dmaCopyVRAMDestination = cast(ushort)(((dmaCopyVRAMDestination + 0x100) & 0xFF00) + 0x100);
		dmaCopySize = cast(ushort)(dmaCopySizeCopy - dmaCopySize);
		copyToVRAMCommon();
		dmaCopyVRAMDestination = dmaCopyVRAMDestinationCopy;
		dmaCopySize = dmaCopySizeCopy;
		dmaCopyRAMSource = dmaCopyRAMSourceCopy;
	} else {
		copyToVRAMCommon();
	}
	if ((dmaCopyVRAMDestination & 0x100) == 0) {
		dmaCopyVRAMDestination += 0x100;
		return;
	}
	if (((((((dmaCopySize + 0x20) & 0xFFC0) / 2) + dmaCopyVRAMDestination) ^ dmaCopyVRAMDestination) & 0x100) != 0) {
		dmaCopyVRAMDestination = cast(ushort)((((dmaCopySize + 0x20) & 0xFFC0) / 2) + dmaCopyVRAMDestination);
	} else {
		dmaCopyVRAMDestination = cast(ushort)((((dmaCopySize + 0x20) & 0xFFC0) / 2) + dmaCopyVRAMDestination - 0x100);
	}
}

/// $C0A60B
ushort[12] spriteDirectionMappings4Direction = [0, 0, 1, 2, 2, 2, 3, 0, 4, 5, 6, 7];

/// $C0A623
ushort[8] spriteDirectionMappings8Direction = [0, 4, 1, 5, 2, 6, 3, 7];

/// $C0A643
void unknownC0A643(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	entityNPCIDs[currentActiveEntityOffset / 2] = setDirection(tmp, arg2);
}

/// $C0A651
short setDirection8(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	entityMovingDirection[currentActiveEntityOffset / 2] = setDirection(tmp, arg2);
	return 0;
}

/// $C0A65F
short setDirection(short arg1, ref const(ubyte)*) {
	if (entityPathfindingState[currentActiveEntityOffset / 2] >= 0) {
		entityDirections[currentActiveEntityOffset / 2] = arg1;
	}
	return arg1;
}

/// $C0A66D
void unknownC0A66D(short arg1) {
	entityDirections[currentActiveEntityOffset / 2] = arg1;
}

/// $C0A673
short unknownC0A673() {
	return entityDirections[currentActiveEntityOffset / 2];
}

/// $C0A679
short setSurfaceFlags(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	entitySurfaceFlags[currentActiveEntityOffset / 2] = tmp;
	return 0;
}

/// $C0A685
void actionScriptSetMovementSpeedConstant(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	setMovementSpeed(tmp, arg2);
}

/// $C0A685
void setMovementSpeed(short arg1, ref const(ubyte)* arg2) {
	entityMovementSpeed[currentActiveEntityOffset / 2] = arg1;
}

/// $C0A691
short getMovementSpeed() {
	return entityMovementSpeed[currentActiveEntityOffset / 2];
}

/// $C0A6A2
void unknownC0A6A2(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC0CA4E(tmp);
}

/// $C0A6AD
void unknownC0A6AD(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC0CBD3(tmp);
}

/// $C0A6B8
short unknownC0A6B8() {
	short tmp = 0;
	if ((entityCollidedObjects[currentActiveEntityOffset / 2] & 0x8000) == 0) {
		tmp--;
	}
	return tmp;
}

/// $C0A6DA
short clearCurrentEntityCollision(short, ref const(ubyte)* arg2) {
	entityCollidedObjects[currentActiveEntityOffset / 2] = 0xFFFF;
	return 0;
}

/// $C0A6D1
short disableCurrentEntityCollision(short, ref const(ubyte)* arg2) {
	entityCollidedObjects[currentActiveEntityOffset / 2] = 0x8000;
	return 0;
}

/// $C0A6E3
void unknownC0A6E3() {
	short a;
	spriteUpdateEntityOffset = currentActiveEntityOffset;
	// new direction this frame?
	if (((entityWalkingStyles[currentActiveEntityOffset / 2] >> 8) | entityDirections[currentActiveEntityOffset / 2]) != entityAnimationFingerprints[currentActiveEntityOffset / 2]) {
		entityAnimationFingerprints[currentActiveEntityOffset / 2] = (entityWalkingStyles[currentActiveEntityOffset / 2] >> 8) | entityDirections[currentActiveEntityOffset / 2];
		updateEntitySpriteFrameCurrent();
		return;
	}
	if (entityScriptVar7Table[currentActiveEntityOffset / 2] < 0) {
		entityScriptVar7Table[currentActiveEntityOffset / 2] &= ~PartyMemberMovementFlags.unknown15;
		goto Unknown5;
	}
	// animation frame updated
	if ((entityScriptVar7Table[currentActiveEntityOffset / 2] & PartyMemberMovementFlags.unknown13) != 0) {
		if (entityAnimationFrames[currentActiveEntityOffset / 2] == 0) {
			goto Unknown6;
		} else {
			entityAnimationFrames[currentActiveEntityOffset / 2] = 0;
			goto Unknown5;
		}
	}
	if (battleSwirlCountdown != 0) {
		goto Unknown6;
	}
	if (--entityScriptVar2Table[currentActiveEntityOffset / 2] > 0) {
		goto Unknown6;
	}
	entityScriptVar2Table[currentActiveEntityOffset / 2] = entityScriptVar3Table[currentActiveEntityOffset / 2];
	entityAnimationFrames[currentActiveEntityOffset / 2] ^= 2;
	if (entityAnimationFrames[currentActiveEntityOffset / 2] != 0) {
		goto Unknown5;
	}
	if (currentActiveEntityOffset == footstepSoundIgnoreEntity) {
		goto Unknown5;
	}
	a = footstepSoundTable[(footstepSoundIDOverride == 0) ? (footstepSoundID / 2) : (footstepSoundIDOverride / 2)];
	if ((a != 0) && (disabledTransitions == 0)) {
		playSfx(a);
	}
	Unknown5:
	updateEntitySpriteFrameCurrent();
	Unknown6:
	if (psiTeleportDestination != 0) {
		return;
	}
	if (playerIntangibilityFrames == 0) {
		return;
	}
	if (playerIntangibilityFrames < 45) {
		a = playerIntangibilityFrames & 3;
	} else if ((playerIntangibilityFrames & 1) == 0) {
		a = cast(short)(entitySpriteMapFlags[currentActiveEntityOffset / 2] | SpriteMapFlags.drawDisabled);
	} else {
		a = entitySpriteMapFlags[currentActiveEntityOffset / 2] & ~SpriteMapFlags.drawDisabled;
	}
	entitySpriteMapFlags[currentActiveEntityOffset / 2] = a;
}

/// $C0A780
void updateEntitySpriteFrame(short arg1) {
	spriteUpdateEntityOffset = cast(short)(arg1 * 2);
	updateEntitySpriteFrameCurrent();
}

/// $C0A794
void updateEntitySpriteFrameCurrent() {
	ushort x00 = entityTileHeights[spriteUpdateEntityOffset / 2];
	dmaCopySize = entityByteWidths[spriteUpdateEntityOffset / 2];
	dmaCopyVRAMDestination = entityVramAddresses[spriteUpdateEntityOffset / 2];
	const(OverworldSpriteGraphics)* x02 = (entityGraphicsPointers[spriteUpdateEntityOffset / 2] + spriteDirectionMappings8Direction[entityDirections[spriteUpdateEntityOffset / 2]] * 2 + entityAnimationFrames[spriteUpdateEntityOffset / 2] / 2);
	if (((x02.lsb & 2) == 0) && ((entitySurfaceFlags[spriteUpdateEntityOffset / 2] & SurfaceFlags.shallowWater) != 0)) {
		dmaCopyMode = 3;
		dmaCopyRAMSource = &blankTiles;
		uploadSpriteTileRow();
		if (--x00 == 0) {
			return;
		}
		if ((entitySurfaceFlags[spriteUpdateEntityOffset / 2] & SurfaceFlags.causesSunstroke) != 0) {
			uploadSpriteTileRow();
			x00--;
			return;
		}
	}
	entityCurrentDisplayedSprites[spriteUpdateEntityOffset / 2] = x02;
	//Original code:
	//dmaCopyRAMSource = (*x02) & 0xFFFE;
	//dmaCopyRAMSource + 2 = UNKNOWN_30X2_TABLE_31[spriteUpdateEntityOffset / 2];
	dmaCopyRAMSource = sprites[x02.id].ptr;
	dmaCopyMode = 0;
	while (true) {
		uploadSpriteTileRow();
		if (--x00 == 0) {
			break;
		}
		dmaCopyRAMSource += dmaCopySize;
	}
}

/// $C0A82F
short disableCurrentEntityCollision2(short, ref const(ubyte)* arg2) {
	entityCollidedObjects[currentActiveEntityOffset / 2] = 0x8000;
	return 0;
}

/// $C0A838
short clearCurrentEntityCollision2(short, ref const(ubyte)* arg2) {
	entityCollidedObjects[currentActiveEntityOffset / 2] = 0xFFFF;
	return 0;
}

/// $C0A841
void unknownC0A841(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	return playSfx(tmp);
}

/// $C0A84C
short actionScriptGetEventFlag(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	return getEventFlag(tmp);
}

/// $C0A857
void unknownC0A857(short arg1, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	setEventFlag(tmp, arg1);
}

/// $C0A864
void actionScriptMoveEntityToPartyMember(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	moveEntityToPartyMember(tmp);
}

/// $C0A86F
void actionScriptMoveEntityToSprite(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	moveEntityToSprite(tmp);
}

/// $C0A87A
void unknownC0A87A(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC46CF5(tmp2, tmp);
}

/// $C0A88D
void actionScriptQueueInteraction8(short, ref const(ubyte)* arg2) {
	string tmp = movementDataReadString(arg2);
	actionScriptLastRead = arg2;
	queueInteraction8(getTextBlock(tmp));
}

/// $C0A8A0
void unknownC0A8A0(short, ref const(ubyte)* arg2) {
	string tmp = movementDataReadString(arg2);
	actionScriptLastRead = arg2;
	unknownC466F0(getTextBlock(tmp));
}

/// $C0A8B3
void unknownC0A8B3(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC46C5E(tmp2, tmp);
}

/// $C0A8C6
short unknownC0A8C6() {
	return unknownC47143(0, 0);
}

/// $C0A8D1
short unknownC0A8D1() {
	return unknownC47143(1, 0);
}

/// $C0A8DC
short unknownC0A8DC() {
	return unknownC47143(0, 1);
}

/// $C0A8E7
void actionScriptSpiralMovement() {
	entitySpiralMovement(0);
}

/// $C0A8F7
short actionScriptPrepareNewEntityAtSelf(short, ref const(ubyte)* arg2) {
	prepareNewEntityAtExistingEntityLocation(0);
	return 0;
}

/// $C0A8FF
short actionScriptPrepareNewEntityAtPartyLeader(short, ref const(ubyte)* arg2) {
	prepareNewEntityAtExistingEntityLocation(1);
	return 0;
}

/// $C0A907
short actionScriptPrepareNewEntityAtTeleportDestination(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	prepareNewEntityAtTeleportDestination(tmp);
	return 0;
}

/// $C0A912
short actionScriptPrepareNewEntity(short, ref const(ubyte)* arg1) {
	short tmp = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	short tmp2 = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	short tmp3 = movementDataRead8(arg1);
	actionScriptLastRead = arg1;
	prepareNewEntity(tmp3, tmp, tmp2);
	return 0;
}

/// $C0A92D
void unknownC0A92D(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC46B8D(tmp);
}

/// $C0A938
void unknownC0A938(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC46BBB(tmp);
}

/// $C0A943
short actionScriptGetPositionOfPartyMember(short, ref const(ubyte)* arg1) {
	short tmp1 = movementDataRead8(arg1);
	actionScriptLastRead = arg1;
	getPositionOfPartyMember(tmp1);
	return 0;
}

/// $C0A94E
void unknownC0A94E(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC46984(tmp);
}

/// $C0A959
void unknownC0A959(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC469F1(tmp);
}

/// $C0A964
void actionScriptSetEntityBoundaries(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	setEntityBoundaries(tmp, tmp2);
}

/// $C0A977
short actionScriptLoadBattleBG(short, ref const(ubyte)* arg1) {
	short tmp = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	short tmp2 = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	loadBackgroundAnimation(tmp, tmp2);
	return 0;
}

/// $C0A98B
short actionScriptSpawnEntityAtSelf(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	return spawnEntityAtSelf(tmp, tmp2);
}

/// $C0A99F
short actionScriptCreateEntityAtV01PlusBG3Y(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	return createEntityAtV01PlusBG3Y(tmp, tmp2);
}

/// $C0A9B3
void unknownC0A9B3(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp3 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC4EBAD(tmp, tmp2, tmp3);
}

/// $C0A9CF
void unknownC0A9CF(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp3 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC4EC05(tmp, tmp2, tmp3);
}

/// $C0A9EB
void unknownC0A9EB(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp3 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC4EC52(tmp, tmp2, tmp3);
}

/// $C0AA23
void unknownC0AA23(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp3 = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	unknownC47765(tmp, tmp2, tmp3);
}

/// $C0AA3F
void unknownC0AA3F(short arg1, ref const(ubyte)* arg2) {
	short x = (--arg1 != 0) ? 0x33 : 0xB3;
	actionscriptCOLDATABlue = cast(ubyte)movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	actionscriptCOLDATAGreen = cast(ubyte)movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	actionscriptCOLDATARed = cast(ubyte)movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	unknownC42439(x);
}

/// $C0AA6E
void actionScriptUpdateSpriteDirection(short, ref const(ubyte)* arg2) {
	if (entityScriptVar0Table[currentActiveEntityOffset / 2] == 0) {
		entityDirections[currentActiveEntityOffset / 2] = cast(ubyte)movementDataRead8(arg2);
		actionScriptLastRead = arg2;
		useSecondSpriteFrame = entityAnimationFrames[currentActiveEntityOffset / 2] = cast(ubyte)movementDataRead8(arg2);
		actionScriptLastRead = arg2;
		updateEntitySpriteOffset(currentActiveEntityOffset);
	} else {
		entityDirections[currentActiveEntityOffset / 2] = cast(ubyte)movementDataRead8(arg2);
		actionScriptLastRead = arg2;
		entityAnimationFrames[currentActiveEntityOffset / 2] = cast(ubyte)(movementDataRead8(arg2) * 2);
		actionScriptLastRead = arg2;
		spriteUpdateEntityOffset = currentActiveEntityOffset;
		updateEntitySpriteFrameCurrent();
	}
}

/// $C0AAAC
void unknownC0AAAC() {
	spriteUpdateEntityOffset = currentActiveEntityOffset;
	updateEntitySpriteFrameCurrent();
}

/// $C0AAB5
void unknownC0AAB5(short, ref const(ubyte)* arg2) {
	short tmp = movementDataRead16(arg2);
	actionScriptLastRead = arg2;
	short tmp2 = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	short tmp3 = movementDataRead8(arg2);
	actionScriptLastRead = arg2;
	unknownC497C0(tmp3, tmp2, tmp);
}

/// $C0AACD
short unknownC0AACD() {
	return 2;
}

/// $C0AAD5
void actionScriptJumpToLabelNTimes(short, ref const(ubyte)* arg2) {
	actionScriptVar90 = cast(short)(movementDataRead8(arg2) + 1);
	actionScriptLastRead = arg2;
	actionScriptJumpDestination = cast(const(ubyte)*)movementDataReadPtr(arg2);
	actionScriptLastRead = arg2;
	//offset is just an estimate...
	if (actionScriptStack[4].counter == 0) {
		actionScriptStack[4].counter = cast(ubyte)actionScriptVar90;
	}
	if (--actionScriptStack[4].counter != 0) {
		actionScriptLastRead = actionScriptJumpDestination;
	}
}

/// $C0AAFD
void unknownC0AAFD() {
	//offset is just an estimate...
	actionScriptStack[4].counter = 0;
}

/// $C0AA07
void actionScriptFadeOutWithMosaic(short, ref const(ubyte)* arg1) {
	short tmp1 = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	short tmp2 = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	short tmp3 = movementDataRead16(arg1);
	actionScriptLastRead = arg1;
	fadeOutWithMosaic(tmp1, tmp2, tmp3);
}

/// $C0ABC6
void stopMusic() {
	stopMusicExternal();
	currentMusicTrack = 0xFFFF;
}

/// $C0ABE0 - Play a sound effect
void playSfx(short sfx) {
	playSFX(cast(ubyte)sfx);
}
void playSfxUnknown() {
	playSFX(0);
}

/// $C0AC0C
void musicEffect(short arg1) {
	doMusicEffect(arg1);
}

/// $C0AC43
void unknownC0AC43() {
	spritemapBank = 0xC4;
	ubyte actionScriptVar04 = 0xC4;
	ubyte actionScriptVar00 = ((entitySurfaceFlags[currentActiveEntityOffset / 2] & 1) != 0) ? 1 : 0;
	switch (entitySurfaceFlags[currentActiveEntityOffset / 2] & SurfaceFlags.deepWater) {
		default:
			if (entityByteWidths[currentActiveEntityOffset / 2] == 0x40) {
				if (entityRippleNextUpdateFrames[currentActiveEntityOffset / 2] == 0) {
					entityRippleOverlayPtrs[currentActiveEntityOffset / 2] = updateOverlayFrame(&entityRippleSpritemaps[currentActiveEntityOffset / 2], entityRippleNextUpdateFrames[currentActiveEntityOffset / 2], entityRippleOverlayPtrs[currentActiveEntityOffset / 2]);
				}
				entityRippleNextUpdateFrames[currentActiveEntityOffset / 2]--;
				drawSprite(entityRippleSpritemaps[currentActiveEntityOffset / 2] + actionScriptVar00, entityScreenXTable[currentActiveEntityOffset / 2], entityScreenYTable[currentActiveEntityOffset / 2]);
			} else {
				if (entityBigRippleNextUpdateFrames[currentActiveEntityOffset / 2] == 0) {
					entityBigRippleOverlayPtrs[currentActiveEntityOffset / 2] = updateOverlayFrame(&entityBigRippleSpritemaps[currentActiveEntityOffset /2], entityBigRippleNextUpdateFrames[currentActiveEntityOffset / 2], entityBigRippleOverlayPtrs[currentActiveEntityOffset / 2]);
				}
				entityBigRippleNextUpdateFrames[currentActiveEntityOffset / 2]--;
				drawSprite(entityBigRippleSpritemaps[currentActiveEntityOffset / 2] + actionScriptVar00 + actionScriptVar00, entityScreenXTable[currentActiveEntityOffset / 2], cast(short)(entityScreenYTable[currentActiveEntityOffset / 2] + 8));
			}
			goto case;
		case SurfaceFlags.none:
			if (entityOverlayFlags[currentActiveEntityOffset / 2] == EntityOverlayFlags.none) {
				return;
			}
			if ((entityOverlayFlags[currentActiveEntityOffset / 2] & EntityOverlayFlags.sweating) == 0) {
				break;
			}
			goto case;
		case SurfaceFlags.causesSunstroke:
			if (currentActiveEntityOffset < 46) {
				return;
			}
			if (entitySweatingNextUpdateFrames[currentActiveEntityOffset / 2] == 0) {
				entitySweatingOverlayPtrs[currentActiveEntityOffset / 2] = updateOverlayFrame(&entitySweatingSpritemaps[currentActiveEntityOffset / 2], entitySweatingNextUpdateFrames[currentActiveEntityOffset / 2], entitySweatingOverlayPtrs[currentActiveEntityOffset / 2]);
			}
			entitySweatingNextUpdateFrames[currentActiveEntityOffset / 2]--;
			if (entitySweatingSpritemaps[currentActiveEntityOffset / 2] is null) {
				break;
			}
			drawSprite(entitySweatingSpritemaps[currentActiveEntityOffset / 2] + actionScriptVar00, entityScreenXTable[currentActiveEntityOffset / 2], entityScreenYTable[currentActiveEntityOffset / 2]);
			break;
	}
	if ((entityOverlayFlags[currentActiveEntityOffset / 2] & EntityOverlayFlags.mushroom) == 0) {
		return;
	}
	if (currentActiveEntityOffset < 46) {
		return;
	}
	if (entityMushroomizedNextUpdateFrames[currentActiveEntityOffset / 2] == 0) {
		entityMushroomizedOverlayPtrs[currentActiveEntityOffset / 2] = updateOverlayFrame(&entityMushroomizedSpritemaps[currentActiveEntityOffset / 2], entityMushroomizedNextUpdateFrames[currentActiveEntityOffset / 2], entityMushroomizedOverlayPtrs[currentActiveEntityOffset / 2]);
	}
	entityMushroomizedNextUpdateFrames[currentActiveEntityOffset / 2]--;
	drawSprite(entityMushroomizedSpritemaps[currentActiveEntityOffset / 2] + actionScriptVar00, entityScreenXTable[currentActiveEntityOffset / 2], entityScreenYTable[currentActiveEntityOffset / 2]);
}

/// $C0AD56
const(OverlayScript)* updateOverlayFrame(const(SpriteMap)** arg1, out ushort frames, const(OverlayScript)* overlay) {
	ushort y = 0;
	NextCommand:
	if (overlay[y].command == 1) {
		arg1[0] = overlay[y++].spriteMap;
		goto NextCommand;
	}
	if (overlay[y].command == 3) {
		overlay = overlay[y++].dest;
		goto NextCommand;
	}
	frames = overlay[y++].frames;
	return &overlay[y];
}

/// $C0AD9F
void unknownC0AD9F() {
	setBGOffsetY(3, bg3YPosition);
}

/// $C0ADB2
void doBackgroundDMA(short arg1, short arg2, short arg3) {
	dmaChannels[arg1].BBAD = dmaTargetRegisters[arg2];
	dmaChannels[arg1].DMAP = 0x42;
	ubyte* a;
	if (arg3 == 0) {
		short x = HDMAIndirectTableEntry.sizeof * 2;
		do {
			// The original game code does 16-bit copy here, which copies
			// one byte too many. Do one byte at a time instead.
			animatedBackgroundLayer1HDMATable[x] = (cast(immutable(ubyte)*)&animatedBackgroundLayer1HDMATableTemplate)[x];
			x -= 1;
		} while (x >= 0);
		a = &animatedBackgroundLayer1HDMATable[0];
	} else {
		short x = HDMAIndirectTableEntry.sizeof * 2;
		do {
			animatedBackgroundLayer2HDMATable[x] = (cast(immutable(ubyte)*)&animatedBackgroundLayer2HDMATableTemplate)[x];
			x -= 1;
		} while (x >= 0);
		a = &animatedBackgroundLayer2HDMATable[0];
	}
	dmaChannels[arg1].A1T = a;
	mirrorHDMAEN |= dmaFlags[arg1];
}

/// $C0AE16
immutable ubyte[7] dmaFlags = [ 1 << 0, 1 << 1, 1 << 2, 1 << 3, 1 << 4, 1 << 5, 1 << 6];

/// $C0AE26
const HDMAIndirectTableEntry[3] animatedBackgroundLayer1HDMATableTemplate;

/// $C0AE2D
const HDMAIndirectTableEntry[3] animatedBackgroundLayer2HDMATableTemplate;

shared static this() {
	animatedBackgroundLayer1HDMATableTemplate = [
		HDMAIndirectTableEntry(0xE4, cast(const(ubyte)*)&backgroundHDMABuffer[0]),
		HDMAIndirectTableEntry(0xFC, cast(const(ubyte)*)&backgroundHDMABuffer[100]),
		HDMAIndirectTableEntry(0x00),
	];
	animatedBackgroundLayer2HDMATableTemplate = [
		HDMAIndirectTableEntry(0xE4, cast(const(ubyte)*)&backgroundHDMABuffer[324]),
		HDMAIndirectTableEntry(0xFC, cast(const(ubyte)*)&backgroundHDMABuffer[424]),
		HDMAIndirectTableEntry(0x00),
	];
	animatedMapPaletteBuffers = [
		&animatedMapPaletteBuffer[0],
		&animatedMapPaletteBuffer[0xC0],
		&animatedMapPaletteBuffer[0x180],
		&animatedMapPaletteBuffer[0x240],
		&animatedMapPaletteBuffer[0x300],
		&animatedMapPaletteBuffer[0x3C0],
		&animatedMapPaletteBuffer[0x480],
		&animatedMapPaletteBuffer[0x540],
	];
}

/// $C0AE1D
// WMDATA, BG1HOFS, BG2HOFS, BG3HOFS, BG4HOFS, BG1VOFS, BG2VOFS, BG3VOFS, BG4VOFS
immutable ubyte[9] dmaTargetRegisters = [ 0x80, 0x0D, 0x0F, 0x11, 0x13, 0x0E, 0x10, 0x12, 0x14 ];

/// $C0AE34
void hdmaDisable(short layer) {
	mirrorHDMAEN &= hdmaDisableMasks[layer];
}

/// $C0AE44
immutable ubyte[8] hdmaDisableMasks = [
	0b11111110,
	0b11111101,
	0b11111011,
	0b11110111,
	0b11101111,
	0b11011111,
	0b10111111,
	0b01111111
];

/// $C0AE4C
void loadBackgroundOffsetParameters(short arg1, short arg2, short arg3) {
	backgroundDistortionStyle = arg1;
	backgroundDistortionTargetLayer = arg2;
	backgroundDistortSecondLayer = arg3;
}

/// $C0AE56
void loadBackgroundOffsetParameters2(short arg1) {
	backgroundDistortionCompressionRate = arg1;
}

/// $C0AE5A
void prepareBackgroundOffsetTables(short rippleFrequency, short rippleAmplitude, short distortionSpeed) {
	ushort x03 = cast(ushort)((distortionSpeed & 0xFF) << 8);
	short startOffset = 0;
	short endOffset = 0x1C0;
	short bufferPosition;
	ushort x05;
	if (backgroundDistortSecondLayer != 0) {
		startOffset = 0x1C0;
		endOffset = 0x380;
	}
	if (backgroundDistortionTargetLayer != 0) {
		if (backgroundDistortionStyle < (DistortionStyle.verticalSmooth - 1)) {
			switch (backgroundDistortionTargetLayer - 1) {
				case 0:
					x03 += cast(ushort)(bg1YPosition << 8);
					x05 += cast(ushort)(bg1XPosition << 8);
					break;
				case 1:
					x03 += cast(ushort)(bg2YPosition << 8);
					x05 += cast(ushort)(bg2XPosition << 8);
					break;
				case 2:
					x03 += cast(ushort)(bg3YPosition << 8);
					x05 += cast(ushort)(bg3XPosition << 8);
					break;
				case 3:
					x03 += cast(ushort)(bg4YPosition << 8);
					x05 += cast(ushort)(bg4XPosition << 8);
					break;
				default: break;
			}
		} else {
			switch (backgroundDistortionTargetLayer - 1) {
				case 0:
					x05 = cast(ushort)(bg1YPosition << 8);
					break;
				case 1:
					x05 = cast(ushort)(bg2YPosition << 8);
					break;
				case 2:
					x05 = cast(ushort)(bg3YPosition << 8);
					break;
				case 3:
					x05 = cast(ushort)(bg4YPosition << 8);
					break;
				default: break;
			}
		}
	} else {
		x05 = 0;
	}
	switch(backgroundDistortionStyle) {
		case DistortionStyle.horizontalSmooth - 1:
			bufferPosition = startOffset;
			while (bufferPosition < endOffset) {
				backgroundHDMABuffer[bufferPosition / 2] = cast(ushort)(((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8) + x05);
				x03 += rippleFrequency;
				bufferPosition += 2;
			}
			break;
		case DistortionStyle.horizontalInterlaced - 1:
			bufferPosition = startOffset;
			while (bufferPosition < endOffset) {
				backgroundHDMABuffer[bufferPosition / 2] = cast(ushort)(((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8) + x05);
				x03 += rippleFrequency;
				backgroundHDMABuffer[bufferPosition / 2 + 1] = cast(ushort)(x05 - ((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8));
				x03 += rippleFrequency;
				bufferPosition += 4;
			}
			break;
		case DistortionStyle.verticalSmooth - 1:
			x05 = cast(ushort)(x05 << 8);
			bufferPosition = startOffset;
			while (bufferPosition < endOffset) {
				x05 += backgroundDistortionCompressionRate;
				backgroundHDMABuffer[bufferPosition / 2] = cast(ushort)(((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8) + (x05 / 256));
				x03 += rippleFrequency;
				bufferPosition += 2;
			}
			break;
		case DistortionStyle.unknown - 1:
		default:
			x05 = cast(ushort)(x05 << 8);
			bufferPosition = startOffset;
			while (bufferPosition < endOffset) {
				x05 += backgroundDistortionCompressionRate;
				backgroundHDMABuffer[bufferPosition / 2] = cast(ushort)(((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8) + (x05 / 256));
				x05 += backgroundDistortionCompressionRate;
				x03 += rippleFrequency;
				backgroundHDMABuffer[bufferPosition / 2 + 1] = cast(ushort)((x05 / 256) - ((rippleAmplitude * sineLookupTable[x03 / 256]) >> 8));
				x03 += rippleFrequency;
				bufferPosition += 4;
			}
			break;
	}
}

/// $C0AFCD
void setLayerConfig(short arg1) {
	mirrorTM = layerConfigTMs[arg1];
	mirrorTD = layerConfigTDs[arg1];
	CGWSEL = layerConfigCGWSELs[arg1];
	CGADSUB = layerConfigCGADSUBs[arg1];
}

/// $C0AFF1
immutable ubyte[11] layerConfigTMs = [
	TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg4 | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg1,
	TMTD.obj | TMTD.bg3 | TMTD.bg1
];

/// $C0AFFC
immutable ubyte[10] layerConfigTDs = [
	TMTD.none,
	TMTD.none,
	TMTD.bg4,
	TMTD.bg4,
	TMTD.bg4,
	TMTD.bg4,
	TMTD.bg2,
	TMTD.bg2,
	TMTD.bg2,
	TMTD.bg2
];

/// $C0B006
immutable ubyte[10] layerConfigCGWSELs = [0x00, 0x00, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02];

/// $C0B010
immutable ubyte[10] layerConfigCGADSUBs = [0x00, 0x00, 0x24, 0x64, 0xA4, 0xE4, 0x21, 0x61, 0xA1, 0xE1];

/// $C0B01A
void setColData(ubyte red, ubyte green, ubyte blue) {
	setFixedColourData((red & 0x1F) | 0x20);
	setFixedColourData((green & 0x1F) | 0x40);
	setFixedColourData((blue & 0x1F) | 0x80);
}

/// $C0B039
void setColourAddSubMode(ubyte cgwsel, ubyte cgadsub) {
	CGWSEL = cgwsel;
	CGADSUB = cgadsub;
}

/** Sets window masking registers WxxxSEL, TMW, TSW and WxxxLOG with presets
 * Params:
 * 	layers = Bitmask of masks to enable (see earthbound.commondefs.SwirlMask for values)
 * 	invert = If 0, sets mode to affect the outside of the windows using OR logic, if 1, uses area inside of the windows with AND logic
 * Original_Address: $(DOLLAR)C0B047
 */
void setWindowMask(ushort layers, ushort invert) {
	W12SEL = windowMaskSettingPresets[layers & 3] & ((invert != 0) ? 0b10101010 : 0b11111111);
	W34SEL = windowMaskSettingPresets[(layers>>2) & 3] & ((invert != 0) ? 0b10101010 : 0b11111111);
	WOBJSEL = windowMaskSettingPresets[(layers>>4) & 3] & ((invert != 0) ? 0b10101010 : 0b11111111);
	TMW = layers & 0b00011111;
	TSW = layers & 0b00011111;
	WBGLOG = (invert != 0) ? 0 : 0b01010101;
	WOBJLOG = (invert != 0) ? 0 : 0b01010101;
}

/** Mask setting presets for W12SEL, W34SEL, WOBJSEL used by setWindowMask
 * Original_Address: $(DOLLAR)C0B0A6
 */
immutable ubyte[4] windowMaskSettingPresets = [
	0b00000000, // disable masking on both BG1/BG3/OBJ and BG2/BG4/MATH
	0b00001111, // enable masking only on BG1/BG3/OBJ
	0b11110000, // enable masking only on BG2/BG4/MATH
	0b11111111, // enable masking on both BG1/BG3/OBJ and BG2/BG4/MATH
];

/** Resets windows 1 and 2 by setting the left edge to the right edge of the screen
 * Original_Address: $(DOLLAR)C0B0AA
 */
void resetWindows() {
	WH0 = 0xFF;
	WH2 = 0xFF;
}

/** Enables window HDMA. Destination is fixed to WH0-WH3
 * Params:
 * 	channel = The channel (0 - 7) to set up HDMA on
 * 	table = The HDMA table to use, prefixed with a single byte for HDMA parameters (ie a DMAPx value)
 * Original_Address: $(DOLLAR)C0B0B8
 */
void enableWindowHDMA(short channel, const(ubyte)* table) {
	//dmaChannels[channel].A1B = bank of table;
	//dmaChannels[channel].DASB = bank of table;
	dmaChannels[channel].BBAD = 0x26;
	dmaChannels[channel].DMAP = *table;
	dmaChannels[channel].A1T = &table[1];
	mirrorHDMAEN |= dmaFlags[channel];
}

/// $C0B0EF
void enableSwirlWindowHDMA(ubyte channel, ubyte flags) {
	// Write the table entry for the first 100 lines of window data
	swirlWindowHDMATable[0].lines = 100 | 0x80;
	swirlWindowHDMATable[0].address = &swirlWindowHDMAData[0];
	// Write the table entry for the 124 remaining lines of window data
	swirlWindowHDMATable[1].lines = 124 | 0x80;
	swirlWindowHDMATable[2].lines = 0;
	//dmaChannels[channel].A1B = 0x7E;
	//dmaChannels[channel].DASB = 0x7E;
	dmaChannels[channel].BBAD = 0x26;
	dmaChannels[channel].DMAP = flags;
	// Depending on whether we are writing to windows 1 and 2 (4 bytes) or just window 1 (2 bytes),
	// skip ahead in the buffer by 400 or 200 bytes (100 lines)
	swirlWindowHDMATable[1].address = ((flags & 4) != 0) ? (&swirlWindowHDMAData[400]) : (&swirlWindowHDMAData[200]);
	dmaChannels[channel].A1T = &swirlWindowHDMATable[0];
	mirrorHDMAEN |= dmaFlags[channel];
}

/// $C0B149
void generateSwirlHDMATable(short arg1, short arg2, short arg3, short arg4) {
	if (/+(arg2 > 0) && (+/arg2 >= 0x70) {
		short y = 0;
		short a = cast(short)(arg2 - arg4);
		if (a > 0) {
			do {
				*cast(ushort*)&swirlWindowHDMAData[y] = 0xFF;
				y += 2;
			} while(--a != 0);
			a = 0;
		}
		short x0A = cast(short)(a + arg4);
		short x0C;
		while (true) {
			short x08 = (a == 0) ? arg3 : ((0x80 + arg3 * unknownC0B2FF[cast(ushort)x0A / cast(ubyte)arg4]) >> 8);
			a = cast(short)(x08 + arg1);
			if (a >= 0) {
				if (a >= 0x100) {
					a = 0xFF;
				}
				x0C = a;
				a = cast(short)(arg1 - x08);
				if (a < 0) {
					a = 0;
				} else if (a >= 0x100) {
					a = 0xFF;
				} else {
					a = cast(ushort)(x0C << 8) | cast(ubyte)a;
				}
			}
			*cast(ushort*)&swirlWindowHDMAData[y] = a;
			x0C = cast(short)(x0A * 4);
			if (y + x0C < 0x1C0) {
				*cast(ushort*)&swirlWindowHDMAData[y + x0C] = a;
			}
			y += 2;
			if (--x0A < 0) {
				break;
			}
		}
		a = y;
		y = cast(short)(a + arg4 + arg4);
		if (y < 0x1C0) {
			a = 0xFF;
			do {
				*cast(ushort*)&swirlWindowHDMAData[y] = 0xFF;
				y += 2;
			} while (y < 0x1C0);
		}
	} else {
		short y = 0x1BE;
		short a = 0xE0;
		a = cast(short)(a - arg2 - arg4);
		if (a > 0) {
			do {
				*cast(ushort*)&swirlWindowHDMAData[y] = 0xFF;
				y -= 2;
			} while (--a != 0);
			a = 0;
		}
		short x0A = cast(short)(a + arg4);
		short x0C;
		while (true) {
			short x08 = (a == 0) ? arg3 : ((0x80 + arg3 * unknownC0B2FF[cast(ushort)x0A / cast(ubyte)arg4]) >> 8);
			a = cast(short)(x08 + arg1);
			if (a >= 0) {
				if (a >= 0x100) {
					a = 0xFF;
				}
				x0C = a;
				a = cast(short)(arg1 - x08);
				if (a < 0) {
					a = 0;
				} else if (a >= 0x100) {
					a = 0xFF;
				} else {
					a = cast(ushort)(x0C << 8) | cast(ubyte)a;
				}
			}
			*cast(ushort*)&swirlWindowHDMAData[y] = a;
			x0C = cast(short)(x0A * 4);
			if (y - x0C >= 0) {
				*cast(ushort*)&swirlWindowHDMAData[y - x0C] = a;
			}
			y -= 2;
			if (--x0A < 0) {
				break;
			}
		}
		a = y;
		y = cast(short)(a - arg4 - arg4);
		if (y >= 0) {
			do {
				swirlWindowHDMAData[y] = 0xFF;
				y -= 2;
			} while (y >= 0);
		}
	}
}

/// $C0B2FF
immutable byte[256] unknownC0B2FF = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3, -3, -3, -4, -4, -4, -4, -4, -5, -5, -5, -5, -5, -6, -6, -6, -6, -6, -7, -7, -7, -7, -8, -8, -8, -8, -9, -9, -9, -9, -10, -10, -10, -11, -11, -11, -12, -12, -12, -12, -13, -13, -13, -14, -14, -15, -15, -15, -16, -16, -16, -17, -17, -17, -18, -18, -19, -19, -20, -20, -20, -21, -21, -22, -22, -23, -23, -23, -24, -24, -25, -25, -26, -26, -27, -27, -28, -28, -29, -29, -30, -30, -31, -31, -32, -33, -33, -34, -34, -35, -35, -36, -37, -37, -38, -38, -39, -40, -40, -41, -42, -42, -43, -44, -44, -45, -46, -46, -47, -48, -49, -49, -50, -51, -52, -52, -53, -54, -55, -55, -56, -57, -58, -59, -59, -60, -61, -62, -63, -64, -65, -65, -66, -67, -68, -69, -70, -71, -72, -73, -74, -75, -76, -77, -78, -79, -80, -81, -82, -83, -84, -86, -87, -88, -89, -90, -91, -93, -94, -95, -96, -97, -99, -100, -101, -103, -104, -105, -107, -108, -110, -111, -113, -114, -116, -117, -119, -120, -122, -123, -125, -127, 127, 126, 124, 122, 120, 118, 116, 114, 112, 110, 108, 106, 104, 102, 99, 97, 94, 92, 89, 86, 83, 81, 77, 74, 71, 67, 63, 59, 55, 50, 45, 39, 32, 23];

/// $C0B425
immutable byte[256] sineLookupTable = [0, 3, 6, 9, 12, 15, 18, 21, 24, 28, 31, 34, 37, 40, 43, 46, 48, 51, 54, 57, 60, 63, 65, 68, 71, 73, 76, 78, 81, 83, 85, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108, 109, 111, 112, 114, 115, 117, 118, 119, 120, 121, 122, 123, 124, 124, 125, 126, 126, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 126, 126, 125, 124, 124, 123, 122, 121, 120, 119, 118, 117, 115, 114, 112, 111, 109, 108, 106, 104, 102, 100, 98, 96, 94, 92, 90, 88, 85, 83, 81, 78, 76, 73, 71, 68, 65, 63, 60, 57, 54, 51, 48, 46, 43, 40, 37, 34, 31, 28, 24, 21, 18, 15, 12, 9, 6, 3, 0, -3, -6, -9, -12, -15, -18, -21, -24, -28, -31, -34, -37, -40, -43, -46, -48, -51, -54, -57, -60, -63, -65, -68, -71, -73, -76, -78, -81, -83, -85, -88, -90, -92, -94, -96, -98, -100, -102, -104, -106, -108, -109, -111, -112, -114, -115, -117, -118, -119, -120, -121, -122, -123, -124, -124, -125, -126, -126, -127, -127, -127, -127, -127, -127, -127, -127, -127, -127, -127, -126, -126, -125, -124, -124, -123, -122, -121, -120, -119, -118, -117, -115, -114, -112, -111, -109, -108, -106, -104, -102, -100, -98, -96, -94, -92, -90, -88, -85, -83, -81, -78, -76, -73, -71, -68, -65, -63, -60, -57, -54, -51, -48, -46, -43, -40, -37, -34, -31, -28, -24, -21, -18, -15, -12, -9, -6, -3];

/** Calculates cos(angle) * factor / 2
 * Params:
 * 	factor = Number to multiply
 * angle = Angle in 1/256ths of a radian
 * Original_Address: $(DOLLAR)C0B400
 */
short cosineMult(short factor, short angle) {
	return sineMult(factor, cast(ubyte)(angle - 0x40));
}

/** Returns sin(angle) * factor / 2
 * Params:
 * 	factor = Number to multiply
 * angle = Angle in 1/256ths of a radian
 * Original_Address: $(DOLLAR)C0B40B
 */
short sineMult(short factor, ubyte angle) {
	return (factor * sineLookupTable[angle]) >> 8;
}

/// $C0B525
void fileSelectInit() {
	prepareForImmediateDMA();
	unknownC0927C();
	oamClear();
	updateScreen();
	clearSpriteTable();
	spriteVramTableOverwrite(short.min, 0);
	initializeMiscObjectData();
	overworldSetupVRAM();
	unknownC432B1();
	prepareAverageForSpritePalettes();
	memcpy(&palettes[8][0], spriteGroupPalettes.ptr, 0x100);
	initializeTextSystem();
	copyToVRAM(3, 0x800, 0x7C00, buffer.ptr);
	decomp(textWindowGraphics.ptr, buffer.ptr);
	memcpy(&buffer[0x2000], &buffer[0x1000], 0x2A00);
	loadWindowGraphics(WindowGraphicsToLoad.all);
	memcpy(&palettes[0][0], textWindowFlavourPalettes.ptr, 0x40);
	if (config.autoLoadFile.isNull) {
		loadBackgroundAnimation(BackgroundLayer.fileSelect, 0);
	}
	entityAllocationMinSlot = partyLeaderEntity;
	entityAllocationMaxSlot = partyLeaderEntity + 1;
	initEntity(ActionScript.unknown787, 0, 0);
	mirrorTM = TMTD.obj | TMTD.bg3 | TMTD.bg2;
	bg2YPosition = 0;
	bg1YPosition = 0;
	bg2XPosition = 0;
	bg1XPosition = 0;
	oamClear();
	updateScreen();
	fadeIn(1, 1);
	unknownC1FF6B();
	fadeOutWithMosaic(1, 1, 0);
	deleteEntity(partyLeaderEntity);
	mirrorTM = TMTD.obj | TMTD.bg3 | TMTD.bg2 | TMTD.bg1;
	unknownC4FD18(gameState.soundSetting - 1);
}

/// $C0B65F
void setLeaderLocation(short arg1, short arg2) {
	tracef("Setting coordinates to %s, %s", arg1, arg2);
	gameState.leaderX.integer = arg1;
	gameState.leaderY.integer = arg2;
	gameState.leaderDirection = 2;
	gameState.partyMembers[0] = 1;
	entityScreenXTable[partyMemberEntityStart] = arg1;
	entityScreenYTable[partyMemberEntityStart] = arg2;
}

/// $C0B67F
void unknownC0B67F() {
	unknownC0927C();
	clearSpriteTable();
	spriteVramTableOverwrite(short.min, 0);
	initializeMiscObjectData();
	battleMode = BattleMode.noBattle;
	inputDisableFrameCounter = 0;
	npcSpawnsEnabled = SpawnControl.offscreenOnly;
	enemySpawnsEnabled = SpawnControl.allEnabled;
	overworldEnemyMaximum = 10;
	battleSwirlCountdown = 0;
	pendingInteractions = 0;
	setBoundaryBehaviour(1);
	dadPhoneTimer = 0x697;
	setIRQCallback(&processOverworldTasks);
	psiTeleportStyle = PSITeleportStyle.none;
	psiTeleportDestination = 0;
	entityFadeEntity = -1;
	entityAllocationMinSlot = partyLeaderEntity;
	entityAllocationMaxSlot = partyLeaderEntity + 1;
	initEntity(ActionScript.partyMemberLeading, 0, 0);
	clearParty();
	unknownC03A24();
	memset(&palettes[0][0], 0, 0x200);
	loadTextPalette();
	overworldInitialize();
	if (config.overrideSpawn) {
		gameState.leaderX.integer = config.spawnCoordinates.x;
		gameState.leaderY.integer = config.spawnCoordinates.y;
	}
	loadMapAtPosition(gameState.leaderX.integer, gameState.leaderY.integer);
	spawnBuzzBuzz();
	prepareWindowGraphics();
	loadWindowGraphics(WindowGraphicsToLoad.all);
	setFollowerEntityLocationToLeaderPosition();
}

/// $C0B731
void initBattleOverworld() {
	if (battleMode == BattleMode.noBattle) {
		return;
	}
	if ((debugging == 0) || (unknownEFE708() != -1)) {
		if (instantWinCheck() != 0) {
			instantWinHandler();
			battleMode = BattleMode.noBattle;
		} else {
			short battleResult = initBattleCommon();
			unknownC07B52();
			overworldStatusSuppression = 0;
			if (psiTeleportDestination == 0) {
				if (battleResult != BattleResult.won) {
					if (debugging == 0) {
						return;
					}
					if (debugCheckViewCharacterMode() != 0) {
						return;
					}
				}
				reloadMap();
				fadeIn(1, 1);
			} else {
				teleportMainLoop();
			}
		}
	}
	for (short i = 0; i != partyLeaderEntity; i++) {
		entityCollidedObjects[i] = 0xFFFF;
		entityPathfindingState[i] = 0;
		entitySpriteMapFlags[i] &= ~SpriteMapFlags.drawDisabled;
	}
	overworldStatusSuppression = 0;
	unfreezeEntities();
	playerIntangibilityFrames = 120;
	touchedEnemy = -1;
}

/// $C0B7D8
void ebMain() {
	initializePartyPointers();
	RestartGame:
	if (config.noIntro) {
		disabledTransitions = 1;
	} else {
		initIntro();
	}
	fileSelectInit();
	unknownC0B67F();
	fadeIn(1, 1);
	updateScreen();
	//setjmp(&jmpbuf2);
	unknownC43F53();
	while (1) {
		oamClear();
		runActionscriptFrame();
		updateScreen();
		unknownC4A7B0();
		waitUntilNextFrame();
		if (((currentQueuedInteraction - nextQueuedInteraction) != 0) && !battleSwirlCountdown && !enemyHasBeenTouched && (battleMode == BattleMode.noBattle)) {
			processQueuedInteractions();
			inputDisableFrameCounter++;
		} else if ((gameState.cameraMode != CameraMode.followEntity) && (gameState.walkingStyle != WalkingStyle.escalator) && !battleSwirlCountdown) {
			if (battleMode != BattleMode.noBattle) {
				initBattleOverworld();
				inputDisableFrameCounter++;
			} else if (((padPress[0] & (Pad.a | Pad.l)) != 0) && (gameState.walkingStyle == WalkingStyle.bicycle)) {
				freezeEntities();
				getOffBicycleWithText();
				unfreezeEntities();
				continue;
			}
			if (debugging) {
				if (((padState[0] & (Pad.b | Pad.select)) != 0) && (((padPress[0] & Pad.r)) != 0)) {
					debugYButtonMenu();
					continue;
				}
				if ((padPress[1] & Pad.a) != 0) {
					getDistanceToMagicTruffle();
				}
				if ((padPress[1] & Pad.b) != 0) {
					testYourSanctuaryDisplay();
				}
			}
			if (battleSwirlCountdown) {
				continue;
			}
			if (enemyHasBeenTouched) {
				continue;
			}
			if (inputDisableFrameCounter) {
				inputDisableFrameCounter--;
			} else if (!pendingInteractions) {
				if ((padPress[0] & Pad.a) != 0 ) {
					openMenuButton();
				} else if (((padPress[0] & (Pad.b | Pad.select)) != 0) && (gameState.walkingStyle != WalkingStyle.bicycle)) {
					openHPPPDisplay();
				} else if ((padPress[0] & Pad.x) != 0) {
					showTownMap();
				} else if ((padPress[0] & Pad.l) != 0) {
					openMenuButtonCheckTalk();
				} else if (config.debugMenuButton && ((padPress[0] & Pad.extra1) != 0)) {
					freezeEntities();
					playSfx(Sfx.cursor1);
					createWindowN(Window.textStandard);
					displayText(getTextBlock("MSG_DEBUG_00"));
					clearInstantPrinting();
					hideHPPPWindows();
					closeAllWindows();
					unfreezeEntities();
				} else if (config.debugMenuButton && ((padPress[0] & Pad.extra2) != 0)) {
					freezeEntities();
					playSfx(Sfx.cursor1);
					createWindowN(Window.textStandard);
					displayText(getTextBlock("MSG_DEBUG_01"));
					clearInstantPrinting();
					hideHPPPWindows();
					closeAllWindows();
					unfreezeEntities();
				} else if (config.debugMenuButton && ((padPress[0] & Pad.extra3) != 0)) {
					debugYButtonMenu();
				} else if (config.debugMenuButton && ((padPress[0] & Pad.extra4) != 0)) {
					assert(0, "Intentional crash");
				}
			}
			mainFiberExecute();
			mainFiberExecute = () {};
			if (psiTeleportDestination) {
				teleportMainLoop();
			}
			if (!debugging && ((padPress[1] & Pad.b) != 0)) {
				for (short i = 0; i < partyCharacters.length; i++) {
					partyCharacters[i].hp.target = partyCharacters[i].maxHP;
					partyCharacters[i].pp.target = partyCharacters[i].maxPP;
				}
			}
		}
		if (!unknownC04FFE() && spawn()) {
			goto RestartGame;
		}
		if (debugging && ((padState[0] & Pad.start) != 0) && ((padState[0] & Pad.select) == 0)) {
			break;
		}
	}
}

/// $C0B99A
void gameInit() {
	checkSRAMIntegrity();
	initializeSPC700();
	enableNMIJoypad();
	checkHardware();
	waitUntilNextFrame();
	waitUntilNextFrame();
	debug {
		if (config.loadDebugMenu || ((padState[0] & (Pad.down | Pad.l)) != 0)) {
			debugging = 1;
			debugMenuLoad();
		}
	}
	debugging = 0;
	ebMain();
}

/// $C0B9BC
void unknownC0B9BC(PathCtx* arg1, short arg2, short arg3, short arg4) {
	for (short i = 0; i < arg2; i++) {
		arg1.targetsPos[i].x = (((entityAbsXTable[gameState.partyEntities[i]] - unknownC42A1F[entitySizes[gameState.partyEntities[i]]]) / 8) - arg3) & 0x3F;
		arg1.targetsPos[i].y = (((entityAbsYTable[gameState.partyEntities[i]] - unknownC42A41[entitySizes[gameState.partyEntities[i]]] + unknownC42AEB[entitySizes[gameState.partyEntities[i]]]) / 8) - arg4) & 0x3F;
	}
}

unittest {
	PathCtx ctx;
	gameState.partyEntities[0] = 0;
	entitySizes[gameState.partyEntities[0]] = 5;
	entityAbsXTable[gameState.partyEntities[0]] = 1727;
	entityAbsYTable[gameState.partyEntities[0]] = 1717;

	unknownC0B9BC(&ctx, 1, 182, 182);
	assert(ctx.targetsPos[0].x == 32);
	assert(ctx.targetsPos[0].y == 32);

	entityAbsXTable[gameState.partyEntities[0]] = 1367;
	entityAbsYTable[gameState.partyEntities[0]] = 1783;

	unknownC0B9BC(&ctx, 1, 137, 190);
	assert(ctx.targetsPos[0].x == 32);
	assert(ctx.targetsPos[0].y == 32);

	entityAbsXTable[gameState.partyEntities[0]] = 1560;
	entityAbsYTable[gameState.partyEntities[0]] = 1765;

	unknownC0B9BC(&ctx, 1, 162, 188);
	assert(ctx.targetsPos[0].x == 32);
	assert(ctx.targetsPos[0].y == 32);
}

/// $C0BA35
short unknownC0BA35(PathCtx* arg1, short arg2, short arg3, short arg4, short arg5, short arg6, short arg7) {
	ubyte* x06 = &buffer[0x3000];
	arg1.targetCount = arg2;
	for (short i = 0; i != arg1.radius.x; i++) {
		for (short j = 0; j != arg1.radius.y; j++) {
			if ((loadedCollisionTiles[(i + arg4) & 0x3F][(j + arg3) & 0x3F] & 0xC0) != 0) {
				(x06++)[0] = PathfindingTile.unwalkable;
			} else {
				(x06++)[0] = 0;
			}
		}
	}
	short x02 = 0;
	short x26 = 0;
	for (short i = 0; i < maxEntities; i++) {
		if (entityScriptTable[i] == -1) {
			continue;
		}
		if (entityPathfindingState[i] != -1) {
			continue;
		}
		arg1.pathers[x26].objIndex = i;
		arg1.pathers[x26].fromOffscreen = arg5;
		arg1.pathers[x26].hitbox.x = hitboxWidths[entitySizes[i]];
		arg1.pathers[x26].hitbox.y = hitboxHeights[entitySizes[i]];
		arg1.pathers[x26].origin.x = (((entityAbsXTable[i] - unknownC42A1F[entitySizes[i]]) / 8) - arg3) & 0x3F;
		arg1.pathers[x26].origin.y = (((entityAbsYTable[i] - unknownC42A41[entitySizes[i]] + unknownC42AEB[entitySizes[i]]) / 8) - arg4) & 0x3F;
		x26++;
	}
	arg1.patherCount = x26;
	ushort x28 = pathMain(0xC00, &pathfindingBuffer[0], &arg1.radius, &buffer[0x3000], 4, arg2, &arg1.targetsPos[0], x26, &arg1.pathers[0], -1, arg6, arg7);
	assert(pathGetHeapSize() <= 0xC00);
	if (x28 == 0) {
		for (short i = 0; i != maxEntities; i++) {
			if (entityScriptTable[i] == -1) {
				continue;
			}
			entityPathfindingState[i] = 1;
		}
		return -1;
	} else {
		for (short i = 0; i < x26; i++) {
			short x22 = arg1.pathers[i].objIndex;
			if (arg1.pathers[i].field0A != 0) {
				entityPathPoints[x22] = arg1.pathers[i].points;
				entityPathPointsCount[x22] = arg1.pathers[i].field0A;
			} else {
				entityPathfindingState[x22] = 1;
			}
		}
		return 0;
	}
}

/// $C0BC74
short findPathToParty(short partyCount, short arg2, short arg3) {
	short x28 = gameState.firstPartyMemberEntity;
	PathCtx* x26 = &pathfindingState;
	pathfindingState.radius.y = arg2;
	pathfindingState.radius.x = arg3;
	pathfindingTargetWidth = pathfindingState.radius.y / 2;
	pathfindingTargetHeight = pathfindingState.radius.x / 2;
	pathfindingTargetCenterX = (entityAbsXTable[gameState.firstPartyMemberEntity] - unknownC42A1F[entitySizes[gameState.firstPartyMemberEntity]]) / 8;
	pathfindingTargetCenterY = (entityAbsYTable[gameState.firstPartyMemberEntity] - unknownC42A41[entitySizes[gameState.firstPartyMemberEntity]] + unknownC42AEB[entitySizes[gameState.firstPartyMemberEntity]]) / 8;
	short x02 = ((entityAbsYTable[gameState.firstPartyMemberEntity] - unknownC42A41[entitySizes[gameState.firstPartyMemberEntity]] + unknownC42AEB[entitySizes[gameState.firstPartyMemberEntity]]) / 8) - (pathfindingState.radius.x / 2);
	short x04 = ((entityAbsXTable[gameState.firstPartyMemberEntity] - unknownC42A1F[entitySizes[gameState.firstPartyMemberEntity]]) / 8) - (pathfindingState.radius.y / 2);
	unknownC0B9BC(&pathfindingState, partyCount, x04, x02);
	return unknownC0BA35(&pathfindingState, partyCount, x04, x02, 0, 0x40, 0x32);
}

unittest {
	if (romDataLoaded) {
		initializeForTesting();
		currentHeapAddress = &heap[0][0];
		heapBaseAddress = &heap[0][0];

		gameState.playerControlledPartyMemberCount = 1;
		gameState.playerControlledPartyMembers[gameState.playerControlledPartyMemberCount - 1] = 0;
		chosenFourPtrs[gameState.playerControlledPartyMembers[gameState.playerControlledPartyMemberCount - 1]] = &partyCharacters[0];
		reloadMapAtPosition(1365, 1766);
		//printCollision(loadedCollisionTiles);

		entityAbsXTable = [1656, 1816, 1562, 1728, 1648, 1624, 1528, 1656, 1425, 1521, 222, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1560, 0, 0, 0, 0, 0];
		entityAbsYTable = [1608, 1952, 1773, 1744, 1758, 1632, 1728, 1712, 1768, 1790, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1765, 0, 0, 0, 0, 0];
		entitySizes = [8, 5, 5, 11, 5, 5, 0, 5, 14, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0];
		entityScriptTable = [0, -1, 21, 8, 21, 13, 9, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 2, -1, -1, -1, -1, -1];
		entityPathfindingState = [0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		gameState.firstPartyMemberEntity = 24;
		gameState.partyEntities[0] = cast(ubyte)gameState.firstPartyMemberEntity;
		entitySizes[gameState.firstPartyMemberEntity] = 5;
		//assert(findPathToParty(1, 64, 64) == 0);
	}
}


/// $C0BD96
short unknownC0BD96() {
	short x2A = gameState.firstPartyMemberEntity;
	PathCtx* x28 = &pathfindingState;
	short x04 = pathfindingState.radius.y = 56;
	short x02 = pathfindingState.radius.x = 56;
	pathfindingTargetWidth = pathfindingState.radius.y / 2;
	pathfindingTargetHeight = pathfindingState.radius.x / 2;
	pathfindingTargetCenterX = (entityAbsXTable[x2A] - unknownC42A1F[entitySizes[x2A]]) / 8;
	pathfindingTargetCenterY = (entityAbsYTable[x2A] - unknownC42A41[entitySizes[x2A]] + unknownC42AEB[entitySizes[x2A]]) / 8;
	x04 = cast(short)((entityAbsXTable[x2A] - unknownC42A1F[entitySizes[x2A]]) / 8 - x04);
	x02 = cast(short)((entityAbsYTable[x2A] - unknownC42A41[entitySizes[x2A]] + unknownC42AEB[entitySizes[x2A]]) / 8 - x02);
	unknownC0B9BC(x28, 1, x04, x02);
	short result = unknownC0BA35(x28, 1, x04, x02, 1, 0xFC, 0x32);
	if (result == 0) {
		entityAbsXTable[pathfindingState.pathers[0].objIndex] = cast(short)((pathfindingState.pathers[0].origin.x * 8) + unknownC42A1F[entitySizes[pathfindingState.pathers[0].objIndex]] + ((pathfindingTargetCenterX - pathfindingTargetWidth) * 8));
		entityAbsYTable[pathfindingState.pathers[0].objIndex] = cast(short)((pathfindingState.pathers[0].origin.y * 8) -unknownC42AEB[entitySizes[pathfindingState.pathers[0].objIndex]] + unknownC42A41[entitySizes[pathfindingState.pathers[0].objIndex]] + ((pathfindingTargetCenterY - pathfindingTargetHeight) * 8));
		entityPathPoints[pathfindingState.pathers[0].objIndex]++;
		entityPathPointsCount[pathfindingState.pathers[0].objIndex]--;
	}
	return result;
}

/// $C0BF72
short unknownC0BF72() {
	PathCtx* x26 = &pathfindingState;
	pathfindingState.radius.y = 56;
	pathfindingState.radius.x = 56;
	short x04 = pathfindingState.radius.y / 2;
	pathfindingTargetWidth = pathfindingState.radius.y / 2;
	pathfindingTargetHeight = pathfindingState.radius.x / 2;
	pathfindingTargetCenterX = (entityAbsXTable[currentEntitySlot] - unknownC42A1F[entitySizes[currentEntitySlot]]) / 8;
	pathfindingTargetCenterY = (entityAbsYTable[currentEntitySlot] - unknownC42A41[entitySizes[currentEntitySlot]] + unknownC42AEB[entitySizes[currentEntitySlot]]) / 8;
	short x = cast(short)((entityAbsXTable[currentEntitySlot] - unknownC42A1F[entitySizes[currentEntitySlot]]) / 8 - x04);
	short x28 = cast(short)((entityAbsYTable[currentEntitySlot] - unknownC42A41[entitySizes[currentEntitySlot]] + unknownC42AEB[entitySizes[currentEntitySlot]]) / 8 - x04);
	pathfindingState.targetsPos[0].x = x04 & 0x3F;
	pathfindingState.targetsPos[0].y = pathfindingTargetHeight & 0x3F;
	return unknownC0BA35(x26, 1, x, x28, 1, 0xFC, 0x32);
}

/// $C0C19B
short prepareDeliveryEntrancePath(short arg1) {
	if (legalDeliveryAreaTypes[loadSectorAttributes(gameState.leaderX.integer, gameState.leaderY.integer) & 7] != 0) {
		entityPathfindingState[currentEntitySlot] = -1;
		if (unknownC0BD96() == 0) {
			entityPathfindingState[currentEntitySlot] = 0;
			VecYX* x02 = entityPathPoints[currentEntitySlot];
			VecYX* y2 = &deliveryPaths[arg1][0];
			entityPathPoints[currentEntitySlot] = y2;
			short x10 = entityPathPointsCount[currentEntitySlot];
			for (short i = 0; (x10 != 0) && (i < 20); i++) {
				(y2++)[0] = (x02++)[0];
				x10--;
			}
			return 0;
		}
	}
	return 1;
}

/// $C0C251
short prepareDeliveryExitPath(short arg1) {
	entityPathfindingState[currentEntitySlot] = -1;
	if (unknownC0BF72() == 0) {
		entityPathfindingState[currentEntitySlot] = 0;
		short x12 = --entityPathPointsCount[currentEntitySlot];
		VecYX* x02 = &entityPathPoints[currentEntitySlot][(x12 - 1) * 4];
		VecYX* x10 = &deliveryPaths[arg1][0];
		entityPathPoints[currentEntitySlot] = x10;
		short y = entityPathPointsCount[currentEntitySlot];
		for (short i = 0; (y != 0) && (i < 20); y--, i++) {
			x10.y = x02.y;
			x10.x = x02.x;
			x02--;
			x10++;
		}
		return 0;
	}
	return 1;
}

/// $C0C30C
void unknownC0C30C(short arg1) {
	if (getEventFlag(npcConfig[entityNPCIDs[arg1]].eventFlag)) {
		entityDirections[arg1] = Direction.up; // 0
	} else {
		entityDirections[arg1] = Direction.down; // 4
	}
	updateEntitySprite(arg1);
}

/// $C0C353
void unknownC0C353() {
	unknownC0C30C(currentEntitySlot);
}

/// $C0C35D
short unknownC0C35D() {
	return gameState.leaderHasMoved;
}

/// $C0C363
short unknownC0C363() {
	short x02 = cast(short)(gameState.leaderX.integer - entityAbsXTable[currentEntitySlot]);
	short x04 = cast(short)(gameState.leaderY.integer - entityAbsYTable[currentEntitySlot]);
	if (0 > x04) {
		x04 = cast(short)-cast(int)x04;
	} else {
		x04 = x04;
	}
	if (x04 + ((0 > x02) ? (cast(short)-cast(int)x02) : x02) > 0x100) {
		return 3;
	}
	if (x04 + ((0 > x02) ? (cast(short)-cast(int)x02) : x02) > 0xA0) {
		return 2;
	}
	if (x04 + ((0 > x02) ? (cast(short)-cast(int)x02) : x02) > 0x80) {
		return 1;
	}
	return 0;
}

/// $C0C3F9
short unknownC0C3F9() {
	short x02 = cast(short)(gameState.leaderX.integer - entityAbsXTable[currentEntitySlot]);
	short x0E = cast(short)(gameState.leaderY.integer - entityAbsYTable[currentEntitySlot]);
	short x04 = (0 > x0E) ? (cast(short)-cast(int)x0E) : x0E;
	x02 = (0 > x02) ? (cast(short)-cast(int)x02) : x02;
	x0E = cast(short)(x02 + x04);
	if (x0E > 0x80) {
		return 3;
	}
	if (x0E > 0x50) {
		return 2;
	}
	if (x0E > 0x40) {
		return 1;
	}
	return 0;
}

/// $C0C48F
short unknownC0C48F() {
	if (entityPathfindingState[currentEntitySlot] != 0) {
		return 0;
	}
	if (playerIntangibilityFrames == 0) {
		return unknownC0C363();
	}
	return -1;
}

/// $C0C4AF
short unknownC0C4AF() {
	if (entityPathfindingState[currentEntitySlot] != 0) {
		return 0;
	}
	if (playerIntangibilityFrames == 0) {
		return unknownC0C3F9();
	}
	return -1;
}

/// $C0C4F6
short getDirectionFromPlayerToEntity() {
	return getDirectionTo(entityAbsXTable[currentEntitySlot], entityAbsYTable[currentEntitySlot], gameState.leaderX.integer, gameState.leaderY.integer);
}

/// $C0C524
short isEntityWeak() {
	if ((battleEntryPointerTable[entityNPCIDs[currentEntitySlot] & 0x7FFF].runAwayFlag != 0) && (getEventFlag(battleEntryPointerTable[entityNPCIDs[currentEntitySlot] & 0x7FFF].runAwayFlag) == battleEntryPointerTable[entityNPCIDs[currentEntitySlot] & 0x7FFF].runAwayFlagState)) {
		return 1;
	}
	short x0E = unknownC0546B();
	if (x0E > enemyConfigurationTable[entityEnemyIDs[currentEntitySlot]].level * 10) {
		return 1;
	}
	if ((x0E > enemyConfigurationTable[entityEnemyIDs[currentEntitySlot]].level * 8) && (entityWeakEnemyValue[currentEntitySlot] >= 192)) {
		return 1;
	}
	if ((x0E > enemyConfigurationTable[entityEnemyIDs[currentEntitySlot]].level * 6) && (entityWeakEnemyValue[currentEntitySlot] >= 128)) {
		return 1;
	}
	return 0;
}

/// $C0C62B
short getAngleTowardsPlayerUnlessWeak() {
	short x02 = 0;
	if ((entityNPCIDs[currentEntitySlot] < 0) && (isEntityWeak() != 0)) {
		x02 = short.min;
	}
	return cast(short)(getScreenAngle(entityAbsXTable[currentEntitySlot], entityAbsYTable[currentEntitySlot], entityScriptVar6Table[currentEntitySlot], entityScriptVar7Table[currentEntitySlot]) + x02);
}

/// $C0C682
short getDirectionRotatedClockwise(short arg1) {
	return (entityDirections[currentEntitySlot] + arg1) & 7;
}

/// $C0C6B6
short unknownC0C6B6() {
	if (teleportationSpeed.integer >= 4) {
		return -1;
	}
	short x0E = cast(short)(entityAbsXTable[currentEntitySlot] - (gameState.leaderX.integer - 0x80));
	short x = cast(short)(entityAbsYTable[currentEntitySlot] - (gameState.leaderY.integer - 0x70));
	if ((x0E >= -64) && (x0E < 320)) {
		if ((x >= -64) && (x < 320)) {
			return -1;
		}
	}
	return 0;
}


/// $C0C711
short unknownC0C711() {
	//weird...
	if ((((entityScreenXTable[currentEntitySlot] - unknownC42A1F[entitySizes[currentEntitySlot]]) | (entityScreenYTable[currentEntitySlot] - unknownC42A41[entitySizes[currentEntitySlot]]) | (currentEntitySlot + 8)) & 0xFF00) == 0) {
		return -1;
	} else {
		return 0;
	}
}

unittest {
	{
		currentEntitySlot = 2;
		entityScreenXTable[currentEntitySlot] = 0x104;
		entityScreenYTable[currentEntitySlot] = 0x78;
		entitySizes[currentEntitySlot] = 5;
		assert(unknownC0C711() == -1);
	}
	{
		currentEntitySlot = 4;
		entityScreenXTable[currentEntitySlot] = 0xAC;
		entityScreenYTable[currentEntitySlot] = cast(short)0xFFC1;
		entitySizes[currentEntitySlot] = 14;
		assert(unknownC0C711() == 0);
	}
}

/// $C0C7DB
void unknownC0C7DB() {
	entitySurfaceFlags[currentEntitySlot] = getSurfaceFlags(entityAbsXTable[currentEntitySlot], entityAbsYTable[currentEntitySlot], currentEntitySlot);
}

/// $C0C83B
void unknownC0C83B(short direction) {
	entityMovingDirection[currentEntitySlot] = direction;
	FixedPoint1616 x0E;
	if ((direction & 1) != 0) {
		x0E.combined = (cast(int)entityMovementSpeed[currentEntitySlot] * 0xB505) >> 8;
	} else {
		x0E.combined = (cast(int)entityMovementSpeed[currentEntitySlot] * 0x10000) >> 8;
	}
	FixedPoint1616 x12;
	FixedPoint1616 x16;
	switch (direction) {
		case Direction.up:
			x12.combined = 0;
			x16.combined = -x0E.combined;
			break;
		case Direction.upRight:
			x12.combined = x0E.combined;
			x16.combined = -x0E.combined;
			break;
		case Direction.right:
			x12.combined = x0E.combined;
			x16.combined = 0;
			break;
		case Direction.downRight:
			x12.combined = x0E.combined;
			x16.combined = x0E.combined;
			break;
		case Direction.down:
			x12.combined = 0;
			x16.combined = x0E.combined;
			break;
		case Direction.downLeft:
			x12.combined = -x0E.combined;
			x16.combined = x0E.combined;
			break;
		case Direction.left:
			x12.combined = -x0E.combined;
			x16.combined = 0;
			break;
		case Direction.upLeft:
			x12.combined = -x0E.combined;
			x16.combined = -x0E.combined;
			break;
		default: break;
	}
	entityDeltaXTable[currentEntitySlot] = x12.integer;
	entityDeltaXFractionTable[currentEntitySlot] = x12.fraction;
	entityDeltaYTable[currentEntitySlot] = x16.integer;
	entityDeltaYFractionTable[currentEntitySlot] = x16.fraction;
}

/// $C0CBD3
void unknownC0CBD3(short arg1) {
	entityScriptSleepFrames[currentScriptSlot] = cast(short)((cast(int)arg1 << 8) / entityMovementSpeed[currentEntitySlot]);
}

/// $C0CA4E
void unknownC0CA4E(short arg1) {
	FixedPoint1616 x0E;
	x0E.integer = entityDeltaXTable[currentEntitySlot];
	x0E.fraction = entityDeltaXFractionTable[currentEntitySlot];
	FixedPoint1616 x12;
	x12.integer = entityDeltaYTable[currentEntitySlot];
	x12.fraction = entityDeltaYFractionTable[currentEntitySlot];
	FixedPoint1616 x16;
	FixedPoint1616 x0A;
	if (0 > x12.combined) {
		x16.combined = -x12.combined;
	} else {
		x16 = x12;
	}
	if (0 > x0E.combined) {
		x0A.combined = -x0E.combined;
	} else {
		x0A = x0E;
	}
	if (x0A.combined > x16.combined) {
		if (0 > x0E.combined) {
			x0A.combined = -x0E.combined;
		} else {
			x0A = x0E;
		}
	} else {
		if (0 > x12.combined) {
			x0A.combined = -x12.combined;
		} else {
			x0A = x12;
		}
	}
	assert(x0A.combined != 0);
	entityScriptSleepFrames[currentScriptSlot] = cast(short)((arg1 << 16) / x0A.combined);
}

/// $C0CC11
void unknownC0CC11() {
	short x12 = cast(short)(entityScriptVar6Table[currentEntitySlot] - entityAbsXTable[currentEntitySlot]);
	short y = (0 > x12) ? (cast(short)-cast(int)x12) : x12;
	x12 = cast(short)(entityScriptVar7Table[currentEntitySlot] - entityAbsYTable[currentEntitySlot]);
	short x02 = (0 > x12) ? (cast(short)-cast(int)x12) : x12;
	FixedPoint1616 x0E;
	if (y > x02) {
		x12 = y;
		x0E.integer = entityDeltaXTable[currentEntitySlot];
		x0E.fraction = entityDeltaXFractionTable[currentEntitySlot];
	} else {
		x12 = x02;
		x0E.integer = entityDeltaYTable[currentEntitySlot];
		x0E.fraction = entityDeltaYFractionTable[currentEntitySlot];
	}
	x12 = cast(short)((x12 << 16) / x0E.combined);
	if (x12 == 0) {
		x12 = 1;
	}
	entityScriptSleepFrames[currentScriptSlot] = x12;
}

/// $C0CCCC
void unknownC0CCCC() {
	entityScriptVar6Table[currentEntitySlot] = entityAbsXTable[currentEntitySlot];
	entityScriptVar7Table[currentEntitySlot] = cast(short)(entityAbsYTable[currentEntitySlot] + 16);
	entityScriptVar5Table[currentEntitySlot] = cast(short)((cast(int)entityMovementSpeed[currentEntitySlot] * 16) / 64800) << 8;
	if ((rand() & 1) != 0) {
		entityDirections[currentEntitySlot] = Direction.up;
	} else {
		entityDirections[currentEntitySlot] = Direction.down;
	}
	if (entityDirections[currentEntitySlot] < Direction.down) {
		entityUnknown2DC6[currentEntitySlot] = 0;
	} else {
		entityUnknown2DC6[currentEntitySlot] = 0xFFFF;
	}
	entityScriptVar4Table[currentEntitySlot] = 0;
}

/// $C0CD50
short unknownC0CD50() {
	short x04 = entityUnknown2DC6[currentEntitySlot];
	short x02;
	if (x04 == 0) {
		x02 = cast(short)(entityScriptVar4Table[currentEntitySlot] + entityScriptVar5Table[currentEntitySlot]);
	} else {
		x02 = cast(short)(entityScriptVar4Table[currentEntitySlot] - entityScriptVar5Table[currentEntitySlot]);
	}
	entityScriptVar4Table[currentEntitySlot] = x02;
	auto x0E = unknownC41FFF(x02, 0x1000);
	FixedPoint1616 x1E;
	FixedPoint1616 x1A;
	x1A.integer = x0E.y;
	x1E.integer = x0E.x;
	x1A.combined >>= 8;
	x1E.combined >>= 8;
	FixedPoint1616 x22;
	x22.integer = entityScriptVar6Table[currentEntitySlot];
	FixedPoint1616 x26;
	x26.integer = entityScriptVar7Table[currentEntitySlot];
	FixedPoint1616 x12;
	x12.integer = entityAbsXTable[currentEntitySlot];
	x12.fraction = entityAbsXFractionTable[currentEntitySlot];
	FixedPoint1616 x16;
	x16.integer = entityAbsYTable[currentEntitySlot];
	x16.fraction = entityAbsYFractionTable[currentEntitySlot];
	FixedPoint1616 x2A;
	x2A.combined = x22.combined + x1A.combined - x12.combined;
	FixedPoint1616 x2E;
	x2E.combined = x26.combined + x1E.combined - x16.combined;
	entityDeltaXTable[currentEntitySlot] = x2A.integer;
	entityDeltaXFractionTable[currentEntitySlot] = x2A.fraction;
	entityDeltaYTable[currentEntitySlot] = x2E.integer;
	entityDeltaYFractionTable[currentEntitySlot] = x2E.fraction;
	if (x04 == 0) {
		return cast(short)(x02 + 0x4000);
	} else {
		return cast(short)(x02 - 0x4000);
	}
}

/// $C0CEBE
short unknownC0CEBE(short arg1) {
	short x04 = entityScriptVar4Table[currentEntitySlot];
	short x02 = x04;
	if (arg1 != x04) {
		short x;
		if (arg1 > x04) {
			if (arg1 - x04 >= 0) {
				x = 0;
			} else {
				x = -1;
			}
		} else {
			if (x04 - arg1 >= 0) {
				x = -1;
			} else {
				x = 0;
			}
		}
		if (x == 0) {
			x04 = cast(short)(x02 + 0x800);
		} else {
			x04 = cast(short)(x02 - 0x800);
		}
	}
	if (entityMovementSpeed[currentEntitySlot] < entityScriptVar3Table[currentEntitySlot]) {
		entityMovementSpeed[currentEntitySlot] += 16;
	}
	if (setMovingDirectionFromAngle(x02) != setMovingDirectionFromAngle(x04)) {
		updateEntitySprite(currentEntitySlot);
	}
	return x04;
}

/// $C0CF58
immutable ubyte[63] unknownC0CF58 = [ 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x04, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x01, 0x01, 0x02, 0x02, 0x03, 0x04 ];

/// $C0CF97
short unknownC0CF97(short arg1, short arg2) {
	//x1C = arg2
	ubyte x00 = cast(ubyte)arg1;
	const(ubyte)* x06 = &unknownC0CF58[0];
	short y = cast(short)(((entityAbsXTable[currentEntitySlot] - unknownC42A1F[entitySizes[currentEntitySlot]]) / 8) - 4);
	short x12 = cast(short)(((entityAbsYTable[currentEntitySlot] - unknownC42A41[entitySizes[currentEntitySlot]] + unknownC42AEB[entitySizes[currentEntitySlot]]) / 8) - 4);
	short x10 = y & 0x3F;
	short x18 = x12 & 0x3F;
	for (short i = 0; i != arg2; i++) {
		if ((x10 < 0x40) && (x18 < 0x40) && ((x00 & loadedCollisionTiles[x18 & 0x3F][x10 & 0x3F]) != 0)) {
			goto Unknown9;
		}
		short x0E = (x06++)[0];
		switch (x0E) {
			case 1:
				x18--;
				x12--;
				break;
			case 2:
				x10++;
				y++;
				break;
			case 3:
				x18++;
				x12++;
				break;
			case 4:
				x10--;
				y--;
				break;
			default: break;
		}
	}
	return 0;
	Unknown9:
	entityScriptVar6Table[currentEntitySlot] = cast(short)(y * 8 + unknownC42A1F[entitySizes[currentEntitySlot]]);
	entityScriptVar7Table[currentEntitySlot] = cast(short)(x12 * 8 - unknownC42AEB[entitySizes[currentEntitySlot]] + unknownC42A41[entitySizes[currentEntitySlot]]);
	return -1;
}

/// $C0D0D9
short unknownC0D0D9() {
	return unknownC0CF97(3, 60);
}

/// $C0D0E6
short unknownC0D0E6() {
	if ((unknownC0C363() == 0) && (entityPathfindingState[currentEntitySlot] != 0)) {
		entityAbsXTable[currentEntitySlot] = gameState.leaderX.integer;
		entityAbsYTable[currentEntitySlot] = gameState.leaderY.integer;
		return -1;
	}
	testEntityMovementActive();
	if ((unknownC05CD7(entityMovementProspectX, entityMovementProspectY, currentEntitySlot, Direction.down) & (SurfaceFlags.solid | SurfaceFlags.unknown2)) != 0) {
		entityMovementSpeed[currentEntitySlot] -= 0x1000;
		return 0;
	}
	entityAbsXTable[currentEntitySlot] = entityMovementProspectX;
	entityAbsYTable[currentEntitySlot] = entityMovementProspectY;
	return -1;
}

/// $C0D15C
short unknownC0D15C() {
	if ((playerMovementFlags & PlayerMovementFlags.collisionDisabled) != 0) {
		return 0;
	}
	if (entityCollidedObjects[partyLeaderEntity] == currentEntitySlot) {
		return -1;
	}
	if (((entityCollidedObjects[currentEntitySlot] & 0x8000) != 0) || (entityCollidedObjects[currentEntitySlot] < partyLeaderEntity)) {
		return 0;
	}
	return -1;
}

/// $C0D19B
void unknownC0D19B() {
	short x20 = touchedEnemy;
	enemyHasBeenTouched = 0;
	short x;
	short y;
	if (entityMovingDirection[touchedEnemy] == 8) {
		y = 0;
		x = 1;
	} else {
		short x04 = ((getScreenAngle(entityAbsXTable[x20], entityAbsYTable[x20], entityAbsXTable[enemyPathfindingTargetEntity], entityAbsYTable[enemyPathfindingTargetEntity]) + 0x1000) / 0x2000);
		switch ((entityMovingDirection[touchedEnemy] - x04) & 7) {
			case 0:
			case 1:
			case 7:
				 y = 1;
				 break;
			default:
				y = 0;
				break;
		}
		switch ((gameState.leaderDirection - x04) & 7) {
			case 0:
			case 1:
			case 7:
				x = 0;
				break;
			default:
				x = 1;
				break;
		}
	}
	battleInitiative = 0;
	if ((x == 1) && (y == 0)) {
		battleInitiative = Initiative.partyFirst;
	} else if ((y == 1) && (x == 0)) {
		battleInitiative = Initiative.enemiesFirst;
	}
	battleSwirlCountdown = 120;
	currentBattleGroup = entityNPCIDs[x20] & 0x7FFF;
	battleSwirlSequence();
	const(BattleGroupEnemy)* x06 = &battleEntryPointerTable[entityNPCIDs[x20] & 0x7FFF].enemies[0];
	for (short i = 0; i != 4; i++) {
		short x02 = x06.count;
		if (x02 != 0xFF) {
			short x1A = x02;
			if (x1A != 0) {
				y = x06.enemyID;
				if (y == entityEnemyIDs[x20]) {
					entityPathfindingState[x20] = -1;
					x1A--;
				}
				if (x1A != 0) {
					for (short j = 0; j != partyLeaderEntity; j++) {
						if (entityScriptTable[j] == -1) {
							continue;
						}
						if (y != entityEnemyIDs[j]) {
							continue;
						}
						entityPathfindingState[j] = -1;
					}
				}
			}
			x06++;
		} else {
			x02 = 0;
			y = 0;
		}
		pathfindingEnemyIDs[i] = y;
		pathfindingEnemyCounts[i] = x02;
	}
	enemiesInBattle = 0;
	findPathToParty(gameState.partyCount, 0x40, 0x40);
	x06 = &battleEntryPointerTable[currentBattleGroup].enemies[0];
	for (short i = 0; i != 4; i++) {
		short x14 = x06.count;
		if (x14 == 0xFF) {
			continue;
		}
		if (x14 != 0) {
			short x1A = x06.enemyID;
			if (x1A != 0) {
				short x18 = 0;
				for (short j = 0; j < pathfindingState.patherCount; j++) {
					if (pathfindingState.pathers[j].objIndex == x1A) {
						x18++;
					}
				}
				if (x18 > x14) {
					for (short j = cast(short)(x18 - x14); j-- != 0;) {
						short x10 = -1;
						short x1C = 0;
						for (short k = 0; k < pathfindingState.patherCount; k++) {
							if (entityEnemyIDs[pathfindingState.pathers[k].objIndex] != x1A) {
								continue;
							}
							if (pathfindingState.pathers[k].pointCount <= x1C) {
								continue;
							}
							x10 = x18;
							x1C = entityEnemyIDs[pathfindingState.pathers[k].pointCount];
						}
						if (pathfindingState.pathers[x10].objIndex != x20) {
							pathfindingState.pathers[x10].pointCount = 0;
							entityPathfindingState[pathfindingState.pathers[x10].objIndex] = 0;
						}
					}
				}
			}
		}
		x06++;
	}
	for (short i = 0; i < partyLeaderEntity; i++) {
		if (i == x20) {
			continue;
		}
		if (entityPathfindingState[i] == -1) {
			entityCallbackFlags[i] &= 0xFFFF ^ (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled);
		} else {
			entitySpriteMapFlags[i] |= SpriteMapFlags.drawDisabled;
		}
	}
	entityPathfindingState[x20] = 0;
	enemiesInBattleIDs[enemiesInBattle++] = entityEnemyIDs[x20];
}

/// $C0D4DE
void unknownC0D4DE() {
	memcpy(&buffer[0x2000], &palettes[0][0], 0x200);
	for (short i = 0; i < 0x80; i++) {
		ushort x18 = (cast(ushort*)&palettes[0][0])[i];
		short x16 = x18 & 0x1F;
		short x02 = (x18 >> 5) & 0x1F;
		short tmp = (x18 >> 10) & 0x1F;
		short x16_2 = (x16 + x02 + tmp) / 3;
		(cast(ushort*)&palettes[0][0])[i] = cast(ushort)(x16_2 << 10 + x16_2 << 5 + x16_2);
	}
	preparePaletteUpload(PaletteUpload.full);
}

/// $C0D59B
short unknownC0D59B() {
	if ((battleSwirlCountdown != 0) || (enemyHasBeenTouched != 0)) {
		return 1;
	}
	return 0;
}

/// $C0D5B0
short unknownC0D5B0() {
	if (battleMode != BattleMode.noBattle) {
		return 0;
	}
	if (usingDoor != 0) {
		return 0;
	}
	if ((battleSwirlCountdown == 0) || (currentEntitySlot != touchedEnemy)) {
		if (gameState.cameraMode == CameraMode.followEntity) {
			return 0;
		}
		if ((playerMovementFlags & PlayerMovementFlags.collisionDisabled) != 0) {
			return 0;
		}
		if (gameState.walkingStyle == WalkingStyle.escalator) {
			return 0;
		}
		if (playerIntangibilityFrames != 0) {
			return 0;
		}
		if ((battleSwirlCountdown == 0) || (entityPathPointsCount[currentEntitySlot] != 0)) {
			if (unknownC0D15C() == 0) {
				return 0;
			}
		}
	}
	if ((battleSwirlCountdown == 0) && (enemyHasBeenTouched == 0) && (entityEnemyIDs[currentEntitySlot] == EnemyID.magicButterfly)) {
		return 1;
	}
	if ((battleSwirlCountdown == 0) && (enemyHasBeenTouched == 0)) {
		enemyHasBeenTouched = 1;
		unknownC0D4DE();
		if (currentEntitySlot == entityCollidedObjects[partyLeaderEntity]) {
			enemyPathfindingTargetEntity = partyMemberEntityStart;
		} else {
			enemyPathfindingTargetEntity = entityCollidedObjects[currentEntitySlot];
		}
		touchedEnemy = currentEntitySlot;
		for (short i = 0; i < maxEntities; i++) {
			if (i == partyLeaderEntity) {
				continue;
			}
			entityCallbackFlags[i] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
		}
		switchToCameraMode3();
		return 1;
	}
	entityCollidedObjects[currentEntitySlot] = 0x8000;
	short x12 = 0;
	if (battleSwirlCountdown != 0) {
		if (currentEntitySlot == touchedEnemy) {
			entityCallbackFlags[currentEntitySlot] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
			x12 = 1;
		} else {
			x12 = 0;
			short y = 0;
			for (short i = 0; i != 4; i++) {
				if (entityEnemyIDs[currentEntitySlot] == pathfindingEnemyIDs[i]) {
					short x0E = pathfindingEnemyCounts[i];
					if (x0E != 0) {
						pathfindingEnemyCounts[i] = cast(short)(x0E - 1);
						x12 = 1;
						entityCallbackFlags[currentEntitySlot] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
						enemiesInBattleIDs[enemiesInBattle++] = entityEnemyIDs[currentEntitySlot];
					}
				}
				y += pathfindingEnemyCounts[i];
			}
			if ((y == 0) && (unknownC2E9C8() == 0)) {
				for (short i = 0; i < maxEntities; i++) {
					if (i == partyLeaderEntity) {
						continue;
					}
					entityCallbackFlags[i] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
				}
				battleSwirlCountdown = 1;
			}
		}
	}
	return x12;
}

/// $C0D7E0
void unknownC0D7E0() {
	if (entityPathfindingState[currentEntitySlot] != 0) {
		entityPathfindingState[currentEntitySlot] = 1;
	}
}

/// $C0D7F7
void unknownC0D7F7() {
	if (entityPathfindingState[currentEntitySlot] != -1) {
		return;
	}
	short x1C = entitySizes[currentEntitySlot];
	VecYX* x1A = entityPathPoints[currentEntitySlot];
	short x18 = entityAbsXTable[currentEntitySlot];
	short x16 = entityAbsYTable[currentEntitySlot];
	short x12 = cast(short)((pathfindingTargetCenterX - pathfindingTargetWidth * 8) + x1A.x * 8 + unknownC42A1F[x1C]);
	short x04 = cast(short)((pathfindingTargetCenterY - pathfindingTargetHeight * 8) + x1A.y * 8 - unknownC42AEB[x1C] + unknownC42A41[x1C]);
	short x10 = cast(short)(x18 - x12);
	if (0 > x10) {
		x10 = cast(short)-cast(int)x10;
	}
	if (3 > x10) {
		x10 = cast(short)(x16 - x04);
		if (0 > x10) {
			x10 = cast(short)-cast(int)x10;
		}
		if ((3 > x10) && (--entityPathPointsCount[currentEntitySlot] != 0)) {
			VecYX* x14 = &x1A[1];
			entityPathPoints[currentEntitySlot] = x14;
			x12 = cast(short)((pathfindingTargetCenterX - pathfindingTargetWidth) * 8 + x14.x * 8 + unknownC42A1F[x1C]);
			x04 = cast(short)((pathfindingTargetCenterY - pathfindingTargetHeight) * 8 + x14.y * 8 - unknownC42AEB[x1C] + unknownC42A41[x1C]);
		}
	}
	if (entityPathPointsCount[currentEntitySlot] != 0) {
		entityDirections[currentEntitySlot] = setMovingDirectionFromAngle(setMovementFromAngle(getScreenAngle(x18, x16, x12, x04)));
	} else {
		entityPathfindingState[currentEntitySlot] = 0;
		entityObstacleFlags[currentEntitySlot] |= 0x80;
	}
}

/// $C0D77F
void unknownC0D77F() {
	for (short i = 0; i < maxEntities; i++) {
		if (i == currentEntitySlot) {
			continue;
		}
		if (i == partyLeaderEntity) {
			continue;
		}
		entityCallbackFlags[i] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
	}
}

/// $C0D7B3
void actionScriptBackupPosition() {
	actionScriptBackupX = entityAbsXTable[currentEntitySlot];
	actionScriptBackupY = entityAbsYTable[currentEntitySlot];
}

/// $C0D7C7
void actionScriptRestorePositionBackup() {
	entityAbsXTable[currentEntitySlot] = actionScriptBackupX;
	entityAbsYTable[currentEntitySlot] = actionScriptBackupY;
}

/// $C0D98F
short unknownC0D98F() {
	if (entityPathPointsCount[currentEntitySlot] == 0) {
		return 0;
	}
	short x12 = entitySizes[currentEntitySlot];
	VecYX* x0E = entityPathPoints[currentEntitySlot];
	entityScriptVar6Table[currentEntitySlot] = cast(short)((x0E.x * 8) + unknownC42A1F[x12] + (pathfindingTargetCenterX - pathfindingTargetWidth) * 8);
	entityScriptVar7Table[currentEntitySlot] = cast(short)((x0E.y * 8) - unknownC42AEB[x12] + unknownC42A41[x12] + (pathfindingTargetCenterY - pathfindingTargetHeight) * 8);
	entityPathPointsCount[currentEntitySlot]--;
	entityPathPoints[currentEntitySlot] = x0E + 1;
	return 1;
}

/// $C0DA31
//this looks pretty ugly... is this right?
void actionScriptDrawEntitiesAlt() {
	if (firstEntity + 1 == 0) {
		return;
	}
	short x02 = 0;
	for (short i = 0; i != 0x1E; i++) {
		if (entityScriptTable[i] + 1 == 0) {
			continue;
		}
		if (entityDrawPriority[i] - 1 == 0) {
			if (((entityScreenYTable[i] + 8) & 0xFE00) == 0) {
				entityDrawSorting[x02++] = cast(short)(i + 1);
			} else {
				actionScriptDrawEntity(i);
			}
		}
	}
	entityDrawSorting[x02] = -1;
	for (short i = x02; i-- != 0;) {
		short j;
		for (j = 0; entityDrawSorting[j] == 0; j++) {}
		x02 = j;
		short x12 = j;
		short y = entityAbsYTable[entityDrawSorting[j] - 1];
		while (entityDrawSorting[++j] + 1 != 0) {
			if (entityDrawSorting[j] == 0) {
				continue;
			}
			if (y >= entityAbsYTable[entityDrawSorting[j - 1]]) {
				continue;
			}
			y = entityAbsYTable[entityDrawSorting[j - 1]];
			x12 = j;
		}
		actionScriptDrawEntity(cast(short)(entityDrawSorting[x12] - 1));
		entityDrawSorting[x12] = 0;
	}
}

/// $C0DB0F
void actionScriptDrawEntities() {
	if (padState[1] & Pad.select) {
		actionScriptDrawEntitiesAlt();
		return;
	}

	int entity = -1;
	uint entityOffset = firstEntity;

	// UNKNOWN6
	// I guess this is a micro-optimization they decided to add here...? We've seen what == -1 looks like normally,
	// and this is logically equivalent to that, but usually the compiler just does CMP #$FFFF
	while (entityOffset + 1) {
		if (entityScreenYTable[entityOffset / 2] < 256 || entityScreenYTable[entityOffset / 2] >= -64u) {
			// UNKNOWN3
			if (entityDrawPriority[entityOffset / 2] == 1) {
				entityDrawSorting[entityOffset / 2] = cast(short)entity;
				entity = entityOffset / 2;
			} else {
				// UNKNOWN4
				actionScriptDrawEntity(cast(short)(entityOffset / 2));
			}
		}
		// UNKNOWN5
		entityOffset = entityNextEntityTable[entityOffset / 2];
	}

	// UNKNOWN12
	// Same little optimization as above
	while (entity + 1) {
		uint drawnEntity = entity;
		uint maxY = entityAbsYTable[entity];
		uint dp04 = -1;
		uint dp02 = entity;
		uint y = entityDrawSorting[entity];
		// They really liked doing this huh...
		while (y + 1) {
			// UNKNOWN8
			if (entityAbsYTable[y] >= maxY) {
				maxY = entityAbsYTable[y];
				drawnEntity = y;
				dp04 = dp02;
			}
			// UNKNOWN9
			dp02 = y;
			y = entityDrawSorting[y];
		}
		actionScriptDrawEntity(cast(short)drawnEntity);

		if (dp04 + 1) {
			entityDrawSorting[dp04] = entityDrawSorting[drawnEntity];
		} else {
			// UNKNOWN11
			entity = entityDrawSorting[drawnEntity];
		}
	}
	// UNKNOWN13
}

/// $C0DBE6 - schedules a task to be run at some point in the future while on the overworld
short scheduleOverworldTask(short arg1, void function() arg2) {
	OverworldTask* task = &overworldTasks[0];
	short i;
	for (i = 0; i < 4; i++) {
		if (task.framesLeft == 0) {
			break;
		}
		task++;
	}
	task.framesLeft = arg1;
	task.func = arg2;
	return i;
}

/// $C0DC4E
void processOverworldTasks() {
	if ((frameCounter == 0) && (dadPhoneTimer != 0)) {
		dadPhoneTimer--;
	}
	if (windowHead != -1) {
		return;
	}
	if (battleModeFlag != 0) {
		return;
	}
	if (battleSwirlCountdown != 0) {
		return;
	}
	if (enemyHasBeenTouched != 0) {
		return;
	}
	for (short i = 0; i < overworldTasks.length; i++) {
		if (overworldTasks[i].framesLeft == 0) {
			continue;
		}
		if (--overworldTasks[i].framesLeft != 0) {
			continue;
		}
		overworldTasks[i].func();
	}
}

/// $C0DCC6
void loadDadPhone() {
	if (windowHead != -1) {
		return;
	}
	if (battleModeFlag != 0) {
		return;
	}
	if (battleSwirlCountdown != 0) {
		return;
	}
	if (enemyHasBeenTouched != 0) {
		return;
	}
	if (dadPhoneQueued != 0) {
		return;
	}
	if (getEventFlag(EventFlag.sysDis2HPapa) != 0) {
		return;
	}
	queueInteraction(InteractionType.textSurvivesDoorTransition, QueuedInteractionPtr(getTextBlock("MSG_SYS_PAPA_2H")));
	dadPhoneQueued = 1;
}

/** Wait enough frames for the active screen fade effect to complete
 * Original_Address: $(DOLLAR)C0DD0F
 */
void waitForFadeToFinish() {
	while (fadeParameters.step != 0) {
		oamClear();
		runActionscriptFrame();
		updateScreen();
		waitUntilNextFrame();
	}
}

/** Wait n frames
 * Original_Address: $(DOLLAR)C0DD2C
 */
void psiTeleportWaitNFrames(short n) {
	for (short i = n; i != 0; i--) {
		oamClear();
		runActionscriptFrame();
		updateScreen();
		waitUntilNextFrame();
	}
}

/** Initiate a PSI Teleport sequence
 * Original_Address: $(DOLLAR)C0DD53
 */
void setTeleportState(ubyte arg1, PSITeleportStyle arg2) {
	psiTeleportDestination = arg1;
	psiTeleportStyle = arg2;
}

/** Load the destination for a successful PSI Teleport
 * Original_Address: $(DOLLAR)C0DD79
 */
void psiTeleportLoadDestination() {
	for (short i = 1; i <= 10; i++) {
		setEventFlag(i, 0);
	}
	currentTeleportDestinationX = psiTeleportDestinationTable[psiTeleportDestination].x;
	currentTeleportDestinationY = psiTeleportDestinationTable[psiTeleportDestination].y;
	short x02 = cast(short)(currentTeleportDestinationX * 8);
	short x0E = cast(short)(currentTeleportDestinationY * 8);
	if (psiTeleportStyle != PSITeleportStyle.instant) {
		x02 += 0x13C;
	}
	currentMapMusicTrack = -1;
	loadedMapPalette = -1;
	loadedMapTileCombo = -1;
	initializeMap(x02, x0E, 6);
}

/** Set initial animation flags for party members starting to PSI Teleport
 * Original_Address: $(DOLLAR)C0DE16
 */
void setupTeleportingEntities() {
	for (short i = 0x18; i < 0x1E; i++) {
		entityScriptVar3Table[i] = 8;
		entityScriptVar7Table[i] |= PartyMemberMovementFlags.unknown11;
	}
}

/** Initialize PSI Teleport variables and entities
 * Original_Address: $(DOLLAR)C0DE46
 */
void initializePSITeleportation() {
	setupTeleportingEntities();
	psiTeleportBetaAngle = cast(short)(rand() << 8);
	if (psiTeleportStyle == PSITeleportStyle.psiBeta) {
		psiTeleportBetaProgress = 4;
	} else {
		psiTeleportBetaProgress = 8;
		psiTeleportBetterProgress = 0;
	}
	psiTeleportBetaXAdjustment = gameState.leaderX.integer;
	psiTeleportBetaYAdjustment = gameState.leaderY.integer;
}

/** Update teleportation speed based on old speed and teleportation stage
 * Original_Address: $(DOLLAR)C0DF22
 */
void psiTeleportUpdateSpeed(ushort direction) {
	FixedPoint1616 newSpeed;
	switch (teleportState) {
		case TeleportState.complete:
			if (gameState.specialGameState == SpecialGameState.useMiniSprites) {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction += 0x51E; // +0.02
				if (tmpSpeed.fraction < 0x51E) {
					tmpSpeed.integer++;
				}
				newSpeed = tmpSpeed;
			} else {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction += 0x3333; // + 0.2
				if (tmpSpeed.fraction < 0x3333) {
					tmpSpeed.integer++;
				}
				newSpeed = tmpSpeed;
			}
			break;
		case TeleportState.unknown3:
			if (gameState.specialGameState == SpecialGameState.useMiniSprites) {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction -= 0x1999; // + 0.1
				if (tmpSpeed.fraction >= 0x10000 - 0x1999) {
					tmpSpeed.integer--;
				}
				newSpeed = tmpSpeed;
			} else {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction -= 0x1999; // + 0.1
				if (tmpSpeed.fraction >= 0x10000 - 0x1999) {
					tmpSpeed.integer--;
				}
				newSpeed = tmpSpeed;
			}
			break;
		default:
			if (gameState.specialGameState == SpecialGameState.useMiniSprites) {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction += 0x29FB; // + 0.164
				if (tmpSpeed.fraction < 0x29FB) {
					tmpSpeed.integer++;
				}
				newSpeed = tmpSpeed;
			} else {
				FixedPoint1616 tmpSpeed;
				tmpSpeed.combined = teleportationSpeed.combined;
				tmpSpeed.fraction += 0x1851; // + 0.095
				if (tmpSpeed.fraction < 0x1851) {
					tmpSpeed.integer++;
				}
				newSpeed = tmpSpeed;
			}
			break;
	}
	teleportationSpeed.combined = newSpeed.combined;
	if ((direction & 1) != 0) {
		psiTeleportSpeedX.combined = ((newSpeed.combined >> 8) * 0xB505) >> 8; // sqrt(2) / 2
		psiTeleportSpeedY.combined = ((newSpeed.combined >> 8) * 0xB505) >> 8; // sqrt(2) / 2
	} else {
		psiTeleportSpeedX.combined = newSpeed.combined;
		psiTeleportSpeedY.combined = newSpeed.combined;
	}
	switch (direction) { //this is hard to read. were the cases rearranged to dedupe code?
		case Direction.up:
			psiTeleportSpeedY.combined = -psiTeleportSpeedY.combined;
			goto case;
		case Direction.down:
			psiTeleportSpeedX.combined = 0;
			break;
		case Direction.left:
			psiTeleportSpeedX.combined = -psiTeleportSpeedX.combined;
			goto case;
		case Direction.right:
			psiTeleportSpeedY.combined = 0;
			break;
		case Direction.upRight:
			psiTeleportSpeedY.combined = -psiTeleportSpeedY.combined;
			break;
		case Direction.upLeft:
			psiTeleportSpeedY.combined = -psiTeleportSpeedY.combined;
			goto case;
		case Direction.downLeft:
			psiTeleportSpeedX.combined = -psiTeleportSpeedX.combined;
			break;
		default: break;
	}
}

/** Restore control after a successful PSI Teleport
 * Original_Address: $(DOLLAR)C0DE7C
 */
void psiTeleportRestoreControl() {
	currentPartyMemberTick = &partyCharacters[0];
	for (short i = partyMemberEntityStart; i < partyMemberEntityStart + partyCharacters.length; i++) {
		entityScriptVar3Table[i] = 8;
		entityScriptVar7Table[i] &= ~PartyMemberMovementFlags.unknown11;
		entityCollidedObjects[i] &= 0x7FFF;
		currentPartyMemberTick.unknown55 = 0xFFFF;
		currentPartyMemberTick++;
	}
	changeMapMusicImmediately();
}

/** Perform a PSI Teleport collision check. Check both the leader's current position and the position where it will be
 * Original_Address: $(DOLLAR)C0DED9
 */
short psiTeleportCheckCollision(short curX, short curY, short nextX, short nextY, short) {
	if (teleportState != TeleportState.inProgress) {
		return 1;
	}
	return getSurfaceFlags(curX, curY, gameState.firstPartyMemberEntity) | getSurfaceFlags(nextX, nextY, gameState.firstPartyMemberEntity);
}

/// $C0E196
void writePartyLeaderStateToPositionBuffer() {
	playerPositionBuffer[gameState.leaderPositionIndex].xCoord = gameState.leaderX.integer;
	playerPositionBuffer[gameState.leaderPositionIndex].yCoord = gameState.leaderY.integer;
	playerPositionBuffer[gameState.leaderPositionIndex].tileFlags =getSurfaceFlags(gameState.leaderX.integer, gameState.leaderY.integer, gameState.firstPartyMemberEntity);
	playerPositionBuffer[gameState.leaderPositionIndex].walkingStyle = 0;
	playerPositionBuffer[gameState.leaderPositionIndex].direction = gameState.leaderDirection;
	gameState.leaderPositionIndex++;
	gameState.leaderPositionIndex &= 0xFF;
}

/** Get current position buffer index while PSI Teleporting
 * Original_Address: $(DOLLAR)C0E214
 */
short psiTeleportGetPositionIndex(short characterID, short currentIndex) {
	if (gameState.partyMemberIndex[0] == characterID + 1) {
		return cast(short)(currentIndex + 1);
	}
	if (teleportationSpeed.integer == 0) {
		return currentIndex;
	}
	return getNewPositionIndex(characterID, 6, currentIndex, 2);
}

/** Increase animation frame rate according to teleportation speed
 * Original_Address: $(DOLLAR)C0E254
 */
void psiTeleportUpdateAnimationSpeed() {
	ushort x10 = cast(ushort)(12 - teleportationSpeed.integer);
	//weird way to say x10 <= 0
	if ((x10 == 0) || ((x10 & 0x8000) != 0)) {
		x10 = 1;
	}
	for (short i = 0x18; i < 0x1D; i++) {
		entityScriptVar3Table[i] = x10;
	}
}

/** A single tick of PSI Teleport alpha movement
 * Original_Address: $(DOLLAR)C0E28F
 */
void psiTeleportAlphaLeaderTick() {
	gameState.leaderHasMoved = 1;
	ushort newDirection = mapInputToDirection(0);
	// no cheating. you have to actually turn
	if (gameState.leaderDirection == (newDirection ^ 4)) {
		newDirection = gameState.leaderDirection;
	}
	// invalid or no input, just keep going
	if (newDirection == 0xFFFF) {
		newDirection = gameState.leaderDirection;
	}
	gameState.leaderDirection = newDirection;
	// whoops we hit an enemy
	if (battleSwirlCountdown != 0) {
		teleportState = TeleportState.failed;
		battleMode = BattleMode.teleportFailed;
	}
	psiTeleportUpdateSpeed(newDirection);
	psiTeleportNextX.combined = psiTeleportSpeedX.combined + gameState.leaderX.combined;
	psiTeleportNextY.combined = psiTeleportSpeedY.combined + gameState.leaderY.combined;
	if (npcCollisionCheck(psiTeleportNextX.integer, psiTeleportNextY.integer, gameState.firstPartyMemberEntity) != -1) {
		teleportState = TeleportState.failed;
	}
	if ((psiTeleportCheckCollision(gameState.leaderX.integer, gameState.leaderY.integer, psiTeleportNextX.integer, psiTeleportNextY.integer, newDirection) & 0xC0) != 0) {
		teleportState = TeleportState.failed;
	}
	if (teleportState != TeleportState.failed) {
		gameState.leaderX = psiTeleportNextX;
		gameState.leaderY = psiTeleportNextY;
	}
	centerScreen(gameState.leaderX.integer, gameState.leaderY.integer);
	writePartyLeaderStateToPositionBuffer();
	psiTeleportUpdateAnimationSpeed();
	if (teleportationSpeed.integer > 9) {
		teleportState = TeleportState.complete;
	}
}

/** Update following party members while teleporting
 * Original_Address: $(DOLLAR)C0E3C1
 */
void psiTeleportFollowerTick() {
	currentPartyMemberTick = &partyCharacters[entityScriptVar1Table[currentEntitySlot]];
	doPartyMovementFrame(entityScriptVar0Table[currentEntitySlot], playerPositionBuffer[partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex].walkingStyle, currentEntitySlot);
	entityAbsXTable[currentEntitySlot] = playerPositionBuffer[partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex].xCoord;
	entityAbsYTable[currentEntitySlot] = playerPositionBuffer[partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex].yCoord;
	entityDirections[currentEntitySlot] = playerPositionBuffer[partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex].direction;
	entitySurfaceFlags[currentEntitySlot] = playerPositionBuffer[partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex].tileFlags;
	currentPartyMemberTick.positionIndex = cast(ubyte)psiTeleportGetPositionIndex(entityScriptVar0Table[currentEntitySlot], partyCharacters[entityScriptVar1Table[currentEntitySlot]].positionIndex);
}

/** Adjust the movement of PSI Teleport beta based on controller input
 * Original_Address: $(DOLLAR)C0E44D
 */
void adjustPSITeleportBetaDirection() {
	if (psiTeleportStyle == PSITeleportStyle.psiBetter) {
		return;
	}
	if ((padState[0] & Pad.up) != 0) {
		psiTeleportBetaYAdjustment--;
	}
	if ((padState[0] & Pad.down) != 0) {
		psiTeleportBetaYAdjustment++;
	}
	if ((padState[0] & Pad.left) != 0) {
		psiTeleportBetaXAdjustment--;
	}
	if ((padState[0] & Pad.right) != 0) {
		psiTeleportBetaXAdjustment++;
	}
}

/** Update PSI Teleport beta speed according to current direction
 * Original_Address: $(DOLLAR)C0E48A
 */
void psiTeleportUpdateBetaSpeed() {
	psiTeleportSpeedY.integer = 0;
	psiTeleportSpeedX.integer = 0;
	switch (gameState.leaderDirection) {
		case Direction.up:
			psiTeleportSpeedY.integer = -5;
			break;
		case Direction.upRight:
			psiTeleportSpeedY.integer = -5;
			psiTeleportSpeedX.integer = 5;
			break;
		case Direction.right:
			psiTeleportSpeedX.integer = 5;
			break;
		case Direction.downRight:
			psiTeleportSpeedY.integer = 5;
			psiTeleportSpeedX.integer = 5;
			break;
		case Direction.down:
			psiTeleportSpeedY.integer = 5;
			break;
		case Direction.downLeft:
			psiTeleportSpeedY.integer = 5;
			psiTeleportSpeedX.integer = -5;
			break;
		case Direction.left:
			psiTeleportSpeedX.integer = -5;
			break;
		case Direction.upLeft:
			psiTeleportSpeedY.integer = -5;
			psiTeleportSpeedX.integer = -5;
			break;
		default: break;
	}
}

/** Leader tick function for PSI Teleport beta movement
 * Original_Address: $(DOLLAR)C0E516
 */
void psiTeleportBetaLeaderTick() {
	gameState.leaderHasMoved = 1;
	adjustPSITeleportBetaDirection();
	auto betaSpiralMovementPosition = unknownC41FFF(psiTeleportBetaAngle, psiTeleportBetaProgress);
	psiTeleportNextX.integer = cast(short)((betaSpiralMovementPosition.x >> 8) + psiTeleportBetaXAdjustment);
	psiTeleportNextY.integer = cast(short)((betaSpiralMovementPosition.y >> 8) + psiTeleportBetaYAdjustment);
	if (psiTeleportStyle != PSITeleportStyle.psiBetter) {
		if ((psiTeleportCheckCollision(gameState.leaderX.integer, gameState.leaderY.integer, psiTeleportNextX.integer, psiTeleportNextY.integer, gameState.leaderDirection) & 0xC0) != 0) {
			teleportState = TeleportState.failed;
		}
		if (battleSwirlCountdown != 0) {
			teleportState = TeleportState.failed;
			battleMode = BattleMode.teleportFailed;
		}
		if (npcCollisionCheck(psiTeleportNextX.integer, psiTeleportNextY.integer, gameState.firstPartyMemberEntity) != -1) {
			teleportState = TeleportState.failed;
		}
	}
	if (teleportState != TeleportState.failed) {
		gameState.leaderX.integer = psiTeleportNextX.integer;
		gameState.leaderY.integer = psiTeleportNextY.integer;
	}
	gameState.leaderDirection = ((psiTeleportBetaAngle >> 13) + 2) & 7;
	teleportationSpeed.combined += 0x1851; // about +0.95
	if (psiTeleportStyle == PSITeleportStyle.psiBeta) {
		psiTeleportBetaAngle += 0xA00;
		psiTeleportBetaProgress += 0xC;
	} else {
		psiTeleportBetterProgress += 0x20;
		psiTeleportBetaAngle += psiTeleportBetterProgress;
		psiTeleportBetaProgress += 0x10;
	}
	centerScreen(gameState.leaderX.integer, gameState.leaderY.integer);
	writePartyLeaderStateToPositionBuffer();
	psiTeleportUpdateAnimationSpeed();
	if (psiTeleportStyle == PSITeleportStyle.psiBeta) {
		if (psiTeleportBetaProgress > 0x1000) { // complete in 340 frames (5.666 seconds)
			teleportState = TeleportState.complete;
			psiTeleportUpdateBetaSpeed();
		}
	} else {
		if (psiTeleportBetterProgress > 0x1800) { // complete in 192 frames (3.2 seconds)
			teleportState = TeleportState.complete;
			psiTeleportUpdateBetaSpeed();
		}
	}
}

/** Leader tick function for PSI Teleport departure
 *
 * Update speed, position, adjust screen position according to screen speed and update position buffer
 * Original_Address: $(DOLLAR)C0E674
 */
void psiTeleportSuccessDepartLeaderTick() {
	psiTeleportUpdateSpeed(gameState.leaderDirection);
	gameState.leaderX.combined += psiTeleportSpeedX.combined;
	gameState.leaderY.combined += psiTeleportSpeedY.combined;
	psiTeleportSuccessScreenX += psiTeleportSuccessScreenSpeedX;
	psiTeleportSuccessScreenY += psiTeleportSuccessScreenSpeedY;
	centerScreen(psiTeleportSuccessScreenX, psiTeleportSuccessScreenY);
	writePartyLeaderStateToPositionBuffer();
}

/** Leader tick function for PSI Teleport arrivals
 *
 * Update speed, position, center screen on leader, update position buffer and update animation speed
 * Original_Address: $(DOLLAR)C0E776
 */
void psiTeleportArriveLeaderTick() {
	psiTeleportUpdateSpeed(gameState.leaderDirection);
	gameState.leaderX.combined += psiTeleportSpeedX.combined;
	gameState.leaderX.combined += psiTeleportSpeedY.combined;
	centerScreen(cast(short)(gameState.leaderX.integer - ((teleportationSpeed.combined * 2) & 0xFFFF)), gameState.leaderY.integer);
	writePartyLeaderStateToPositionBuffer();
	psiTeleportUpdateAnimationSpeed();
}

/** Disables collision and teleports out of the current area
 * Original_Address: $(DOLLAR)C0E815
 */
void psiTeleportDepart() {
	if (psiTeleportStyle == PSITeleportStyle.instant) {
		return;
	}
	for (short i = 0x18; i < 0x1E; i++) {
		entityCollidedObjects[i] = 0x8000;
	}
	psiTeleportSpeedY.integer = 0;
	psiTeleportSpeedX.integer = 0;
	setPartyTickCallbacks(partyLeaderEntity, &psiTeleportSuccessDepartLeaderTick, &psiTeleportFollowerTick);
	psiTeleportSuccessScreenSpeedX = psiTeleportSpeedX.integer;
	psiTeleportSuccessScreenX = gameState.leaderX.integer;
	psiTeleportSuccessScreenSpeedY = psiTeleportSpeedY.integer;
	psiTeleportSuccessScreenY = gameState.leaderY.integer;
	fadeOut(1, 4);
	waitForFadeToFinish();
}

/** Fade in and finish teleporting into destination
 * Original_Address: $(DOLLAR)C0E897
 */
void psiTeleportArrive() {
	if (psiTeleportStyle == PSITeleportStyle.instant) {
		centerScreen(gameState.leaderX.integer, gameState.leaderY.integer);
		fadeIn(1, 1);
		waitForFadeToFinish();
		return;
	}
	for (short i = 0; i < 6; i++) {
		partyCharacters[i].unknown55 = 0xFFFF;
		version(noUndefinedBehaviour) {
			if (gameState.partyMemberIndex[i] == 0) {
				continue;
			}
		}
		doPartyMovementFrame(gameState.partyMemberIndex[i] - 1, 0, cast(short)(i + 0x18));
	}
	teleportationSpeed.fraction = 0;
	teleportationSpeed.integer = 8;
	gameState.leaderDirection = 6;
	teleportState = TeleportState.unknown3;
	setPartyTickCallbacks(partyLeaderEntity, &psiTeleportArriveLeaderTick, &psiTeleportFollowerTick);
	setupTeleportingEntities();
	changeMusic(Music.teleportIn);
	for (short i = 0; i < 0x1E; i++) {
		waitUntilNextFrame();
	}
	fadeIn(1, 4);
	while (teleportationSpeed.integer != 0) {
		oamClear();
		runActionscriptFrame();
		updateScreen();
		waitUntilNextFrame();
	}
	centerScreen(gameState.leaderX.integer, gameState.leaderY.integer);
}

/** Leader does nothing during a PSI Teleport fail
 * Original_Address: $(DOLLAR)C0E979
 */
void psiTeleportFailLeaderTick() {
	//nothing
}

/** When party members get to move, clean the soot off
 * $(DOLLAR)C0E97C
 */
void psiTeleportFailFollowerTick() {
	entitySurfaceFlags[currentEntitySlot] = getSurfaceFlags(entityAbsXTable[currentEntitySlot], entityAbsYTable[currentEntitySlot], currentEntitySlot);
	doPartyMovementFrame(entityScriptVar0Table[currentEntitySlot], -1, currentEntitySlot);
}

/** Player failed to teleport, update state as appropriate
 * Original_Address: $(DOLLAR)C0E9BA
 */
void psiTeleportFail() {
	disabledTransitions = 1;
	changeMusic(Music.teleportFail);
	for (short i = partyMemberEntityStart; i < maxEntities; i++) {
		entityScriptVar7Table[i] |= PartyMemberMovementFlags.unknown15;
	}
	setPartyTickCallbacks(partyLeaderEntity, &psiTeleportFailLeaderTick, &psiTeleportFailFollowerTick);
	gameState.partyStatus = PartyStatus.burnt;
	for (short i = 0; i < 180; i++) { // wait 3 seconds
		oamClear();
		runActionscriptFrame();
		updateScreen();
		waitUntilNextFrame();
	}
	gameState.partyStatus = PartyStatus.normal;
	disabledTransitions = 0;
}

/** Make sure all the non-party entities are frozen for PSI teleportation
 * Original_Address: $(DOLLAR)C0EA3E
 */
void psiTeleportFreezeObjects() {
	for (short i = 0; i < partyLeaderEntity; i++) {
		entityCallbackFlags[i] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
	}
}

/** Make sure all the non-party entities are frozen for PSI teleportation in a less expensive way suitable for a hot loop
 * Original_Address:$(DOLLAR)C0EA68
 */
void psiTeleportFreezeObjectsLoop() {
	for (short i = 0; i < partyLeaderEntity; i++) {
		if ((entityCallbackFlags[i] & (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled)) != (EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled)) {
			entityCallbackFlags[i] |= EntityCallbackFlags.tickDisabled | EntityCallbackFlags.moveDisabled;
		}
	}
}

/** Handles entire PSI teleportation process
 * Original_Address: $(DOLLAR)C0EA99
 */
void teleportMainLoop() {
	stopMusic();
	waitUntilNextFrame();
	psiTeleportFreezeObjects();
	unread7E5DBA = 1;
	teleportationSpeed.fraction = 0;
	teleportationSpeed.integer = 0;
	teleportState = TeleportState.inProgress;
	playerIntangibilityFlash();
	initializePSITeleportation();
	switch(psiTeleportStyle) {
		case PSITeleportStyle.psiAlpha:
		case PSITeleportStyle.learnAlpha:
			setPartyTickCallbacks(partyLeaderEntity, &psiTeleportAlphaLeaderTick, &psiTeleportFollowerTick);
			break;

		case PSITeleportStyle.psiBeta:
			setPartyTickCallbacks(partyLeaderEntity, &psiTeleportBetaLeaderTick, &psiTeleportFollowerTick);
			break;
		case PSITeleportStyle.instant:
			teleportState = TeleportState.complete;
			break;
		case PSITeleportStyle.psiBetter:
			setPartyTickCallbacks(partyLeaderEntity, &psiTeleportBetaLeaderTick, &psiTeleportFollowerTick);
			break;
		default: break;
	}
	if (psiTeleportStyle != PSITeleportStyle.instant) {
		changeMusic(Music.teleportOut);
	}
	while (teleportState == TeleportState.inProgress) {
		oamClear();
		runActionscriptFrame();
		psiTeleportFreezeObjectsLoop();
		updateScreen();
		waitUntilNextFrame();
	}

	switch (teleportState) {
		case TeleportState.complete:
			psiTeleportDepart();
			psiTeleportLoadDestination();
			psiTeleportArrive();
			if (psiTeleportStyle == PSITeleportStyle.learnAlpha) {
				displayTextWindowless(getTextBlock("MSG_EVT_MASTER_TLPT"));
			}
			break;
		case TeleportState.failed:
			psiTeleportFail();
			psiTeleportWaitNFrames(10);
			break;
		default: break;
	}
	setPartyTickCallbacks(partyLeaderEntity, &partyLeaderTick, &partyMemberTick);
	psiTeleportRestoreControl();
	unfreezeEntities();
	unread7E5DBA = 0;
	teleportationSpeed.fraction = 0;
	teleportationSpeed.integer = 0;
	playerIntangibilityFrames = 0;
	psiTeleportDestination = 0;
}

/// $C0EBE0
void loadTitleScreenGraphics() {
	decomp(&titleScreenGraphics[0], &buffer[0]);
	copyToVRAM(0, 0x8000, 0, &buffer[0]);
	decomp(&titleScreenArrangement[0], &buffer[0]);
	copyToVRAM(0, 0x1000, 0x5800, &buffer[0]);
	decomp(&unknownE1C6E5[0], &buffer[0]);
	copyToVRAM(0, 0x4000, 0x6000, &buffer[0]);
}

/// $C0EC77
void unknownC0EC77(short arg1) {
	if (arg1 == 0) {
		decomp(&unknownE1AE83[0], &buffer[0]);
	} else {
		decomp(&unknownE1AEFD[0], &buffer[0]);
	}
}

/// $C0ECB7
void unknownC0ECB7() {
	paletteUploadMode = PaletteUpload.none;
	decomp(&titleScreenPalette[0], &palettes[0][0]);
	unknownC496F9();
	memset(&palettes[0][0], 0, 0x100);
	unknownC496E7(0xA5, 0xFF);
	paletteUploadMode = PaletteUpload.full;
}

/// $C0ED14
void setBGPalettesWhite() {
	memset(&palettes[0][0], 0xFF, 0x100);
	paletteUploadMode = PaletteUpload.full;
}

/// $C0ED39
void setBGPalettesBlack() {
	memset(&palettes[0][0], 0, 0x100);
	paletteUploadMode = PaletteUpload.full;
}

/// $C0ED5C
void unknownC0ED5C() {
	paletteUploadMode = PaletteUpload.none;
	decomp(&titleScreenPalette[0], &palettes[0][0]);
	unknownC0EC77(0);
	memcpy(&palettes[8][0], &buffer[0x1A0], 0x20);
	unknownC0EC77(1);
	memcpy(&palettes[7][0], &buffer[0x260], 0x20);
	paletteUploadMode = PaletteUpload.full;
}

/// $C0EDD1
void unknownC0EDD1() {
	actionscriptState = ActionScriptState.titleScreenSpecial;
}

/// $C0EDDA
void unknownC0EDDA() {
	short x16 = entityScriptVar0Table[currentEntitySlot];
	short x14 = entityScriptVar1Table[currentEntitySlot];
	short x02 = entityScriptVar2Table[currentEntitySlot];
	memcpy(&palettes[x14][0], &buffer[x16 * 32], 0x20);
	short x12 = cast(short)(x16 + 1);
	if (x12 == x02) {
		x12 = 0;
	}
	entityScriptVar0Table[currentEntitySlot] = x12;
	paletteUploadMode = PaletteUpload.full;
}

/// $C0EE47
void unknownC0EE47() {
	mirrorTM = TMTD.obj | TMTD.bg2 | TMTD.bg1;
}

/// $C0EE53
void unknownC0EE53() {
	entitySpriteMapFlags[currentEntitySlot] &= ~SpriteMapFlags.drawDisabled;
}

/// $C0EE68
void logoScreenLoad(short arg1) {
	setBGMODE(BGMode.mode1 | BG3Priority);
	setBG3VRAMLocation(BGTileMapSize.normal, 0x4000, 0);
	mirrorTM = TMTD.bg3;
	switch (arg1) {
		case 0:
			decomp(&nintendoGraphics[0], &buffer[0]);
			decomp(&nintendoArrangement[0], &introBG2Buffer[0]);
			decomp(&nintendoPalette[0], &palettes[0][0]);
			break;
		case 1:
			decomp(&apeGraphics[0], &buffer[0]);
			decomp(&apeArrangement[0], &introBG2Buffer[0]);
			decomp(&apePalette[0], &palettes[0][0]);
			break;
		case 2:
			decomp(&halkenGraphics[0], &buffer[0]);
			decomp(&halkenArrangement[0], &introBG2Buffer[0]);
			decomp(&halkenPalette[0], &palettes[0][0]);
			break;
		default: break;
	}
	copyToVRAM(0, 0x8000, 0, &buffer[0]);
	copyToVRAM(0, 0x800, 0x4000, &introBG2Buffer[0]);
	paletteUploadMode = PaletteUpload.full;
}

/// $C0EFE1
short unknownC0EFE1(short arg1) {
	for (short i = arg1; i != 0; i--) {
		if (padPress[0] != 0) {
			return 1;
		}
		waitUntilNextFrame();
	}
	return 0;
}

/// $C0F009
short logoScreen() {
	logoScreenLoad(0);
	fadeInWithMosaic(1, 2, 0);
	if (debugging != 0) {
		unknownC0EFE1(0xB4);
	} else {
		for (short i = 0; i < 0xB4; i++) {
			waitUntilNextFrame();
		}
	}
	fadeOutWithMosaic(1, 2, 0);
	logoScreenLoad(1);
	fadeInWithMosaic(1, 2, 0);
	if (unknownC0EFE1(0x78) != 0) {
		fadeOutWithMosaic(2, 1, 0);
		return 1;
	}
	fadeOutWithMosaic(1, 2, 0);
	logoScreenLoad(2);
	fadeInWithMosaic(1, 2, 0);
	if (unknownC0EFE1(0x78) != 0) {
		fadeOutWithMosaic(2, 1, 0);
		return 1;
	}
	fadeOutWithMosaic(1, 2, 0);
	return 0;
}

/// $C0F0D2
void gasStationLoad() {
	bg2YPosition = 0;
	bg2XPosition = 0;
	bg1YPosition = 0;
	bg1XPosition = 0;
	decomp(&gasStationGraphics[0], &buffer[0]);
	copyToVRAM(0, 0xC000, 0, &buffer[0]);
	decomp(&gasStationArrangement[0], &buffer[0]);
	copyToVRAM(0, 0x800, 0x7800, &buffer[0]);
	decomp(&gasStationPalette[0], &palettes[0][0]);
	unknownC4A377();
	unknownC496F9();
	memset(&buffer[0x40], 0, 0x20);
	memset(&palettes[0][0], 0, 0x40);
	memset(&palettes[3][0], 0, 0x1A0);
	unknownC496E7(0x1E0, -1);
	mirrorTM = TMTD.bg1;
	mirrorTD = TMTD.bg2;
	CGWSEL = 2;
	CGADSUB = 3;
	paletteUploadMode = PaletteUpload.full;
}

/// $C0F1D2
void unknownC0F1D2(short arg1) {
	//the original code also seems to set the bank byte separately, for some reason.
	unknownC4954C(100, &palettes[0][0]);
	unknownC496E7(arg1, -1);
}

/** Runs the portion of the gas station intro screen that can end early when a button is pressed
 * Original_Address: $(DOLLAR)C0F21E
 */
short runGasStationSkippablePortion() {
	short result = 0;
	for (short i = 0; i < 236; i++) {
		if (padPress[0] != 0) {
			return 1;
		}
		drawBattleFrame();
		waitUntilNextFrame();
	}
	for (short i = 0; i < 480; i++) {
		if (padPress[0] != 0) {
			return 1;
		}
		memcpy(&mapPaletteBackup[0], &palettes[2][0], 0x20);
		updateMapPaletteAnimation();
		paletteUploadMode = PaletteUpload.none;
		replaceLoadedAnimatedLayer1Palette();
		memcpy(&palettes[2][0], &mapPaletteBackup[0], 0x20);
		drawBattleFrame();
		paletteUploadMode = PaletteUpload.full;
		waitUntilNextFrame();
	}
	unknownC49740();
	CGADSUB = 0;
	CGWSEL = 0;
	mirrorTM = TMTD.bg1;
	mirrorTD = TMTD.none;
	if (unknownC0EFE1(120) != 0) {
		return 1;
	}
	changeMusic(Music.gasStation2);
	short x12 = initEntityWipe(ActionScript.gasStationFlashing, 0, 0);
	while (entityScriptTable[x12] != -1) {
		runActionscriptFrame();
		waitUntilNextFrame();
		if (padPress[0] != 0) {
			deleteEntity(x12);
			return 1;
		}
	}
	unknownC0F1D2(330);
	return result;
}

/// $C0F33C
short gasStation() {
	unknownC0927C();
	gasStationLoad();
	fadeIn(1, 11);
	short x11 = runGasStationSkippablePortion();
	if (x11 != 0) {
		return 1;
	}
	for (short i = 0; i < 0x14A; i++) {
		if (padPress[0] != 0) {
			return 1;
		}
		updateMapPaletteAnimation();
		waitUntilNextFrame();
	}
	mirrorTM = TMTD.none;
	memset(&palettes[0][0], 0, 0x200);
	paletteUploadMode = PaletteUpload.full;
	if (x11 == 0) { //isn't this always true...?
		unknownC0EFE1(0x1E);
	}
	return x11;
}

/// $C0F3B2
void unknownC0F3B2() {
	decomp(&gasStationPalette2[0], &palettes[0][0]);
	preparePaletteUpload(PaletteUpload.full);
}

/// $C0F3E8
void unknownC0F3E8() {
	decomp(&gasStationPalette[0], &palettes[0][0]);
	preparePaletteUpload(PaletteUpload.full);
}

/// $C0F41E
void creditsScrollFrame() {
	if (bg3YPosition > creditsNextCreditPosition) {
		short x23 = creditsCurrentRow;
		short x21 = cast(short)(creditsCurrentRow + 1);
		creditsCurrentRow = (creditsCurrentRow + 2) & 0xF;
		short x04 = ((bg3YPosition / 8) + 29) & 0x1F;
		short x02 = 0;
		short x1F = 0;
		const(ubyte)* x1B = creditsSource;
		ushort* x17 = &bg2Buffer[x23 * 32];
		ushort* x0A = &bg2Buffer[x21 * 32];
		short x15 = (x1B++)[0];
		switch (x15) {
			case 1:
				creditsNextCreditPosition += 8;
				while (x1B[0] != 0) {
					(x17++)[0] = cast(ushort)((x1B++)[0] + 0x2000);
					x02++;
				}
				unknownC4EFC4(0, cast(short)(x02 * 2), cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)), cast(ubyte*)&bg2Buffer[x23 * 32]);
				break;
			case 2:
				creditsNextCreditPosition += 16;
				while (x1B[0] != 0) {
					(x17++)[0] = cast(ushort)(x1B[0] + 0x2400);
					(x0A++)[0] = cast(ushort)((x1B++)[0] + 0x2410);
					x02++;
				}
				unknownC4EFC4(0, cast(short)(x02 * 2), cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)), cast(ubyte*)&bg2Buffer[x23 * 32]);
				if (x04 != 0x1F) {
					x23 = cast(short)(cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)) + 0x20);
				} else {
					x23 = cast(short)(cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)) - 0x3E0);
				}
				unknownC4EFC4(0, cast(short)(x02 * 2), x23, cast(ubyte*)&bg2Buffer[x21 * 32]);
				break;
			case 3:
				creditsNextCreditPosition += x1B[0] * 8;
				break;
			case 4:
				ubyte* x15_2 = &gameState.earthboundPlayerName[0];
				if (x15_2[0] != 0) {
					for (short i = 0; x15_2[0] != 0; i++) {
						short x13 = x15_2[0];
						switch (x13) {
							case ebChar('♪'):
								creditsPlayerNameBuffer[i] = 0x7C;
								break;
							case 0xAE: //tilde
								creditsPlayerNameBuffer[i] = 0x7E;
								break;
							case 0xAF: //tall o
								creditsPlayerNameBuffer[i] = 0x7F;
								break;
							default:
								if (x13 > 0x90) {
									x13 -= 0x50;
								} else {
									x13 -= 0x30;
								}
								creditsPlayerNameBuffer[i] = cast(ubyte)x13;
								break;
						}
						x15_2++;
					}
					creditsNextCreditPosition += 16;
					for (short i = 0; (creditsPlayerNameBuffer[i] != 0) && (i < 24); i++) {
						(x17++)[0] = cast(ushort)((creditsPlayerNameBuffer[i] & 0xF0) + creditsPlayerNameBuffer[i] + 0x2400);
						(x0A++)[0] = cast(ushort)((creditsPlayerNameBuffer[i] & 0xF0) + creditsPlayerNameBuffer[i] + 0x2410);
						x02++;
					}
					unknownC4EFC4(0, cast(short)(x02 * 2), cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)), cast(ubyte*)&bg2Buffer[x23 * 32]);
					if (x04 != 0x1F) {
						x23 = cast(short)(cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)) + 0x20);
					} else {
						x23 = cast(short)(cast(short)((x04 * 32 + 0x6C10) - (x02 / 2)) - 0x3E0);
					}
					unknownC4EFC4(0, cast(short)(x02 * 2), x23, cast(ubyte*)&bg2Buffer[x21 * 32]);
				}
				x1B--;
				break;
			case 0xFF:
				creditsNextCreditPosition = 0xFFFF;
				break;
			default: break;
		}
		creditsSource = x1B + 1;
	}
	if (creditsRowWipeThreshold < bg3YPosition) {
		creditsRowWipeThreshold += 8;
		unknownC4EFC4(3, 0x40, ((((bg3YPosition / 8) - 1) & 0x1F) * 32) + 0x6C00, &blankTiles[0]);
	}
	creditsScrollPosition.combined += 0x4000;
	bg3YPosition = creditsScrollPosition.integer;
	unknownC0AD9F();
}

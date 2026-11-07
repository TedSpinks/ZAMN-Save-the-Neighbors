# Changelog

## 1.0.0
Changes since 0.9.0-beta.

### Fixed
- **Opening the pause map corrupted the bottom of big levels (pause map and all-in-one patches).** On levels 6, 12, 18, 19, 32, 35, 40, 41 and 48 the map's backup memory overlapped the end of the level's tile data, so after opening the map the bottom of the level showed a stray row of wrong tiles. The map now keeps its backup in the level layer's own tilemap and in memory no level uses, and redraws the level layer when it closes. The full-size map window is unchanged.
- **Tile graphics not fully restored after closing the map (pause map and all-in-one patches).** Part of the video memory the map draws over was not backed up, and its VRAM read test wrote into tile graphics. Both are fixed.
- **Joining mid-level could corrupt the level the same way (all-in-one patch).** The join prompt's buffers overlapped the level's tile data on the big levels; they moved.
- **Map showed areas you had never visited after a drop-in join (all-in-one patch).** The save and OPTIONS code kept scratch variables inside the map's explored-area array, so joining mid-level marked random spots as explored.
- **The secret bonus level password (BCDF) did not work (all-in-one patch).** OPTIONS treated its result as a wrong password. It now returns to the title as the original game does, and START plays the bonus level.

### Changed
- **OPTIONS title lettering (all-in-one patch).** The P, T and N were reshaped so every letter sits on the same slant as the rest of the word: the P now has a squarer top and a shorter stem (its rounded corner suited the start of the original PASSWORD, not the middle of a word), the T's stem ends one pixel higher, and the N's left stem no longer sags below the line. The top of the N is drawn by a spare sprite the original label already had.
- **OPTIONS: the R setting "ORIGINAL" is now "RADAR" (all-in-one patch).** It still does what it did (R opens the neighbor radar, as in the original game); the new name says what R does, and matches the game manual.

### Known limitations
- Two map markers of different colors in the same 8 x 8 cell share one color (for example both players close together, or a neighbor next to a player). The map's palette is set per cell, and moving a marker would misplace it, so this is left as is.

## 0.9.0-beta
First public beta: ZAMN: Save the Neighbors Edition (one main patch) plus individual patches: reverse fire, strafe, pause map, drop-in.

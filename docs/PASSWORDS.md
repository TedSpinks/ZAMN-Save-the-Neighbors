# ZAMN level passwords (for testing)

Passwords are four letters, entered on the PASSWORD screen (title menu: Down, A; on the all-in-one: OPTIONS -> PASSWORD). The game's own password system (not the save-game feature) starts a level directly, so they can be used to reach a given level in tests.

## Verified on the clean US ROM (2026-11-01)

Checked headless in Snes9x: enter the password, Start, Start at the character select, then read the level number at `7E:1E7C` and the level size (`$B2/2` x `$B4`). For scripted entry, tap each direction for 4 frames with 24-frame gaps; shorter taps drop cursor moves.

| Level | Working passwords | Size (tiles) |
|-------|-------------------|--------------|
| 5 | XHRS, VHRV, FHRX, PHRP | 152 x 144 |
| 9 | NBGW, PBGG, WBGR (all 10 victims) | 192 x 96 |
| 13 | BFCB, GFCY | 96 x 144 |
| 17 | FKYQ, KKYM, PKYT, RKYL, BKYZ | 120 x 104 |
| 21 | DXBR, BXBS, SXBK, PXBG, VXBB | 72 x 376 |
| 25 | PYLQ, GYLM, YYLL, XYLZ | 184 x 144 |
| 29 | YLZD, GLZJ, XLZG | 136 x 192 |
| 33 | LJQJ, XJQY, WJQK | 168 x 160 |
| 37 | FZVM, KZVJ, BZVG | 152 x 184 |
| 41 | FRPJ, KRPY, BRPK | 216 x 136 |
| 45 | BLHR, VLHX (all 10 victims) | 144 x 160 |

## Special codes

- **BCDF** - secret bonus level "Day of the Tentacle" (level 0, 136 x 144). The code sets `$1E7C = 0` and returns to the title (`82:B018`); START on the title, then Start at the character select, plays it. Fixed for the all-in-one in 1.0.0 (OPTIONS used to send it back to OPTIONS).
- **XWJR** - credits level (level 49, 160 x 96).
- **XDSJ** - bonus levels 53 (104 x 112), 54 (80 x 144) and 55 (184 x 88).

Not confirmed: FRCR and DBJK did not start a level in this run.

Note: lists found online label some of these as a different level (for example PHRP as level 6 and XHRS as level 4); the table above is what the game actually loads.

A password is confirmed by Start or END. The screen polls the pad every 4 frames, so a 3-frame tap of Start can be missed by a script; hold it 6 frames or more.

## Password screen grid

```
0 1 2 3 4 5 6
7 8 9 B C D F
G H J K L M N
P Q R S T V W
X Y Z . ! <- END
```
Cursor starts on 0. A enters the letter under the cursor; Start or END confirms.

# verify the memory dumps the vice monitor wrote during the smoke check.
#
# usage: LC_ALL=C awk -f verify.awk screen.bin hm.bin coins.bin zp.bin
#
# each dump is the raw output of the vice monitor "s" command: a two byte
# little endian load address header, then the memory contents. run awk in the
# C locale so every byte of the dump is one character; in a utf-8 locale gawk
# mangles the bytes above $7f and the byte counts come out wrong.

function slurp(file,   save) {
  save = RS
  RS = "^$"
  getline whole < file
  RS = save
  return whole
}

# read a vice monitor dump, skip the two byte load address header
function loadDump(file, want, arr,   s, i, n) {
  s = slurp(file)
  if (length(s) != want + 2) {
    print "FAIL " file " is " length(s) " bytes, want " want + 2
    bad++
    return
  }
  n = split(s, ch, "")
  for (i = 3; i <= want + 2; i++) arr[i - 3] = ord[ch[i]]
}

BEGIN {
  # how many frames the monitor script stepped; override with -v expectedFrames=N
  if (!expectedFrames) expectedFrames = 200

  # sprintf("%c", n) round trips for 0..255 in the C locale, so this is a
  # byte value lookup table for the characters the dump was split into
  for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i

  bad = 0

  loadDump(ARGV[1], 1000, scr)  # screen    $0400..$07e7
  loadDump(ARGV[2], 256, hm)    # heightmap $1000..$10ff
  loadDump(ARGV[3], 256, co)    # coin rows $1100..$11ff
  loadDump(ARGV[4], 32, zp)     # zero page $20..$3f
  if (bad > 0) exit 1

  fineScroll = zp[0x20 - 0x20]
  scrollX = zp[0x21 - 0x20]
  playerYhigh = zp[0x24 - 0x20]
  groundLevelHigh = zp[0x28 - 0x20]
  groundRow = zp[0x29 - 0x20]
  onGround = zp[0x2a - 0x20]
  frameCounter = zp[0x2b - 0x20]
  moveDirection = zp[0x2d - 0x20]

  # --- the main loop ran ---
  # the monitor stopped the cpu at .updateAnimation once per frame, so the
  # frame counter is how many frames the demo actually stepped. a demo that
  # crashed into a tight loop or never left the boot code shows up here.
  if (frameCounter < expectedFrames - 2) {
    print "FAIL frame counter is " frameCounter ", want at least " expectedFrames - 2
    bad++
  }

  # --- no input was given, so the world has not scrolled ---
  if (moveDirection != 0) { print "FAIL move direction is " moveDirection ", want 0"; bad++ }
  if (scrollX != 0) { print "FAIL scroll x is " scrollX ", want 0"; bad++ }
  if (fineScroll > 7) { print "FAIL fine scroll is " fineScroll ", want 0-7"; bad++ }

  # --- the runner stands on the terrain ---
  if (onGround != 1) { print "FAIL on ground flag is " onGround ", want 1"; bad++ }
  if (playerYhigh != groundLevelHigh) {
    print "FAIL player y " playerYhigh " is not the ground level " groundLevelHigh
    bad++
  }
  underPlayer = (scrollX + 13) % 256 ;# screen column under the sprite
  if (groundRow != hm[underPlayer]) {
    print "FAIL ground row " groundRow " does not match heightmap " hm[underPlayer]
    bad++
  }
  # y = 8 * groundRow + 32, the fixed point the physics uses
  if (groundLevelHigh != groundRow * 8 + 32) {
    print "FAIL ground level " groundLevelHigh " != 8*" groundRow "+32"
    bad++
  }

  # --- hud row 0: column 0 blank, then "JUMP AND RUN" ---
  # the title starts at column 1 on purpose: the hardware fine scroll shifts
  # the whole display up to seven pixels left, and a glyph in column 0 would
  # scroll off the edge at the wider phases.
  if (scr[0] != 32) { print "FAIL hud row 0 column 0 is " scr[0] ", want blank"; bad++ }
  want = "JUMP AND RUN"
  for (i = 1; i <= 12; i++) {
    c = sprintf("%c", scr[i])
    w = substr(want, i, 1)
    if (c != w) { print "FAIL hud row 0 column " i " is [" c "], want [" w "]"; bad++ }
  }

  # --- hud row 1: column 0 blank, then "SCORE " and three digits ---
  if (scr[40] != 32) { print "FAIL hud row 1 column 0 is " scr[40] ", want blank"; bad++ }
  want = "SCORE"
  for (i = 1; i <= 5; i++) {
    c = sprintf("%c", scr[40 + i])
    w = substr(want, i, 1)
    if (c != w) { print "FAIL hud row 1 column " i " is [" c "], want [" w "]"; bad++ }
  }
  for (i = 6; i <= 8; i++) {
    v = scr[40 + i]
    if (v < 48 || v > 57) { print "FAIL score digit column " i " is " v ", want 0-9"; bad++ }
  }

  # --- the heightmap is loaded and holds plausible ground rows ---
  for (w = 0; w < 256; w++) {
    if (hm[w] < 17 || hm[w] > 23) {
      print "FAIL heightmap column " w " is " hm[w] ", want 17-23"
      bad++
      break
    }
  }

  # --- world rows: screen matches the heightmap and the coin table ---
  coins = 0
  for (col = 0; col < 40; col++) {
    world = (scrollX + col) % 256
    g = hm[world]
    coin = co[world]
    for (r = 2; r < 25; r++) {
      v = scr[r * 40 + col]
      if (coin != 255 && r == coin) {
        coins++
        if (v != 36) { print "FAIL coin row " r " col " col " is " v ", want $"; bad++ }
        continue
      }
      expect = (r >= g) ? 160 : 32
      if (v != expect) {
        print "FAIL terrain row " r " col " col " is " v ", want " expect " (ground row " g ")"
        bad++
      }
    }
  }
  if (coins < 1) { print "FAIL no coins drawn on screen"; bad++ }

  if (bad > 0) {
    print "FAIL " bad " mismatches"
    exit 1
  }
  print "PASS " frameCounter " frames stepped, hud, score, runner and terrain verified, coins on screen " coins
  exit 0
}

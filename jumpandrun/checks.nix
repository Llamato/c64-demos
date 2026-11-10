{
  pkgs,
  cbmNix,
  drvname,
  drv,
  ...
}:
{
  # Boot the demo in a headless vice, step it 200 game frames through the
  # monitor, dump screen / heightmap / coin table / zero page and check that
  # what the demo painted matches the world it generated.
  #
  # the demo takes no raster interrupt - it polls $d019 in a loop - so there
  # is no kernal timer to break on. the monitor stops the cpu once per frame
  # at .updateAnimation, the last step of the main loop, which is also what
  # makes the frame counter in zero page a usable "did it keep running" check.
  demoBootsAndDrawsWorld =
    let
      monitorCommandsFile = ./moncheck.txt;
      verifyScript = ./verify.awk;
    in
    cbmNix.checkWithVice {
      name = "jumpandrunBootsAndDrawsWorld";
      emulator = "x64sc";
      fileUnderTest = "${drv}/${drvname}.prg";
      inherit monitorCommandsFile;
      failAfterSeconds = 120;
      warp = true;

      extraViceFlags = [
        # no sound hardware in the build sandbox: without this vice logs a
        # "initialization failed for device pulse" error every run
        "-sounddev dummy"
      ];

      preCheckPhase = ''
        # the headless ui wants these to exist under HOME before it starts
        mkdir -p "$HOME/.config/vice" "$HOME/.local/state/vice"
        cp ${drv}/${drvname}.vicelabels ${drvname}.vicelabels
      '';

      postCheckPhase = ''
        for f in screen.bin hm.bin coins.bin zp.bin; do
          if [ ! -s "$f" ]; then
            echo "vice wrote no $f dump: the monitor script never reached its save commands"
            exit 1
          fi
        done
        # the C locale matters: gawk must see one byte per character
        LC_ALL=C awk -f ${verifyScript} screen.bin hm.bin coins.bin zp.bin
        mkdir -p $out
        touch $out/pass
      '';
    };
}

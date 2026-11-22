{
  pkgs,
  cbmNix,
  drvname,
  drv,
  ...
}:
{
  prinoutMatchesInput =
    let
      # The printout is compared byte for byte against this file, so it may
      # only use characters that survive ASCII -> PETSCII -> printer -> ASCII
      # unchanged (no ` { | } ~), and no line may be wider than 73 columns:
      # the VICE ascii printer driver inserts a line break of its own once a
      # line has reached 74 characters.
      srcTextFilePath = ./test.txt;
      srcTextFilename = baseNameOf srcTextFilePath;
      monitorCommandsFile = pkgs.writeTextFile {
        name = "moncommands.txt";
        text = ''
          load_labels "${drv}/${drvname}.vicelabels"
          until .holdAndCatchFire
          log on
          trace
          quit
        '';
      };
    in
    cbmNix.checkWithVice {
      inherit monitorCommandsFile;
      name = "printoutMatchesInput";
      emulator = "x64sc";
      # test.txt is the full VIC-II article (~130 KB), which takes the
      # emulated printer well over half a minute to print out.
      failAfterSeconds = 300;
      fileUnderTest = "${drv}/${drvname}.d64";
      extraViceFlags = [
        "-trapdevice4"
        "-devicebackend4 1"
        "-pr4output text"
        "-pr4drv ascii"
        "-prtxtdev1 print.dump"
        ''-keybuf \"8\\x0d${srcTextFilename}\\x0d\"''
      ];

      postCheckPhase = ''
        cmp print.dump ${srcTextFilePath}
        mkdir -p $out 
        touch $out/pass
      '';
    };
}

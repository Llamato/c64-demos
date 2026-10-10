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
      failAfterSeconds = 30;
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

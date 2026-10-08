{ pkgs, cbmNix, drvname, drv, ... }: {
  prinoutMatchesInput = let 
    srcTextFilePath = ./test.txt;
    monitorCommandsFile = pkgs.writeTextFile {
      name = "moncommands.txt";
      text = ''
        load_labels "${drv}/${drvname}.vicelabels"
        until .holdAndCatchFire
        quit
      ''; 
    };
    keystrokesFile = pkgs.writeTextFile {
      name = "keystrokes.txt";
      text = ''8\x0dtest.txt\x0d'';
    };
  in
  cbmNix.checkWithVice {
    inherit monitorCommandsFile keystrokesFile;
    name = "printoutMatchesInput";
    emulator = "x64sc";
    fileUnderTest = "${drv}/${drvname}.d64";
    extraViceFlags = [
      ''-trapdevice4''
      ''-devicebackend4 1''
      ''-pr4output text''
      ''-pr4drv ascii''
      ''-prtxtdev1 print.dump''
    ];

    postCheckPhase = ''
      
      cmp print.dump ${srcTextFilePath}
      mkdir -p $out 
      touch $out/pass
    '';
  };
}
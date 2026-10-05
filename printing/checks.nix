{ pkgs, cbmNix, drvname, drv, ... }: {
  prinoutMatchesInput = let 
    srcTextFilePath = ./test.txt;
    prgFilePath = "./printing.prg";
    configFile = pkgs.writeTextFile {
      name = "emulatorconfig.txt";
      text = ''
        [Version]
        ConfigVersion=3.10

        [C64SC]
        Window0Height=654
        Window0Width=720
        Window0Xpos=920
        Window0Ypos=235
        TrapDevice4=1
        BusDevice4=1
        PrinterTextDevice1="print.dump"
        Printer4Output="text"
        Printer4Driver="ascii"
        Printer4=1
        Drive9Type=1541
      '';
    };
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
      text = ''8\x0d${drv}/${drvname}.d64\x0d'';
    };
  in
  cbmNix.checkWithVice {
    inherit configFile monitorCommandsFile keystrokesFile;
    name = "printoutMatchesInput";
    emulator = "x64sc";
    fileUnderTest = "${drv}/${drvname}.d64";
  };
}
{ pkgs, testPkgs, drvname, drvattrs, drv, ... }: {
  prinoutMatchesInput = let
    testFilename = "test.txt";
    testFilePath = "${drvattrs.src}/${testFilename}";
    monitorCommands = pkgs.writeTextFile {
      name = "moncommands.txt";
      text = ''
        load_labels "${drv}/${drvname}.vicelabels"
        until .holdAndCatchFire
        quit
      '';
    }; 
  in
  pkgs.runCommand ''printoutMatchesInput-test'' {

  } ''
    export HOME=$(mktemp -d)
    ${testPkgs.vice-headless}/bin/x64sc \
     -initbreak ready \
     -warp \
     -moncommands ${monitorCommands} \
     -autostart ${drv}/${drvname}.d64 \
     -trapdevice4 \
     -devicebackend4 1 \
     -pr4output text \
     -pr4drv ascii \
     -prtxtdev1 print.dump \
     -keybuf "8\x0d${testFilename}\x0d"
    
    cmp print.dump ${testFilePath}
    mkdir -p $out 
    touch $out/pass
  '';
}
// A tray slid into its module. The tray is built to the module's opening, so the
// helper function places it exactly where it runs.
//
//   openscad -o examples/assembly.png examples/assembly.scad
use <../ashrack.scad>
use <../tray.scad>

// The module: 2U, tray slot 20 mm from the mounting edge, 150 mm wide and deep.
half_rack_module(2, 20, 150, 150, "left");

// The tray, matching those same numbers.
translate(tray_position(20)) tray();

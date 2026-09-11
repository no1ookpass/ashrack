// A tray slid into its module. The tray is built to the module's opening, so the
// helper function places it exactly where it runs.
//
//   openscad -o examples/assembly.png examples/assembly.scad
//   openscad -o examples/assembly-1u.png -D units=1 examples/assembly.scad
use <../ashrack-panel.scad>
use <../ashrack-tray.scad>

// Rack units tall. Override from the command line, e.g. -D units=1
units = 2;

// The tray slot: 20 mm in from the mounting edge, 150 mm wide and 150 mm deep.
slot_offset = 20;
slot_width = 150;
slot_depth = 150;

// The module.
half_rack_module(units, slot_offset, slot_depth, slot_width, "left");

// The tray, matching those same numbers. tray() takes the units, width and depth
// it should be built to, so one tray model fits any module.
translate(tray_position(slot_offset))
    tray(units = units, width = slot_width, depth = slot_depth);

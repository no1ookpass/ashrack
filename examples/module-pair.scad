// Both halves butted together at the centre of the rack, showing the flush join
// and the interlocking joiner tabs.
//
// Both halves butted together at the centre of the rack, with a different tray
// slot on each side to show the halves are independent.
//
//   openscad -o examples/module-pair.png examples/module-pair.scad
//   openscad -o examples/module-pair-1u.png -D units=1 examples/module-pair.scad
//
// 482.6 is a full rack width: the right hand is the mirror, so shifting it by a
// whole rack width puts its mounting edge at the far rail.
use <../ashrack.scad>

// Rack units tall. Override from the command line, e.g. -D units=1
units = 2;

// Tray slots: wide and deep on the rail side, narrow and shallow on the centre
// side. half_rack_module takes units, then offset, depth and width.
left_width = 150;  left_depth = 150;
right_width = 110; right_depth = 80;

half_rack_module(units, 20, left_depth, left_width, "left");
translate([482.6, 0, 0]) half_rack_module(units, 20, right_depth, right_width, "right");

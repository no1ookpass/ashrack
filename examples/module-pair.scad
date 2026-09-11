// Both halves butted together at the centre of the rack, showing the flush join
// and the interlocking joiner tabs.
//
//   openscad -o examples/module-pair.png examples/module-pair.scad
//
// 482.6 is a full rack width: the right hand is the mirror, so shifting it by a
// whole rack width puts its mounting edge at the far rail.
use <../ashrack.scad>

half_rack_module(2, 20, 150, 150, "left");
translate([482.6, 0, 0]) half_rack_module(2, 20, 150, 150, "right");

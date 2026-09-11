// A whole rack width: both halves, each with its tray slid in.
//
//   openscad -o examples/pair-assembly.png examples/pair-assembly.scad
//   openscad -o examples/pair-assembly-1u.png -D units=1 examples/pair-assembly.scad
//
// Note how the right hand is assembled. half_rack_module(..., "right") already
// mirrors the body, so its tray needs its placement mirrored too, or it would
// land on the wrong side of the slot. Mirroring the tray along with the module
// also puts its handles and cut-outs the right way round.
use <../ashrack.scad>
use <../tray.scad>

// Rack units tall, and a different tray size on each side.
units = 2;
left_width = 150;  left_depth = 150;
right_width = 110; right_depth = 80;

// Left half: mounted at the near rail, its tray placed straight in.
half_rack_module(units, 20, left_depth, left_width, "left");
translate(tray_position(20)) tray(units = units, width = left_width, depth = left_depth);

// Right half: mirrored, then shifted a whole rack width so the two panels meet
// flush at the centre of the rack. Its tray is the narrow, shallow one, and its
// placement is mirrored along with the module or it would land on the wrong side
// of the slot.
translate([482.6, 0, 0]) {
    half_rack_module(units, 20, right_depth, right_width, "right");
    mirror([1, 0, 0]) translate(tray_position(20))
        tray(units = units, width = right_width, depth = right_depth);
}

// Ashrack tray - the drawer that slides into a module's tray slot.
//
// Front and floor are always solid. The side walls and the top can each be solid,
// solid with slits, or a criss-cross skeleton. Front cut-outs are listed in this
// file (see front_cutouts below).
//
// Coordinates match the module's opening, so the tray drops straight in:
//   X = 0 at the left of the opening, growing right
//   Y = 0 at the front face, growing backwards into the rack
//   Z = 0 at the bottom of the opening

include <ashrack_common.scad>

/* [Tray] */

// Rack units this tray is built for. Must match the module it goes into.
module_units = 2; // [1:1:8]

// Tray width (mm). Must match the module it goes into.
tray_width = 150; // [10:1:220]

// Tray depth (mm). Must match the module it goes into.
tray_depth = 150; // [10:1:600]

// Side walls
side_style = "skeleton"; // [solid, slits, skeleton]

// Back wall
back_style = "skeleton"; // [solid, slits, skeleton]

// Top: the tray's roof. Built into the body, or removable and screwed on.
top_style = "skeleton"; // [solid, slits, skeleton]
top_removable = false;

// Which part to build. With a removable top the roof is its own part, so print
// the body, then the top.
part = "body"; // [body, top]

/* [Hidden] */

// Slide clearance between the tray and the channel it runs in.
TRAY_SLIDE_CLEARANCE = 0.5;

// Slit styling: slots run along the depth, spaced across the wall.
SLIT_WIDTH = 5;
SLIT_PITCH = 12;
SLIT_BORDER = 8;

// Keep cut-outs this far inside the front face.
FRONT_CUTOUT_MARGIN = 2;

// Removable top: M3 screws, self-tapping into printed bosses. The top and its
// screws stay inside the tray's outer envelope, or the tray would jam in the
// channel it slides into: the roof sits on the rim and the heads sit in
// countersinks, so nothing stands proud of TRAY_H.
TOP_THICKNESS = WALL_THICKNESS;
TOP_BOSS_D = 7;
TOP_BOSS_HEIGHT = 8;
TOP_BOSS_BITE = 1;                   // boss overlap into the walls, so it fuses
TOP_SCREW_PILOT_D = 2.5;             // pilot for a self-tapping M3
TOP_SCREW_CLEARANCE_D = 3.4;
TOP_SCREW_HEAD_D = 6.2;
TOP_SCREW_HEAD_DEPTH = 1.7;

// Front cut-outs. One entry per cut-out, each a rounded rectangle:
//   [x, z, width, height, corner_radius]
// (x, z) is the cut-out's centre measured from the bottom left of the front face.
// A radius of half the smaller side gives a circle or a stadium slot. This list
// has to be edited here: the Customizer only accepts flat vectors of up to four
// numbers, so a list of cut-outs cannot be entered in the UI. For example:
//   front_cutouts = [[45, 40, 25, 15, 7.5], [105, 40, 14, 14, 7]];
front_cutouts = [];

// Tray outside size: the module's opening, less the slide clearance.
TRAY_W = opening_width(tray_width) - TRAY_SLIDE_CLEARANCE;
TRAY_H = opening_height(module_units) - TRAY_SLIDE_CLEARANCE;
TRAY_D = tray_depth;

// Walls stop short when the top is removable, so the roof finishes flush.
WALL_TOP = top_removable ? TRAY_H - TOP_THICKNESS : TRAY_H;

// Boss centres, pulled in far enough to bite into both walls at each corner.
TOP_BOSS_INSET = WALL_THICKNESS + TOP_BOSS_D / 2 - TOP_BOSS_BITE;
TOP_BOSS_POSITIONS = [
    for (x = [TOP_BOSS_INSET, TRAY_W - TOP_BOSS_INSET])
        for (y = [PANEL_THICKNESS + TOP_BOSS_INSET, PANEL_THICKNESS + TRAY_D - TOP_BOSS_INSET])
            [x, y]
];

// Where this tray sits inside its module. Handy for checking the fit: place the
// module, then translate the tray by this. The opening already includes the fit
// clearance, so only the slide clearance has to be centred in it.
function tray_position(tray_offset) = [
    tray_offset + TRAY_SLIDE_CLEARANCE / 2,
    0,
    TRAY_EDGE_MARGIN + TRAY_SLIDE_CLEARANCE / 2
];

// A rounded rectangle, centred on the origin. Radius is clamped so that half the
// smaller side gives a circle or a stadium.
module rounded_cutout(width, height, radius) {
    r = min(radius, min(width, height) / 2);
    if (r <= 0.01)
        square([width, height], center = true);
    else
        hull()
            for (sx = [-1, 1])
                for (sz = [-1, 1])
                    translate([sx * (width / 2 - r), sz * (height / 2 - r)])
                        circle(r = r, $fn = 32);
}

// Solid wall with a row of rounded slots down it.
module slit_panel(u_len, v_len) {
    slot_len = max(0.1, u_len - 2 * SLIT_BORDER);
    slots = max(1, floor((v_len - 2 * SLIT_BORDER) / SLIT_PITCH));

    difference() {
        square([u_len, v_len], center = true);

        for (i = [0 : slots - 1])
            translate([0, (i - (slots - 1) / 2) * SLIT_PITCH])
                rounded_cutout(slot_len, SLIT_WIDTH, SLIT_WIDTH / 2);
    }
}

// One wall, drawn flat and extruded across its thickness. u runs along the depth,
// v across the wall.
module wall_profile(u_len, v_len, style) {
    if (style == "slits")
        slit_panel(u_len, v_len);
    else if (style == "skeleton")
        braced_panel(u_len, v_len, v_len - 2 * RAIL_THICKNESS);
    else
        square([u_len, v_len], center = true);
}

// A corner boss for a top screw, fused to the walls and blind-drilled so the
// screw taps into it.
module top_boss(x, y) {
    translate([x, y, WALL_TOP - TOP_BOSS_HEIGHT])
        difference() {
            cylinder(d = TOP_BOSS_D, h = TOP_BOSS_HEIGHT, $fn = 32);

            // Pilot hole, open at the top, with a little material left below.
            translate([0, 0, 1.5])
                cylinder(d = TOP_SCREW_PILOT_D, h = TOP_BOSS_HEIGHT, $fn = 24);
        }
}

// The removable top: one piece covering the whole roof, screwed down onto the
// bosses. With top_removable = false the roof is part of the body instead.
module removable_top() {
    difference() {
        translate([TRAY_W / 2, PANEL_THICKNESS + TRAY_D / 2, TRAY_H - TOP_THICKNESS / 2])
            rotate([0, 0, 90])
                linear_extrude(height = TOP_THICKNESS, center = true)
                    wall_profile(TRAY_D, TRAY_W, top_style);

        for (p = TOP_BOSS_POSITIONS) {
            // Clearance hole.
            translate([p[0], p[1], TRAY_H - TOP_THICKNESS - 1])
                cylinder(d = TOP_SCREW_CLEARANCE_D, h = TOP_THICKNESS + 2, $fn = 24);

            // Countersink, so the head finishes below the tray's envelope.
            translate([p[0], p[1], TRAY_H - TOP_SCREW_HEAD_DEPTH])
                cylinder(d1 = TOP_SCREW_HEAD_D, d2 = TOP_SCREW_CLEARANCE_D,
                    h = TOP_SCREW_HEAD_DEPTH + 1, $fn = 24);
        }
    }
}

module tray() {
    assert(tray_width >= MIN_TRAY_WIDTH,
        "tray_width is too small: a module that narrow prints as a blank panel, so it has no slot to slide into");
    assert(TRAY_H > 0 && TRAY_D > 0, "module_units and tray_depth must leave a usable tray");

    for (c = front_cutouts)
        assert(c[0] - c[2] / 2 >= FRONT_CUTOUT_MARGIN && c[0] + c[2] / 2 <= TRAY_W - FRONT_CUTOUT_MARGIN
            && c[1] - c[3] / 2 >= FRONT_CUTOUT_MARGIN && c[1] + c[3] / 2 <= TRAY_H - FRONT_CUTOUT_MARGIN,
            "a front_cutout falls outside the front face, or too close to its edge");

    difference() {
        union() {
            // Front face: solid, and it fills the module's opening flush.
            cube([TRAY_W, PANEL_THICKNESS, TRAY_H]);

            // Floor: solid.
            translate([0, PANEL_THICKNESS, 0])
                cube([TRAY_W, TRAY_D, WALL_THICKNESS]);

            // Side walls, running from the floor up to the rim.
            for (x = [WALL_THICKNESS / 2, TRAY_W - WALL_THICKNESS / 2])
                translate([x, PANEL_THICKNESS + TRAY_D / 2, (WALL_THICKNESS + WALL_TOP) / 2])
                    rotate([0, 0, 90])
                        rotate([90, 0, 0])
                            linear_extrude(height = WALL_THICKNESS, center = true)
                                wall_profile(TRAY_D, WALL_TOP - WALL_THICKNESS, side_style);

            // Back wall.
            translate([
                TRAY_W / 2,
                PANEL_THICKNESS + TRAY_D - WALL_THICKNESS / 2,
                (WALL_THICKNESS + WALL_TOP) / 2
            ])
                rotate([-90, 0, 0])
                    linear_extrude(height = WALL_THICKNESS, center = true)
                        wall_profile(TRAY_W, WALL_TOP - WALL_THICKNESS, back_style);

            // Roof, sitting between the side walls, unless it is removable.
            if (!top_removable)
                translate([TRAY_W / 2, PANEL_THICKNESS + TRAY_D / 2, TRAY_H - WALL_THICKNESS / 2])
                    rotate([0, 0, 90])
                        linear_extrude(height = WALL_THICKNESS, center = true)
                            wall_profile(TRAY_D, TRAY_W - 2 * WALL_THICKNESS, top_style);

            // Bosses the removable top screws into.
            if (top_removable)
                for (p = TOP_BOSS_POSITIONS)
                    top_boss(p[0], p[1]);
        }

        // Front cut-outs, right through the front face.
        for (c = front_cutouts)
            translate([c[0], -1, c[1]])
                rotate([-90, 0, 0])
                    linear_extrude(height = PANEL_THICKNESS + 2)
                        rounded_cutout(c[2], c[3], c[4]);
    }
}

if (part == "top") {
    assert(top_removable,
        "part = \"top\" but top_removable is false: the roof is built into the tray body, so there is no separate top to print");
    removable_top();
} else {
    tray();
}

// Ashrack tray - the drawer that slides into a module's tray slot.
//
// Front and floor are always solid. The side walls, back wall and top can each be
// solid, solid with slits, or a criss-cross skeleton. The front cut-outs and the
// PCB mounts on the floor are both lists you edit in this file, further down.
//
// Coordinates match the module's opening, so the tray drops straight in:
//   X = 0 at the left of the opening, growing right
//   Y = 0 at the front face, growing backwards into the rack
//   Z = 0 at the bottom of the opening

include <ashrack-common.scad>

// Front cut-outs and PCB mounts are lists you edit here in the file. The
// Customizer cannot take a list of shapes (it only accepts flat vectors of up to
// four numbers), so this data lives in code where it can be any length.

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

// Handles on the front face, and which side of it they go on. The sides are
// named from the module's mounting edge: "rail" is the edge that screws to the
// rack, "centre" faces the middle of the rack. Left and right flip with the
// hand, so they are no good as names.
handle_sides = "none"; // [none, rail, centre, both]

// Handle shape: a half donut pull, or a knob
handle_type = "loop"; // [loop, knob]

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

// Handles. They sit on the front face and stand out in front of the rack, so
// they never have to pass through the opening; only the feet bite into the face.
// A loop stands upright, so its opening runs up the face and it takes a band
// that is tall rather than wide. With its feet it is 33 mm tall, which just fits
// a 1U face (33.2 mm), so lower HANDLE_LOOP_OPENING if you want more room.
HANDLE_INSET = 20;              // handle centre, in from the tray's edge
HANDLE_LOOP_OPENING = 24;       // the loop's span, between its two feet
HANDLE_TUBE = 3;                // half donut tube radius
HANDLE_FOOT_D = 9;              // pad where the loop lands on the face
HANDLE_FOOT_T = 2;
HANDLE_BITE = 0.6;              // how far the feet sink into the face
HANDLE_KNOB_D = 16;
HANDLE_STEM_D = 10;
HANDLE_KNOB_H = 12;             // how far the knob stands off the face

// Handle sides, indexed 0 = rail, 1 = centre.
function handle_on(index, sides = handle_sides) =
    sides == "both" ? true
    : sides == "none" ? false
    : sides == "rail" ? index == 0
    : index == 1;

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

// Front cut-outs: any number of openings in the front face, from zero up.
//
//   ["rect",   x, z, width, height]          a rectangular opening
//   ["circle", x, z, diameter, 0]            a round opening
//   ["rect",   x, z, width, height, radius]  a 6th value rounds the corners
//
// (x, z) is the centre of the opening, in mm from the bottom left corner of the
// front face. The face is TRAY_W wide and TRAY_H tall, and every opening must
// stay FRONT_CUTOUT_MARGIN inside it, so the usable range is roughly
// x = 2..TRAY_W-2 and z = 2..TRAY_H-2. A corner radius of half the shorter side
// turns the rectangle into a stadium slot (handy for connectors on flying leads).
//
// The two 1" ethernet openings and an LED for the current build, for example.
// Note where the handles land: each one takes roughly HANDLE_INSET +/- 15 mm, so
// keep cut-outs out of those bands. There is no guard against the two colliding.
//   ["rect",   52, 40, 25, 21],   // ethernet jack 1
//   ["rect",   82, 40, 25, 21],   // ethernet jack 2
//   ["circle", 105, 40,  8,  0],  // LED
front_cutouts = [];

// PCB mounts on the floor: any number of standoffs, from zero up. Each entry adds
// one more override, so you only write what differs from the defaults:
//
//   [x, y]                            default boss, height and screw
//   [x, y, height]                    a taller or shorter standoff
//   [x, y, height, boss_d]            ... and a different boss diameter
//   [x, y, height, boss_d, pilot_d]   ... and a different screw
//
// (x, y) is the centre of the standoff, in mm, measured from the tray's front
// left corner: x across the tray, y back from the front face, so y = 0 is the
// outside of the front face and the floor proper starts at y = PANEL_THICKNESS.
// The floor's usable area runs x = WALL_THICKNESS..TRAY_W-WALL_THICKNESS and
// y = PANEL_THICKNESS..PANEL_THICKNESS+TRAY_D. Defaults come from the PCB_
// constants above.
//
// A 100 x 60 board on four standoffs, with the back pair taller to clear a
// connector, for example:
//   [12, 12], [138, 12], [12, 60, 10], [138, 60, 10]
pcb_mounts = [];

// Tray outside size is derived inside tray() from the numbers it is given, so a
// script can build trays of different sizes to sit side by side. See the bottom
// of this file.

// PCB standoffs on the floor: a boss with a blind pilot hole for a screw. Sized
// per mount from its list entry, falling back to these defaults.
PCB_MOUNT_D = 7;                // boss diameter
PCB_MOUNT_H = 6;                // boss height off the floor
PCB_MOUNT_SINK = 0.6;           // how far the boss sinks into the floor, so it fuses
PCB_MOUNT_FLOOR = 1.5;          // material left under the pilot hole
PCB_SCREW_PILOT_D = 2.5;        // self-tapping M3 by default

// Boss centres for a tray of this width and depth, pulled in far enough to bite
// into both walls at each corner.
TOP_BOSS_INSET = WALL_THICKNESS + TOP_BOSS_D / 2 - TOP_BOSS_BITE;
function top_boss_positions(w, d) = [
    for (x = [TOP_BOSS_INSET, w - TOP_BOSS_INSET])
        for (y = [PANEL_THICKNESS + TOP_BOSS_INSET, PANEL_THICKNESS + d - TOP_BOSS_INSET])
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

// The 2D profile of one front cut-out, taken from its list entry.
module hole_profile(hole) {
    if (hole[0] == "circle")
        circle(d = hole[3], $fn = 64);
    else
        rounded_cutout(hole[3], hole[4], len(hole) > 5 ? hole[5] : 0);
}

// A PCB standoff: a boss on the floor with a blind pilot hole, open at the top.
module pcb_mount(x, y, height, boss_d, pilot_d, w, d) {
    assert(x >= WALL_THICKNESS + boss_d / 2 && x <= w - WALL_THICKNESS - boss_d / 2
        && y >= PANEL_THICKNESS + boss_d / 2 && y <= PANEL_THICKNESS + d - boss_d / 2,
        "a pcb_mount falls outside the floor, or runs into a wall or the front face");

    translate([x, y, WALL_THICKNESS - PCB_MOUNT_SINK])
        difference() {
            cylinder(d = boss_d, h = height + PCB_MOUNT_SINK, $fn = 32);

            translate([0, 0, PCB_MOUNT_FLOOR])
                cylinder(d = pilot_d, h = height - PCB_MOUNT_FLOOR + 0.1, $fn = 24);
        }
}

// Every PCB mount in the list, each entry overriding as much as it needs to.
module pcb_standoffs(w, d, mounts = pcb_mounts) {
    for (m = mounts)
        pcb_mount(m[0], m[1],
            len(m) > 2 ? m[2] : PCB_MOUNT_H,
            len(m) > 3 ? m[3] : PCB_MOUNT_D,
            len(m) > 4 ? m[4] : PCB_SCREW_PILOT_D, w, d);
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

// Half donut pull: a loop of round bar standing off the face, feet flush with it
// so it reads as a drawer bail. The bail stands upright, so it pulls out like a
// riser rather than lying along the face.
module loop_handle() {
    R = HANDLE_LOOP_OPENING / 2;

    // Turned in the plane of the face, so the loop's long axis runs up the tray
    // instead of across it. Rotating about Y keeps it standing off the face.
    rotate([0, 90, 0]) {
        // Feet, sunk a little into the face so they fuse to it.
        for (x = [-R, R])
            translate([x, HANDLE_BITE, 0])
                rotate([90, 0, 0])
                    cylinder(d = HANDLE_FOOT_D, h = HANDLE_FOOT_T + HANDLE_BITE, $fn = 32);

        // The half torus itself, standing out in front of the face.
        rotate([180, 0, 0])
            rotate_extrude(angle = 180, $fn = 64)
                translate([R, 0])
                    circle(r = HANDLE_TUBE, $fn = 24);
    }
}

// Knob on a short stem with a domed end. Prints as-is, no overhang.
module knob_handle() {
    straight = HANDLE_KNOB_H - HANDLE_KNOB_D / 2;

    translate([0, HANDLE_BITE, 0])
        rotate([90, 0, 0]) {
            cylinder(d = HANDLE_STEM_D, h = straight + HANDLE_BITE, $fn = 32);
            translate([0, 0, straight + HANDLE_BITE])
                sphere(d = HANDLE_KNOB_D, $fn = 32);
        }
}

// Handles where the user asked for them, on a tray of this width and height.
module handles(w, h, sides = handle_sides, type = handle_type) {
    for (i = [0, 1])
        if (handle_on(i, sides))
            translate([
                i == 0 ? HANDLE_INSET : w - HANDLE_INSET,
                0,
                h / 2
            ])
                if (type == "knob")
                    knob_handle();
                else
                    loop_handle();
}

// A corner boss for a top screw, fused to the walls and blind-drilled so the
// screw taps into it.
module top_boss(x, y, wall_top) {
    translate([x, y, wall_top - TOP_BOSS_HEIGHT])
        difference() {
            cylinder(d = TOP_BOSS_D, h = TOP_BOSS_HEIGHT, $fn = 32);

            // Pilot hole, open at the top, with a little material left below.
            translate([0, 0, 1.5])
                cylinder(d = TOP_SCREW_PILOT_D, h = TOP_BOSS_HEIGHT, $fn = 24);
        }
}

// The removable top: one piece covering the whole roof, screwed down onto the
// bosses. With top_removable = false the roof is part of the body instead.
module removable_top(units = module_units, width = tray_width, depth = tray_depth) {
    TRAY_W = opening_width(width) - TRAY_SLIDE_CLEARANCE;
    TRAY_H = opening_height(units) - TRAY_SLIDE_CLEARANCE;
    TRAY_D = depth;

    difference() {
        translate([TRAY_W / 2, PANEL_THICKNESS + TRAY_D / 2, TRAY_H - TOP_THICKNESS / 2])
            rotate([0, 0, 90])
                linear_extrude(height = TOP_THICKNESS, center = true)
                    wall_profile(TRAY_D, TRAY_W, top_style);

        for (p = top_boss_positions(TRAY_W, TRAY_D)) {
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

// A tray. The defaults build the one the Customizer describes; pass units, width
// and depth to build a different one, which is how the examples put two sizes
// side by side. cutouts, mounts and the two handle settings all default to the
// ones above, so a build script can hand over its own without touching this
// file's defaults.
module tray(units = module_units, width = tray_width, depth = tray_depth,
            cutouts = front_cutouts, mounts = pcb_mounts,
            handle_sides = handle_sides, handle_type = handle_type) {
    // Outside size: the module's opening, less the slide clearance.
    TRAY_W = opening_width(width) - TRAY_SLIDE_CLEARANCE;
    TRAY_H = opening_height(units) - TRAY_SLIDE_CLEARANCE;
    TRAY_D = depth;

    // Walls stop short when the top is removable, so the roof finishes flush.
    WALL_TOP = top_removable ? TRAY_H - TOP_THICKNESS : TRAY_H;

    assert(width >= MIN_TRAY_WIDTH,
        "tray_width is too small: a module that narrow prints as a blank panel, so it has no slot to slide into");
    assert(TRAY_H > 0 && TRAY_D > 0, "module_units and tray_depth must leave a usable tray");

    for (c = cutouts)
        assert(c[1] - c[3] / 2 >= FRONT_CUTOUT_MARGIN && c[1] + c[3] / 2 <= TRAY_W - FRONT_CUTOUT_MARGIN
            && c[2] - c[4] / 2 >= FRONT_CUTOUT_MARGIN && c[2] + c[4] / 2 <= TRAY_H - FRONT_CUTOUT_MARGIN,
            "a front_cutout falls outside the front face, or too close to its edge");

    difference() {
        union() {
            // Front face: solid, and it fills the module's opening flush.
            cube([TRAY_W, PANEL_THICKNESS, TRAY_H]);

            // Floor: solid.
            translate([0, PANEL_THICKNESS, 0])
                cube([TRAY_W, TRAY_D, WALL_THICKNESS]);

            // PCB mounts on the floor.
            pcb_standoffs(TRAY_W, TRAY_D, mounts);

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

            // Handles on the front face.
            handles(TRAY_W, TRAY_H, handle_sides, handle_type);

            // Bosses the removable top screws into.
            if (top_removable)
                for (p = top_boss_positions(TRAY_W, TRAY_D))
                    top_boss(p[0], p[1], WALL_TOP);
        }

        // Front cut-outs, right through the front face.
        for (c = cutouts)
            translate([c[1], -1, c[2]])
                rotate([-90, 0, 0])
                    linear_extrude(height = PANEL_THICKNESS + 2)
                        hole_profile(c);
    }
}

if (part == "top") {
    assert(top_removable,
        "part = \"top\" but top_removable is false: the roof is built into the tray body, so there is no separate top to print");
    removable_top(module_units, tray_width, tray_depth);
} else {
    tray(module_units, tray_width, tray_depth);
}

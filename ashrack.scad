// Ashrack - half rack, modular rack mount system.
//
// Front module plus tray support for one half of a standard 19" rack.
// Both hands come from the same geometry, mirrored with a transform, so
// there is never a second model file to maintain.
//
// Local coordinate system of the module body:
//   X = 0 at the rack mounting edge, growing towards the rack centre
//   Y = 0 at the front face, growing backwards into the rack
//   Z = 0 at the bottom of the panel

/* [Module] */

// Module height in rack units
module_units = 2; // [1:1:8]

// Tray offset from the mounting edge (mm)
tray_offset = 20; // [0:1:220]

// Tray depth (mm)
tray_depth = 150; // [10:1:600]

// Tray width (mm). Zero makes this a blank panel: no opening, no tray frame.
tray_width = 150; // [0:1:220]

// Rack side this module mounts to
side = "left"; // [left, right]

// Mounting ear thickness, as a multiple of the panel thickness. Measured
// front to back from the panel face, so 1x leaves no ear material.
ear_thickness = 5; // [1:1:8]

// Rack screw holes per rack unit: 1 centre, 2 outer pair, 3 all three
screw_holes = 3; // [1:1:3]

/* [Hidden] */

$fn = 64;

// Standard 19" EIA rack dimensions - fixed, do not customise.
RACK_UNIT = 44.45;
RACK_WIDTH = 482.6;
RACK_MOUNT_HOLE_SPACING = 465.1;
RACK_CLEAR_WIDTH = 450.8;

// Module material and stand-offs.
PANEL_THICKNESS = 3;
PANEL_HEIGHT_CLEARANCE = 0.8;
RAIL_THICKNESS = 3;

// The ear bridges the mounting edge to the tray frame, so its width follows the
// tray offset and always meets the tray container. Only its thickness is scaled
// by the user (front to back, as a multiple of the panel).
EAR_THICKNESS = ear_thickness * PANEL_THICKNESS;
EAR_EDGE_MARGIN = 3;

// Rack mounting hole geometry. The diameter is a standard screw clearance - M5
// is the common 19" rack screw (M6 clearance is 6.4, 10-32 is 4.9).
MOUNT_HOLE_D = 5.2;
MOUNT_HOLE_X = (RACK_WIDTH - RACK_MOUNT_HOLE_SPACING) / 2;

// EIA-310 rack holes sit this far above the unit's lower edge: the outer pair
// close to the panel edges, the middle one on the unit centre line. 15.875 is
// the spacing between holes within a group, not a position.
MOUNT_HOLE_CENTRE = 22.225;
MOUNT_HOLE_OUTER = [6.35, 38.1];
MOUNT_HOLE_ALL = [6.35, 22.225, 38.1];
MOUNT_HOLE_EDGE_MARGIN = 4;

// Hole offsets within a unit for the requested number of holes per unit.
function mount_hole_offsets(per_unit) =
    per_unit <= 1 ? [MOUNT_HOLE_CENTRE]
    : per_unit == 2 ? MOUNT_HOLE_OUTER
    : MOUNT_HOLE_ALL;

// Hole depth follows the ear thickness: the hole passes through the panel and
// through whatever ear material sits behind it.
MOUNT_HOLE_DEPTH = EAR_THICKNESS;

// Tray fit.
TRAY_EDGE_MARGIN = 5;
TRAY_FIT_CLEARANCE = 0.4;

// Below this tray width the channel is too narrow to frame - the join fillet
// alone would fill it in - so anything smaller prints as a blank panel instead.
// Keeps the width slider usable all the way down to 0.
MIN_TRAY_WIDTH = 10;

// Nominal spacing of the criss-cross cells along the tray depth. Cells are kept
// even along the depth so the lattice repeats uniformly.
FRAME_PITCH = 70;

// Width of the criss-cross bars as a multiple of the rail thickness. The bars
// spread sideways in the face they lie in but keep their thickness across it, so
// the frame gets fatter without getting any taller.
FRAME_BAR_SPREAD = 2;

// A half rack module occupies half of the clear rack opening.
MODULE_WIDTH = RACK_CLEAR_WIDTH / 2;

// Panel height for a given number of rack units.
function module_height(units) = units * RACK_UNIT - PANEL_HEIGHT_CLEARANCE;

// Standard mounting hole heights for a panel of the given rack unit count and
// hole count. The panel is centred in its rack space, so the pattern shifts too.
function mount_hole_positions(units, per_unit) =
    let (h = module_height(units), space_bottom = -PANEL_HEIGHT_CLEARANCE / 2)
    [ for (u = [0 : units - 1])
        for (offset = mount_hole_offsets(per_unit))
            let (zz = u * RACK_UNIT + offset + space_bottom)
            if (zz > MOUNT_HOLE_EDGE_MARGIN && zz < h - MOUNT_HOLE_EDGE_MARGIN)
                zz ];

// Radius of the concave fillet applied where bars join and cross. This is what
// makes a crossing read as ")(" instead of "><".
JOIN_FILLET = 2;

// One face of the tray frame, drawn flat so the joins can be filleted in 2D.
// u runs along the tray depth, v runs across the face. A closing pass (offset out
// then back in) fills the concave joins, so crossings and rail junctions come out
// as scooped curves while the bars themselves stay flat straps: the fillet only
// ever moves material in the face plane, so it adds no height and cannot grow
// into the tray channel.
module face_pattern(depth, span, rise) {
    r = RAIL_THICKNESS;
    cells = max(1, round(depth / FRAME_PITCH));
    cell = depth / cells;
    bar_length = sqrt(cell * cell + rise * rise) + r;
    angle = atan2(rise, cell);

    // Trimmed to the face so the scooped joins and the bar overshoot cannot poke
    // past the rails or the ends of the frame.
    intersection() {
        offset(r = -JOIN_FILLET, $fn = 32)
            offset(r = JOIN_FILLET, $fn = 32)
                union() {
                    // Edge rails, running the full tray depth.
                    for (v = [1, -1])
                        translate([0, v * (span - r) / 2])
                            square([depth, r], center = true);

                    // Criss-cross bars, braced across the face.
                    for (i = [0 : cells - 1])
                        for (side = [1, -1])
                            translate([cell * (i + 0.5) - depth / 2, 0])
                                rotate(side * angle)
                                    square([bar_length, FRAME_BAR_SPREAD * r], center = true);
                }

        square([depth, span], center = true);
    }
}

// Open tray container: four corner rails braced by a criss-cross lattice on each
// face, instead of solid walls. The frame assumes nothing about what gets slid
// into it, so it stays open and uses minimal material.
module tray_frame(offset, depth, opening_w, opening_h) {
    r = RAIL_THICKNESS;
    y0 = PANEL_THICKNESS;
    x0 = offset - r;
    z0 = TRAY_EDGE_MARGIN - r;
    frame_w = opening_w + 2 * r;
    frame_h = opening_h + 2 * r;
    mid_y = y0 + depth / 2;

    // Side faces: pattern lies in the YZ plane, extruded across X. The pattern is
    // symmetric across v, so the mirrored v axis is harmless.
    for (x = [x0 + r / 2, x0 + frame_w - r / 2])
        translate([x, mid_y, z0 + frame_h / 2])
            rotate([0, 0, 90])
                rotate([90, 0, 0])
                    linear_extrude(height = r, center = true)
                        face_pattern(depth, frame_h, opening_h);

    // Top and bottom faces: pattern lies in the XY plane, extruded across Z.
    for (z = [z0 + r / 2, z0 + frame_h - r / 2])
        translate([x0 + frame_w / 2, mid_y, z])
            rotate([0, 0, 90])
                linear_extrude(height = r, center = true)
                    face_pattern(depth, frame_w, opening_w);
}

// One handed module, built with its mounting edge on X = 0.
module module_body(units, offset, depth, width) {
    h = module_height(units);
    opening_h = h - 2 * TRAY_EDGE_MARGIN;
    opening_w = width + 2 * TRAY_FIT_CLEARANCE;

    // Anything from zero up to the minimum prints as a blank panel: nothing is
    // going to slide into a channel that narrow anyway, and framing it would
    // just fill the channel in with fillet material.
    trays = width >= MIN_TRAY_WIDTH;

    // Ear reaches from the mounting edge to the outside of the tray frame, so
    // the two always meet whatever the tray offset is.
    ear_width = offset - RAIL_THICKNESS;

    assert(ear_width >= MOUNT_HOLE_X + MOUNT_HOLE_D / 2 + EAR_EDGE_MARGIN,
        "tray_offset is too small: the mounting ear has to be wide enough to carry the rack hole");
    assert(!trays || offset + opening_w + RAIL_THICKNESS <= MODULE_WIDTH,
        "tray_offset + tray_width is too large to fit a half rack module");
    assert(width >= 0, "tray_width cannot be negative");
    assert(depth > 0, "tray_depth must be greater than zero");
    assert(opening_h > 0, "module_units is too small to fit a tray");

    difference() {
        union() {
            // Front panel.
            cube([MODULE_WIDTH, PANEL_THICKNESS, h]);

            // Rack mounting ear, behind the panel on the mounting edge. It spans
            // the gap between the mounting edge and the tray frame.
            if (EAR_THICKNESS > PANEL_THICKNESS)
                translate([0, PANEL_THICKNESS, 0])
                    cube([ear_width, EAR_THICKNESS - PANEL_THICKNESS, h]);

            // Tray support frame behind the opening, unless this is a blank.
            if (trays)
                tray_frame(offset, depth, opening_w, opening_h);
        }

        // Tray opening through the front panel and the channel keep-out behind
        // it. Both are skipped on a blank, which leaves the panel solid.
        if (trays) {
            translate([offset, -1, TRAY_EDGE_MARGIN])
                cube([opening_w, PANEL_THICKNESS + 2, opening_h]);

            // The framed container is open anyway, but this guarantees the
            // slide path stays clear for the tray.
            translate([offset, PANEL_THICKNESS - 1, TRAY_EDGE_MARGIN])
                cube([opening_w, depth + 2, opening_h]);
        }

        // Rack mounting holes, drilled through the full ear thickness. The +2
        // is a boolean overshoot so the hole cuts cleanly out of both faces.
        for (z = mount_hole_positions(units, screw_holes))
            translate([MOUNT_HOLE_X, -1, z])
                rotate([-90, 0, 0])
                cylinder(h = MOUNT_HOLE_DEPTH + 2, d = MOUNT_HOLE_D);
    }
}

// Single source of truth for both hands.
module half_rack_module(units, offset, depth, width, rack_side) {
    if (rack_side == "right") {
        mirror([1, 0, 0]) module_body(units, offset, depth, width);
    } else {
        module_body(units, offset, depth, width);
    }
}

half_rack_module(module_units, tray_offset, tray_depth, tray_width, side);

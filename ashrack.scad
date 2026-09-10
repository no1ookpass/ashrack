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

// Tray width (mm)
tray_width = 150; // [10:1:220]

// Rack side this module mounts to
side = "left"; // [left, right]

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
FLANGE_WIDTH = 15;
FLANGE_DEPTH = 9;

// Rack mounting hole geometry.
MOUNT_HOLE_D = 5.2;
MOUNT_HOLE_X = (RACK_WIDTH - RACK_MOUNT_HOLE_SPACING) / 2;
MOUNT_HOLE_TOP = 15.875;
MOUNT_HOLE_BOTTOM = RACK_UNIT - 15.875;

// Tray fit.
TRAY_EDGE_MARGIN = 5;
TRAY_FIT_CLEARANCE = 0.4;

// A half rack module occupies half of the clear rack opening.
MODULE_WIDTH = RACK_CLEAR_WIDTH / 2;

// Panel height for a given number of rack units.
function module_height(units) = units * RACK_UNIT - PANEL_HEIGHT_CLEARANCE;

// Standard mounting hole heights for a panel of the given rack unit count.
function mount_hole_positions(units) =
    let (h = module_height(units))
    [ for (u = [0 : units - 1])
        for (z = [MOUNT_HOLE_TOP, MOUNT_HOLE_BOTTOM])
            let (zz = u * RACK_UNIT + z)
            if (zz > MOUNT_HOLE_D && zz < h - MOUNT_HOLE_D)
                zz ];

// One handed module, built with its mounting edge on X = 0.
module module_body(units, offset, depth, width) {
    h = module_height(units);
    opening_h = h - 2 * TRAY_EDGE_MARGIN;
    opening_w = width + 2 * TRAY_FIT_CLEARANCE;

    assert(offset >= FLANGE_WIDTH + RAIL_THICKNESS,
        "tray_offset is too small: the tray has to clear the rack mounting flange");
    assert(offset + opening_w + RAIL_THICKNESS <= MODULE_WIDTH,
        "tray_offset + tray_width is too large to fit a half rack module");
    assert(width > 0 && depth > 0,
        "tray_width and tray_depth must both be greater than zero");
    assert(opening_h > 0, "module_units is too small to fit a tray");

    difference() {
        union() {
            // Front panel.
            cube([MODULE_WIDTH, PANEL_THICKNESS, h]);

            // Rack mounting flange, behind the panel on the mounting edge.
            translate([0, PANEL_THICKNESS, 0])
                cube([FLANGE_WIDTH, FLANGE_DEPTH, h]);

            // Tray support sleeve behind the opening.
            translate([
                offset - RAIL_THICKNESS,
                PANEL_THICKNESS,
                TRAY_EDGE_MARGIN - RAIL_THICKNESS
            ])
                cube([opening_w + 2 * RAIL_THICKNESS, depth, opening_h + 2 * RAIL_THICKNESS]);
        }

        // Tray opening through the front panel.
        translate([offset, -1, TRAY_EDGE_MARGIN])
            cube([opening_w, PANEL_THICKNESS + 2, opening_h]);

        // Tray channel. Open at the front and at the back so the tray slides
        // through the panel and is stopped by its own front plate.
        translate([offset, PANEL_THICKNESS - 1, TRAY_EDGE_MARGIN])
            cube([opening_w, depth + 2, opening_h]);

        // Rack mounting holes.
        for (z = mount_hole_positions(units))
            translate([MOUNT_HOLE_X, PANEL_THICKNESS - 1, z])
                rotate([-90, 0, 0])
                cylinder(h = FLANGE_DEPTH + 2, d = MOUNT_HOLE_D);
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

// SPDX-License-Identifier: MIT
// Copyright (c) 2026 no1ookpass
//
// Ashrack common - shared rack standards, fit dimensions and styling.
//
// Included by the front panel (ashrack-panel.scad) and by the tray that slides
// into it (ashrack-tray.scad), so the two can never drift apart: everything that
// decides whether a tray fits its module lives here.

$fn = 64;

// Standard 19" EIA rack dimensions - fixed, do not customise.
RACK_UNIT = 44.45;
RACK_WIDTH = 482.6;
RACK_MOUNT_HOLE_SPACING = 465.1;

// Material.
PANEL_THICKNESS = 3;
PANEL_HEIGHT_CLEARANCE = 0.8;
RAIL_THICKNESS = 3;
WALL_THICKNESS = 3;

// Panel height for a given number of rack units.
function module_height(units) = units * RACK_UNIT - PANEL_HEIGHT_CLEARANCE;

// The tray channel as the module frames it. A tray has to fit inside these.
TRAY_EDGE_MARGIN = 5;
TRAY_FIT_CLEARANCE = 0.4;
function opening_width(tray_width) = tray_width + 2 * TRAY_FIT_CLEARANCE;
function opening_height(units) = module_height(units) - 2 * TRAY_EDGE_MARGIN;

// Below this tray width the channel is too narrow to frame - the join fillet
// alone would fill it in - so the module prints as a blank panel with no slot.
// Keeps the width slider usable all the way down to 0.
MIN_TRAY_WIDTH = 10;

// Criss-cross styling, shared so a tray's walls match the frame holding it.
FRAME_PITCH = 70;
FRAME_BAR_SPREAD = 2;
JOIN_FILLET = 2;

// Closing pass: fills concave joins with a radius so crossings read as ")("
// rather than "><". Wrap it around a flat panel drawn in 2D.
module fillet_joins(radius = JOIN_FILLET) {
    offset(r = -radius, $fn = 32)
        offset(r = radius, $fn = 32)
            children();
}

// A panel drawn flat: edge rails with criss-cross bars braced between them and
// the joins filleted. u runs along the panel, v across it, and brace_span is the
// clear distance the bars span (use the full width to brace wall to wall).
module braced_panel(u_len, v_len, brace_span) {
    r = RAIL_THICKNESS;
    cells = max(1, round(u_len / FRAME_PITCH));
    cell = u_len / cells;
    bar_length = sqrt(cell * cell + brace_span * brace_span) + r;
    angle = atan2(brace_span, cell);

    // Trimmed to the outline so the scooped joins and the bar overshoot cannot
    // poke outside the panel.
    intersection() {
        fillet_joins()
            union() {
                // Edge rails, running the full length.
                for (v = [1, -1])
                    translate([0, v * (v_len - r) / 2])
                        square([u_len, r], center = true);

                // Criss-cross bars, braced across the panel.
                for (i = [0 : cells - 1])
                    for (side = [1, -1])
                        translate([cell * (i + 0.5) - u_len / 2, 0])
                            rotate(side * angle)
                                square([bar_length, FRAME_BAR_SPREAD * r], center = true);
            }

        square([u_len, v_len], center = true);
    }
}

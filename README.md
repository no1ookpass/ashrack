# Ashrack

An open source, modular half-rack system for 19" racks. Every module is half a
rack wide and slides into the rack from the front, and each one holds a tray that
slides into it, so the tray can be built to suit whatever goes inside.

## Files

| File | What it is |
|---|---|
| `ashrack.scad` | The front module: panel, mounting ear with the rack screw holes, the skeleton frame that holds a tray, and the joiner tabs |
| `tray.scad` | The tray that slides into a module: front face with cut-outs, floor with PCB mounts, styled walls, and an optional removable top |
| `ashrack_common.scad` | Shared rack standards, material and fit dimensions. Included by both parts, so a tray cannot drift out of fit with its module |

Open either part in OpenSCAD and use the Customizer panel; everything you can
change is listed there. The two parts are separate files, but they include the
same dimension file, so build them with matching `module_units`, `tray_width`
and `tray_depth`.

## How the two halves work

A module is half a 19" rack (241.3 mm), so two of them sit side by side and meet
flush in the middle. Both hands come from one model: set `side` to `left` or
`right` and the body is mirrored with a transform, so there is no second file.

At the non-mounting edge each module has a pair of joiner tabs. The right hand's
pair sits one thickness higher, so the two interleave into a four tab stack that
a single vertical bolt passes through, tying the halves together.

## Module inputs (`ashrack.scad`)

| Input | Meaning | Default |
|---|---|---|
| `module_units` | Height in rack units | 2 |
| `tray_offset` | How far the tray slot sits from the mounting edge | 20 mm |
| `tray_depth` | How deep a tray the slot takes | 150 mm |
| `tray_width` | Tray width. **0 prints a blank panel**, with no slot at all | 150 mm |
| `side` | Which hand to build | left |
| `ear_thickness` | Mounting ear thickness, as a multiple of the panel | 5 |
| `screw_holes` | Rack screws per unit: 1 centre, 2 outer pair, 3 all three | 3 |

Rack screw holes follow EIA-310: 6.35, 22.225 and 38.1 mm above each unit's
lower edge, so the outer holes sit near the panel edges.

## Tray inputs (`tray.scad`)

| Input | Meaning | Default |
|---|---|---|
| `module_units`, `tray_width`, `tray_depth` | Must match the module it goes in | 2, 150, 150 |
| `side_style`, `back_style`, `top_style` | `solid`, `slits` or `skeleton` for each wall | skeleton |
| `top_removable` | Build the top in, or print it as its own part | false |
| `part` | Which piece to build: `body` or `top` | body |
| `handle_sides` | `none`, `rail`, `centre` or `both` | none |
| `handle_type` | `loop` (half donut pull) or `knob` | loop |

Handles are named from the module's mounting edge: `rail` is the edge that
screws to the rack, `centre` faces the middle of the rack. Left and right flip
with the hand, so they are no good as names.

### Two lists you edit in the file

The Customizer cannot take a list of shapes: it only accepts flat vectors of up
to four numbers. So the front cut-outs and the floor mounts live in the file,
where they can be any length. Both are commented in place.

```scad
// ["rect", x, z, width, height]  or  ["circle", x, z, diameter, 0]
// (x, z) is the centre, in mm from the bottom left of the front face.
front_cutouts = [
    ["rect",   52, 40, 25, 21],   // ethernet jack
    ["rect",   82, 40, 25, 21],   // ethernet jack
    ["circle", 105, 40,  8,  0],  // LED
];

// [x, y], then height, boss diameter and screw as you need them
pcb_mounts = [[12, 12], [138, 12], [12, 60, 10], [138, 60, 10]];
```

Keep cut-outs clear of the handles: each handle takes roughly `HANDLE_INSET`
+/- 15 mm from its edge, and there is no guard against the two colliding.

## Examples

Everything below is these files with the settings noted. The two scripts in
`examples/` show how the parts go together.

### Module

| | |
|---|---|
| ![2U module, left hand](examples/module-left.png) | ![2U module, right hand](examples/module-right.png) |
| **Left hand**, the default: mounting ear with the rack screw holes, skeleton tray frame behind the panel | **Right hand**, `side = "right"`. The same model mirrored, so there is no second file |
| ![Blank panel](examples/module-blank.png) | ![4U module, one hole per unit](examples/module-4u.png) |
| `tray_width = 0`: a **blank panel**, no slot and no frame at all | `module_units = 4` with `screw_holes = 1`: one centre hole per unit |

![Two halves joined](examples/module-pair.png)

*Two halves butted at the centre of the rack. The panels meet flush, and the
joiner tabs interleave into one stack for a single vertical bolt — see
`examples/module-pair.scad`.*

### Tray

| | |
|---|---|
| ![Skeleton tray](examples/tray-skeleton.png) | ![Tray with mixed wall styles](examples/tray-styles.png) |
| The default: skeleton sides, back and top | `side_style = "solid"` with `back_style = "slits"`: each wall is chosen separately |
| ![Loop handles](examples/tray-handle-loop.png) | ![Knob handles](examples/tray-handle-knob.png) |
| `handle_sides = "both"`, `handle_type = "loop"`: half donut pulls | The same sides with `handle_type = "knob"` |
| ![Body for a removable top](examples/tray-no-top.png) | ![The removable top on its own](examples/tray-top.png) |
| `top_removable = true`: the body, walls stopping short with screw bosses in the corners | `part = "top"`: the top prints as its own part, with countersunk screw holes |

![Tray with cut-outs, mounts and handles](examples/tray-fitted.png)

*Everything at once: two ethernet openings and an LED in the front face, four PCB
standoffs on the floor with the back pair taller to clear a connector, and
handles on both sides.*

### Together

![A tray slid into its module](examples/assembly.png)

*`examples/assembly.scad`: the module, with the tray placed by `tray_position()`
so it runs exactly where it slides.*

## Rendering

```
openscad -o module.stl ashrack.scad
openscad -o tray.stl   tray.scad
openscad -o top.stl    -D 'top_removable=true' -D 'part="top"' tray.scad
```

To check a tray in its module, place it with the helper the tray provides:

```scad
use <ashrack.scad>
use <tray.scad>
half_rack_module(2, 20, 150, 150, "left");
translate(tray_position(20)) tray();
```

The tray is built to the module's opening less a `TRAY_SLIDE_CLEARANCE`, so that
placement leaves 0.25 mm per side. If your printer needs more room, that one
constant is the knob.

## Printing

- **Module**: print it panel face down. The frame rises off the bed and needs no
  support.
- **Tray body**: either orientation is a compromise. Floor down is the natural
  box orientation with a solid base, but leaves the handles as horizontal
  overhangs; front face down prints the handles and cut-outs cleanly, at the cost
  of the floor and walls becoming tall thin fins. The knob is the more forgiving
  handle either way, and a loop printed front-down has a bridge at the top of its
  arch.
- **Removable top**: print it flat, countersinks up.

## Hardware

| Where | Fastener |
|---|---|
| Rack mounting | M5 (5.2 mm clearance holes) |
| Joiner tabs | One M5 bolt through the 12 mm tab stack, with washers — the tabs are plain clearance holes, so any long enough bolt works |
| Removable top | Four M3 self-tapping screws into printed bosses, heads countersunk flush |
| PCB mounts | M3 self-tapping into the standoffs, pilot holes are blind |

## Notes

- The lists are the only place you have to write code. If you extend them, note
  that OpenSCAD 2021.01's `for` loop needs `=`, not `in`.
- Every cut-out and mount is bounds checked: an out of range entry fails the
  build with a message rather than printing a broken part.

# Ashrack

An open source, modular half-rack system for 19" racks. Every module is half a
rack wide and slides into the rack from the front, and each one holds a tray that
slides into it, so the tray can be built to suit whatever goes inside.

## Files

| File | What it is |
|---|---|
| `ashrack-panel.scad` | The front module: panel, mounting ear with the rack screw holes, the skeleton frame that holds a tray, and the joiner tabs |
| `ashrack-tray.scad` | The tray that slides into a module: front face with cut-outs, floor with PCB mounts, styled walls, and an optional removable top |
| `ashrack-common.scad` | Shared rack standards, material and fit dimensions. Included by both parts, so a tray cannot drift out of fit with its module |

Open either part in OpenSCAD and use the Customizer panel; everything you can
change is listed there. The two parts are separate files, but they include the
same dimension file, so build them with matching `module_units`, `tray_width`
and `tray_depth`. Every file is named `ashrack-`, so the project's parts sort
together in a listing and can't be mistaken for a `tray.scad` from elsewhere.

## How the two halves work

A module is half a 19" rack (241.3 mm), so two of them sit side by side and meet
flush in the middle. Both hands come from one model: set `side` to `left` or
`right` and the body is mirrored with a transform, so there is no second file.

At the non-mounting edge each module has a pair of joiner tabs. The right hand's
pair sits one thickness higher, so the two interleave into a four tab stack that
a single vertical bolt passes through, tying the halves together.

Because a module is really just a slot, the two halves need not match. Each takes
its own `tray_width` and `tray_depth`, so a wide deep tray and a narrow shallow
one can sit side by side in the same rack space — the paired examples below do
exactly that.

## Module inputs (`ashrack-panel.scad`)

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

## Tray inputs (`ashrack-tray.scad`)

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

`tray()` also takes those two lists and the two handle settings as arguments, `cutouts`, `mounts`,
`handle_sides` and `handle_type`, so a build script can hand over its own without touching this
file's defaults:

```scad
tray(units = 1, width = 180, depth = 150, cutouts = my_cutouts, mounts = my_mounts,
     handle_sides = "rail", handle_type = "loop");
```

That is how a downstream project keeps its build data in its own repo: define the lists there, hand
them over, and the library stays free of any one build's numbers.

Size the keep-out to the handle you picked: a knob is ~16 mm across, a loop spans
`HANDLE_LOOP_OPENING` plus its feet (~33 mm) and stands further off the face, so the band a
cut-out has to avoid is wider with a loop than the `+/- 15 mm` above suggests.

## Examples

Everything below is these files with the settings noted. The three scripts in
`examples/` show how the parts go together: one for a pair of modules, one for a
module with its tray, and one for both halves with their trays.

### Module

| | |
|---|---|
| ![2U module, left hand](examples/module-left.png) | ![2U module, right hand](examples/module-right.png) |
| **Left hand**, the default: mounting ear with the rack screw holes, skeleton tray frame behind the panel | **Right hand**, `side = "right"`. The same model mirrored, so there is no second file |
| ![Blank panel](examples/module-blank.png) | ![4U module, one hole per unit](examples/module-4u.png) |
| `tray_width = 0`: a **blank panel**, no slot and no frame at all | `module_units = 4` with `screw_holes = 1`: one centre hole per unit |
| ![1U module](examples/module-1u.png) | ![Two 1U halves joined](examples/module-pair-1u.png) |
| `module_units = 1`: a single unit tall | The pair again at 1U, still with two different slot sizes |

![Two halves joined](examples/module-pair.png)

*Two halves butted at the centre of the rack. The panels meet flush, and the
joiner tabs interleave into one stack for a single vertical bolt — see
`examples/module-pair.scad`.*

![The same two halves from behind](examples/module-pair-back.png)

*The same pair from behind, where you can see each half is its own slot: 150 x
150 mm on the rail side, 110 x 80 mm on the centre side. Nothing ties the two
sizes together — `examples/module-pair-1u-back.png` shows the same pair at 1U, and
`examples/pair-assembly-back.png` the same idea with trays in place.*

### Tray

| | |
|---|---|
| ![Skeleton tray](examples/tray-skeleton.png) | ![Tray with mixed wall styles](examples/tray-styles.png) |
| The default: skeleton sides, back and top | `side_style = "solid"` with `back_style = "slits"`: each wall is chosen separately |
| ![Loop handles](examples/tray-handle-loop.png) | ![Knob handles](examples/tray-handle-knob.png) |
| `handle_sides = "both"`, `handle_type = "loop"`: half donut pulls | The same sides with `handle_type = "knob"` |
| ![Body for a removable top](examples/tray-no-top.png) | ![The removable top on its own](examples/tray-top.png) |
| `top_removable = true`: the body, walls stopping short with screw bosses in the corners | `part = "top"`: the top prints as its own part, with countersunk screw holes |
| ![1U tray](examples/tray-1u.png) | ![1U tray, every wall slitted](examples/tray-1u-vented.png) |
| `module_units = 1`: a shallow tray, but `tray_depth` still sets how far back it reaches | All three wall styles set to `"slits"` |
| ![1U patch panel tray](examples/tray-1u-patch.png) | ![1U tray with cable slots](examples/tray-1u-slots.png) |
| A patch panel front: four ethernet openings and an LED, with solid walls and PCB mounts behind | Three stadium openings, from the optional sixth cut-out value that rounds a rectangle's corners |

![Tray with cut-outs, mounts and handles](examples/tray-fitted.png)

*Everything at once: two ethernet openings and an LED in the front face, four PCB
standoffs on the floor with the back pair taller to clear a connector, and
handles on both sides.*

### Together

![A tray slid into its module](examples/assembly.png)

*`examples/assembly.scad`: the module, with the tray placed by `tray_position()`
so it runs exactly where it slides.*

![Both halves with their own trays](examples/pair-assembly.png)

*Both halves at once, each with a tray built to its own slot: 150 x 150 mm on the
left, 110 x 80 mm on the right. The right half and its tray are the same models
mirrored, so the tray runs into the slot from the other side.*

![The same pair of assemblies from behind](examples/pair-assembly-back.png)

*From behind: the two trays side by side, each sized to the slot holding it.*

![A 1U module with its tray](examples/assembly-1u.png)

*The same assembly at `module_units = 1`, module and tray together.*

## Rendering

```
openscad -o module.stl ashrack-panel.scad
openscad -o tray.stl   ashrack-tray.scad
openscad -o top.stl    -D 'top_removable=true' -D 'part="top"' ashrack-tray.scad
```

To check a tray in its module, place it with the helper the tray provides:

```scad
use <ashrack-panel.scad>
use <ashrack-tray.scad>
half_rack_module(2, 20, 150, 150, "left");
translate(tray_position(20)) tray();
```

The tray is built to the module's opening less a `TRAY_SLIDE_CLEARANCE`, so that
placement leaves 0.25 mm per side. If your printer needs more room, that one
constant is the knob.

`tray()` also takes the size it should be built to, so one script can make any
number of differently sized trays:

```scad
// tray(units, width, depth) — the same numbers the module was built with
tray();                            // the Customizer's tray, 2U x 150 x 150
tray(units = 1, width = 110);      // 1U, 110 wide, 150 deep
tray(width = 110, depth = 80);     // 2U, 110 wide, 80 deep
```

The same goes for `removable_top()`, so a body and its own top always match.

To see the back of a part, render it from the other side by turning the camera
to the opposite azimuth:

```
openscad -o back.png --camera=0,0,0,58,0,208,0 --projection=p examples/pair-assembly.scad
```

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

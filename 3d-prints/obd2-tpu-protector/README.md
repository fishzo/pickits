# OBD2 scan-tool plug TPU bumper sleeve

A TPU sleeve that stretches over the **outside** of the black OBD2 (J1962) plug shroud on a scan tool
(made for the GM MDI 2 cable). The **front face is left fully open**, so the pins and the mating opening
aren't covered and the plug still slides over the vehicle port.

![iso](preview_iso.png) ![front](preview_front.png)

## Files
- `obd2_tpu_protector.scad`: the parametric source (OpenSCAD, Customizer-friendly)
- `obd2_tpu_protector.stl`: ready to print with the defaults

## Dimensions
Profile (from a traced outline): a trapezoid with a straight wide top edge and sides that taper in along
their whole height. A raised key tab sits in the middle of the narrow bottom edge, and the sleeve wraps around it.

| | Value |
|---|---|
| Width, top edge (measured) | 41.93 mm |
| Height incl. key tab (measured) | 19.60 mm |
| Shroud height above grey body (measured) | 14.7 mm |
| Bottom edge width (from trace) | ~33.3 mm |
| Key tab (from trace) | ~12 mm wide × 2.4 mm |
| Fit | 0.20 mm/side interference (stretch fit) |
| Sleeve length | 14.5 mm (sits against the grey body, stays just behind the front face) |
| Main wall | 2.0 mm |
| Front bumper band | 3.0 mm wall × 4 mm long, chamfered edge |

If the trapezoid angle or tab don't line up, adjust `bottom_w`, `tab_w`, `tab_h` and the corner radii.

## Printing
- TPU 95A, 0.4 mm nozzle, 0.2 mm layers, 20–30 mm/s, retraction low or off
- 4 walls (the 2 mm wall then prints solid), no supports
- The STL is already oriented front-end down; print it that way

## Tuning
- Too tight or too loose: change `fit_per_side` (-0.1 is looser, -0.3 is tighter)
- Port sits in a tight dash recess: reduce `front_band_w` to 2 (or equal to `wall`)

## Fusion 360
`fusion360/OBD2_TPU_Protector/` is a Fusion 360 script that builds the same sleeve as a native parametric model
(sketches → extrudes → chamfers, so you can edit any of it in the timeline).

1. Copy the whole `OBD2_TPU_Protector` folder to your computer.
2. In Fusion: **Utilities → Add-Ins → Scripts and Add-Ins → Scripts tab → `+`**, pick that folder, then **Run**.
3. To change sizes, edit the values at the top of `OBD2_TPU_Protector.py` (mm) and run it again, or
   edit the sketches/extrudes directly.
4. Export: right-click the body → **Save As Mesh** (STL/3MF).

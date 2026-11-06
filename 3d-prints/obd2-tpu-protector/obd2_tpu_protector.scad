// =====================================================================
//  OBD2 (J1962) scan-tool plug bumper sleeve  -  FDM / TPU
// ---------------------------------------------------------------------
//  Slips over the OUTSIDE of the tool's black OBD2 plug shroud.
//  Front face is left completely open (pins + mating opening are not
//  covered), so the plug still slides over the vehicle port normally.
//
//  Measured (calipers): shroud width 41.93 mm, height 19.60 mm.
//  Everything else below is an estimate - check it with calipers and
//  tweak the parameters before printing.
//
//  Print: TPU 95A, 0.4 nozzle, 0.2 layer, 3-4 walls (wall is solid),
//         20-30 mm/s, NO supports. Stand it on the FRONT end (the
//         chamfered bumper end) on the bed - exported STL is already
//         oriented that way.
// =====================================================================

/* [Measured plug shroud] */
plug_w        = 41.93;  // overall shroud width (top edge, widest)
plug_h        = 19.60;  // overall shroud height
// Lower corners of the D/trapezoid profile are cut at an angle.
chamfer_x     = 5.0;    // how far the angled lower corner cuts in, horizontally
chamfer_y     = 6.0;    // how far up the side the angled corner goes
corner_r      = 1.5;    // rounding on all profile corners

/* [Fit] */
// Negative = interference (sleeve is smaller than plug, TPU stretches on).
fit_per_side  = -0.20;

/* [Sleeve] */
sleeve_len    = 16;     // how far back from the front face the sleeve covers
wall          = 2.0;    // main wall thickness
front_band_len= 5;      // length of thicker bumper band at the front edge
front_band_w  = 3.0;    // wall thickness of the front bumper band
band_taper    = 2;      // length of taper from bumper band down to main wall
front_proud   = 0.0;    // >0 = sleeve sticks out past the plug face by this much
                        // (extra edge protection, but only if your vehicle
                        //  port isn't flush in a panel). 0 = flush.
edge_chamfer  = 0.8;    // softens the outside front edge (lead-in for tight bezels)

/* [Latch / key tab relief] */
// Small bump at the bottom-center of the shroud - give it a channel.
tab_relief    = true;
tab_w         = 8.0;
tab_depth     = 1.2;    // depth cut into inner wall (keep < wall)

/* [Grip ribs on the sides (optional)] */
grip_ribs     = true;
rib_count     = 4;
rib_w         = 1.2;
rib_h         = 0.8;

$fn = 64;
eps = 0.01;

// ---------------------------------------------------------------------
// 2D profile of the plug shroud, centred on origin, Y up = top of plug.
// Convex, so hull() can be used freely on it.
module plug_profile(grow = 0) {
    w = plug_w + 2*grow;
    h = plug_h + 2*grow;
    r = max(0.01, corner_r + grow);
    offset(r = r) offset(delta = -corner_r)   // round corners, keep size
        polygon([
            [-w/2,  h/2],
            [ w/2,  h/2],
            [ w/2, -h/2 + chamfer_y],
            [ w/2 - chamfer_x, -h/2],
            [-w/2 + chamfer_x, -h/2],
            [-w/2, -h/2 + chamfer_y],
        ]);
}

module inner_2d() { plug_profile(fit_per_side); }

module outer_2d(t) { offset(r = t) inner_2d(); }

// Thin slab of a profile at height z (for hull-based transitions)
module slab(z, t) { translate([0,0,z]) linear_extrude(eps) outer_2d(t); }

// Outer solid of the sleeve. z = 0 is the front edge (bed side).
module outer_body() {
    L  = sleeve_len + front_proud;
    fb = front_band_len + front_proud;
    union() {
        // front bumper band with chamfered leading edge
        hull() {
            slab(0, front_band_w - edge_chamfer);
            slab(edge_chamfer, front_band_w);
            slab(fb, front_band_w);
        }
        // taper band -> main wall
        hull() {
            slab(fb, front_band_w);
            slab(fb + band_taper, wall);
        }
        // main wall (rear edge gets a small chamfer too)
        hull() {
            slab(fb + band_taper, wall);
            slab(L - 0.6, wall);
            slab(L - eps, wall - 0.6);
        }
    }
}

module grip() {
    if (grip_ribs) {
        z0 = front_band_len + front_proud + band_taper + 1;
        z1 = sleeve_len + front_proud - 1.5;
        for (side = [-1, 1], i = [0 : rib_count - 1]) {
            // ribs run lengthwise on the left/right faces
            y = (plug_h/2 - 2) - i * ((plug_h - chamfer_y - 3) / max(1, rib_count - 1));
            translate([side * (plug_w/2 + fit_per_side + wall + rib_h/2 - 0.2), y, z0])
                hull() {
                    translate([0,0,0])   cube([rib_h + 0.4, rib_w, eps], center = true);
                    translate([0,0,z1-z0]) cube([rib_h + 0.4, rib_w, eps], center = true);
                }
        }
    }
}

module sleeve() {
    difference() {
        union() { outer_body(); grip(); }
        // through bore
        translate([0,0,-1]) linear_extrude(sleeve_len + front_proud + 2) inner_2d();
        // latch / key tab relief channel at bottom centre
        if (tab_relief)
            translate([-tab_w/2, -plug_h/2 - fit_per_side - tab_depth, -1])
                cube([tab_w, tab_depth + 1, sleeve_len + front_proud + 2]);
    }
}

sleeve();

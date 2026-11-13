// =====================================================================
//  OBD2 (J1962) scan-tool plug bumper sleeve  -  FDM / TPU
// ---------------------------------------------------------------------
//  Slips over the OUTSIDE of the tool's black OBD2 plug shroud, from
//  the grey body up to the front face. Front face is left fully open.
//
//  Profile (traced): trapezoid - straight wide top edge, both sides
//  taper inward the whole height, narrow bottom edge with a raised key
//  tab in the middle.
//
//  Measured: width 41.93 mm, height 19.60 mm (incl. key tab),
//            shroud stands 14.7 mm above the grey body.
//  Estimated from the trace: bottom width, tab width/height, radii.
//
//  Print: TPU 95A, 0.2 layer, 4 walls, 20-30 mm/s, NO supports.
//         STL is oriented front-edge down on the bed.
// =====================================================================

/* [Measured plug shroud] */
plug_w        = 41.93;  // width of the wide (top) edge
plug_h        = 19.60;  // total height INCLUDING the key tab
shroud_len    = 14.7;   // how far the black shroud stands above the grey body

/* [Profile shape (from trace)] */
bottom_w      = 33.3;   // width of the narrow (bottom) edge, without radii
tab_w         = 12.0;   // key tab width at its base
tab_h         = 2.4;    // how far the key tab sticks out below the bottom edge
tab_slope     = 1.0;    // tab ends are slightly angled (horizontal run)
top_r         = 3.0;    // corner radius, wide-edge corners
bottom_r      = 1.5;    // corner radius, narrow-edge corners
tab_r         = 0.6;    // radius on the tab corners

/* [Fit] */
// Negative = interference (sleeve smaller than plug, TPU stretches on).
fit_per_side  = -0.20;

/* [Sleeve] */
// Slightly shorter than shroud_len so the front never sits proud.
sleeve_len    = shroud_len - 0.2;
wall          = 2.0;    // main wall thickness
front_band_len= 4;      // thicker bumper band at the front edge
front_band_w  = 3.0;    // wall thickness of the bumper band
band_taper    = 1.6;    // taper from bumper band down to main wall
edge_chamfer  = 0.8;    // softens the outside front edge
rear_chamfer  = 0.6;    // softens the outside rear edge
step          = 0.2;    // z resolution of chamfers/tapers

$fn = 64;

// ---------------------------------------------------------------------
// 2D plug profile. Origin = centre of the body (tab excluded), Y up.
body_h = plug_h - tab_h;

// rounded profile: convex corners via offset in/out, concave tab roots
// filleted by the outward-then-inward offset.
module plug_profile(grow = 0) {
    offset(delta = grow)
    offset(r = -tab_r) offset(r = tab_r)          // fillet tab roots
    union() {
        // body with different top/bottom radii
        hull() {
            for (s = [-1, 1]) {
                translate([s * (plug_w/2 - top_r), body_h/2 - top_r])
                    circle(r = top_r);
                translate([s * (bottom_w/2 - 0.6 * bottom_r),
                           -body_h/2 + bottom_r])
                    circle(r = bottom_r);
            }
        }
        offset(r = tab_r) offset(delta = -tab_r) raw_tab();
    }
}

module raw_tab() {
    yb = -body_h/2;
    polygon([[-tab_w/2, yb + 1], [tab_w/2, yb + 1],
             [tab_w/2 - tab_slope, yb - tab_h],
             [-tab_w/2 + tab_slope, yb - tab_h]]);
}

module inner_2d() { plug_profile(fit_per_side); }

// wall thickness as a function of z (z = 0 front edge on the bed)
function wall_at(z) =
    z < edge_chamfer ? (front_band_w - edge_chamfer) + z :
    z < front_band_len ? front_band_w :
    z < front_band_len + band_taper ?
        front_band_w - (front_band_w - wall) * (z - front_band_len) / band_taper :
    z > sleeve_len - rear_chamfer ? wall - (z - (sleeve_len - rear_chamfer)) :
    wall;

// Wall-thickness steps only where the thickness changes; constant
// sections are extruded in one piece (keeps render time short).
module band(z0, z1) {
    translate([0, 0, z0]) linear_extrude(z1 - z0 + 0.001)
        offset(r = wall_at((z0 + z1) / 2)) inner_2d();
}

module ramp(z0, z1) {
    n = max(1, ceil((z1 - z0) / step));
    for (i = [0 : n - 1]) band(z0 + i * (z1 - z0) / n, z0 + (i + 1) * (z1 - z0) / n);
}

module sleeve() {
    t0 = front_band_len;
    t1 = front_band_len + band_taper;
    r0 = sleeve_len - rear_chamfer;
    difference() {
        union() {
            ramp(0, edge_chamfer);
            band(edge_chamfer, t0);
            ramp(t0, t1);
            band(t1, r0);
            ramp(r0, sleeve_len);
        }
        translate([0, 0, -1]) linear_extrude(sleeve_len + 2) inner_2d();
    }
}

sleeve();

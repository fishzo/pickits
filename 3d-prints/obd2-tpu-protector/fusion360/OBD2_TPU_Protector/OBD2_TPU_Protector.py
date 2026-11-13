"""
OBD2 (J1962) scan-tool plug TPU bumper sleeve - Fusion 360 script.

Run: Utilities > Add-Ins > Scripts and Add-Ins > (+) add this folder > Run.
Creates a new component with sketches, extrudes and chamfers you can edit.

Same geometry as ../../obd2_tpu_protector.scad. All values in mm.
Front edge of the sleeve is at Z = 0, the end that meets the grey body is at Z = SLEEVE_LEN.
"""
import math
import traceback

import adsk.core
import adsk.fusion

# ---------------- Measured plug shroud ----------------
PLUG_W = 41.93        # wide (top) edge width
PLUG_H = 19.60        # total height including the key tab
SHROUD_LEN = 14.7     # shroud height above the grey body

# ---------------- Profile shape (from trace) ----------------
BOTTOM_W = 33.3       # narrow (bottom) edge width
TAB_W = 12.0          # key tab width at its base
TAB_H = 2.4           # key tab protrusion below the bottom edge
TAB_SLOPE = 1.0       # horizontal run of the angled tab ends
TOP_R = 3.0           # radius, wide-edge corners
BOTTOM_R = 1.5        # radius, narrow-edge corners
TAB_R = 0.6           # radius, tab corners (inside and outside)

# ---------------- Fit / sleeve ----------------
FIT_PER_SIDE = -0.20  # negative = interference (TPU stretches on)
SLEEVE_LEN = SHROUD_LEN - 0.2
WALL = 2.0
FRONT_BAND_LEN = 4.0
FRONT_BAND_W = 3.0
EDGE_CHAMFER = 0.8    # outside front edge
REAR_CHAMFER = 0.6    # outside rear edge


def plug_polygon():
    """Sharp-cornered plug outline, CCW, with per-vertex (radius, convex)."""
    body_h = PLUG_H - TAB_H
    yt, yb = body_h / 2.0, -body_h / 2.0
    pts = [
        ((-PLUG_W / 2, yt), TOP_R, True),
        ((-BOTTOM_W / 2, yb), BOTTOM_R, True),
        ((-TAB_W / 2, yb), TAB_R, False),
        ((-TAB_W / 2 + TAB_SLOPE, yb - TAB_H), TAB_R, True),
        ((TAB_W / 2 - TAB_SLOPE, yb - TAB_H), TAB_R, True),
        ((TAB_W / 2, yb), TAB_R, False),
        ((BOTTOM_W / 2, yb), BOTTOM_R, True),
        ((PLUG_W / 2, yt), TOP_R, True),
    ]
    return pts


def offset_polygon(pts, d):
    """Offset a CCW polygon outward by d (mm). Returns new vertex list with radii adjusted."""
    n = len(pts)
    lines = []
    for i in range(n):
        (x0, y0), (x1, y1) = pts[i][0], pts[(i + 1) % n][0]
        dx, dy = x1 - x0, y1 - y0
        ln = math.hypot(dx, dy)
        nx, ny = dy / ln, -dx / ln            # outward normal for CCW
        lines.append(((x0 + nx * d, y0 + ny * d), (dx, dy)))
    out = []
    for i in range(n):
        (p, r), (q, s) = lines[i - 1], lines[i]
        # intersect p + t*r with q + u*s
        den = r[0] * s[1] - r[1] * s[0]
        t = ((q[0] - p[0]) * s[1] - (q[1] - p[1]) * s[0]) / den
        x, y = p[0] + t * r[0], p[1] + t * r[1]
        rad, convex = pts[i][1], pts[i][2]
        rad = rad + d if convex else rad - d
        out.append(((x, y), max(rad, 0.0), convex))
    return out


def draw_profile(sketch, pts):
    """Closed polyline with filleted corners. Coordinates in mm (converted to cm)."""
    P = lambda x, y: adsk.core.Point3D.create(x / 10.0, y / 10.0, 0)
    sl = sketch.sketchCurves.sketchLines
    n = len(pts)
    sp = [P(*v[0]) for v in pts]
    lines = []
    for i in range(n):
        a = lines[-1].endSketchPoint if lines else sp[0]
        b = lines[0].startSketchPoint if i == n - 1 else sp[i + 1]
        lines.append(sl.addByTwoPoints(a, b))

    def near(line_pts, frac):
        (x0, y0), (x1, y1) = line_pts
        return P(x0 + (x1 - x0) * frac, y0 + (y1 - y0) * frac)

    arcs = sketch.sketchCurves.sketchArcs
    for i in range(n):
        rad = pts[i][1]
        if rad <= 0.01:
            continue
        v = pts[i][0]
        prev_v, next_v = pts[i - 1][0], pts[(i + 1) % n][0]
        arcs.addFillet(lines[i - 1], near((v, prev_v), 0.2),
                       lines[i], near((v, next_v), 0.2), rad / 10.0)


def make_sketch(comp, name, pts):
    sk = comp.sketches.add(comp.xYConstructionPlane)
    sk.name = name
    draw_profile(sk, pts)
    return sk


def outer_loop_edges(body, z_mm, normal_z):
    """Outer-loop edges of the planar face at height z (mm) facing normal_z."""
    edges = adsk.core.ObjectCollection.create()
    for face in body.faces:
        g = face.geometry
        if not isinstance(g, adsk.core.Plane):
            continue
        if abs(g.normal.z - normal_z) > 1e-6 and abs(g.normal.z + normal_z) > 1e-6:
            continue
        if abs(face.pointOnFace.z * 10.0 - z_mm) > 1e-3:
            continue
        for loop in face.loops:
            if loop.isOuter:
                for e in loop.edges:
                    edges.add(e)
    return edges


def chamfer(comp, edges, dist_mm, name):
    if edges.count == 0:
        return None
    feats = comp.features.chamferFeatures
    ci = feats.createInput2()
    ci.chamferEdgeSets.addEqualDistanceChamferEdgeSet(
        edges, adsk.core.ValueInput.createByReal(dist_mm / 10.0), True)
    f = feats.add(ci)
    f.name = name
    return f


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = adsk.fusion.Design.cast(app.activeProduct)
        if not design:
            ui.messageBox('Open or create a Fusion design first.')
            return
        design.designType = adsk.fusion.DesignTypes.ParametricDesignType

        root = design.rootComponent
        occ = root.occurrences.addNewComponent(adsk.core.Matrix3D.create())
        comp = occ.component
        comp.name = 'OBD2 TPU Protector'

        plug = plug_polygon()
        bore = offset_polygon(plug, FIT_PER_SIDE)
        outer = offset_polygon(plug, FIT_PER_SIDE + WALL)
        band = offset_polygon(plug, FIT_PER_SIDE + FRONT_BAND_W)

        ext = comp.features.extrudeFeatures
        NEW = adsk.fusion.FeatureOperations.NewBodyFeatureOperation
        JOIN = adsk.fusion.FeatureOperations.JoinFeatureOperation
        CUT = adsk.fusion.FeatureOperations.CutFeatureOperation
        cm = lambda mm: adsk.core.ValueInput.createByReal(mm / 10.0)

        sk_outer = make_sketch(comp, 'Outer wall', outer)
        e1 = ext.addSimple(sk_outer.profiles.item(0), cm(SLEEVE_LEN), NEW)
        e1.name = 'Sleeve'
        body = e1.bodies.item(0)
        body.name = 'OBD2 TPU Protector'

        sk_band = make_sketch(comp, 'Front bumper band', band)
        e2 = ext.addSimple(sk_band.profiles.item(0), cm(FRONT_BAND_LEN), JOIN)
        e2.name = 'Bumper band'

        sk_bore = make_sketch(comp, 'Bore (plug + fit)', bore)
        ei = ext.createInput(sk_bore.profiles.item(0), CUT)
        ei.setDistanceExtent(False, cm(SLEEVE_LEN + 1))
        ei.participantBodies = [body]
        e3 = ext.add(ei)
        e3.name = 'Bore'

        body = comp.bRepBodies.item(0)
        msgs = []
        for z, nz, d, nm in [
            (FRONT_BAND_LEN, 1, FRONT_BAND_W - WALL - 0.1, 'Band taper'),
            (0.0, -1, EDGE_CHAMFER, 'Front edge chamfer'),
            (SLEEVE_LEN, 1, REAR_CHAMFER, 'Rear edge chamfer'),
        ]:
            try:
                body = comp.bRepBodies.item(0)
                chamfer(comp, outer_loop_edges(body, z, nz), d, nm)
            except Exception:
                msgs.append(nm)

        note = ('\n\nCould not add: ' + ', '.join(msgs) +
                ' (add them by hand on the outer edges).') if msgs else ''
        ui.messageBox('OBD2 TPU Protector created.\n'
                      'Export: right-click the body > Save As Mesh (STL/3MF).\n'
                      'Print front edge (Z=0) down, no supports.' + note)
    except Exception:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

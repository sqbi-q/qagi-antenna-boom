// Yagi antenna boom model made by sqbi-q.
// Designed for flat element shape (3G-Aerial DL6WU calculator).

MODEL_VERSION = "0.1.1-Test";

include <./BOSL2/std.scad> // from local dir
//include <BOSL2/std.scad> // from library dir

use <./connector.scad>

/// Load fonts
use <./fonts/osifont-lgpl3fe.ttf>
use <./fonts/overpass-regular.otf>
///

// DL6WU Yagi functions
include <./dl6wu.scad>

$fn = 20;

/// -------- Configuration ----------

directorCount     = 2;
frequency         = 869.000; // MHz
drivenDiameter    = 6;       // mm
parasiticDiameter = 6;       // mm
wavelength = frequencyToWavelength(frequency);

elementParameters = [
    for (p = calculateAntenna(
        directorCount,
        wavelength,
        drivenDiameter,
        parasiticDiameter
    ))
    [ round(p[0]), round(p[1]) ]
];
_ElemParamLength   = 0;
_ElemParamPosition = 1;

BOOM_DIMENSIONS = [
// width,      thickness
   50,         10,
// dipole gap, dipole offset
   2,          20,
// hole diameter
   3.5,
// reflector position
   30,
// element width, element thickness
   10,            2,
];
boomDimensions = function (field) (
      ("width" == field)              ? BOOM_DIMENSIONS[0]
    : ("thickness" == field)          ? BOOM_DIMENSIONS[1]
    : ("dipole_gap" == field)         ? BOOM_DIMENSIONS[2]
    : ("dipole_offset" == field)      ? BOOM_DIMENSIONS[3]
    : ("hole_diameter" == field)      ? BOOM_DIMENSIONS[4]
    : ("reflector_position" == field) ? BOOM_DIMENSIONS[5]
    : ("element_width" == field)      ? BOOM_DIMENSIONS[6]
    : ("element_thickness" == field)  ? BOOM_DIMENSIONS[7]
    : assert(false , str("Invalid boom dimension field '", field, "'"))
);

/// ---------------------------------


/// ---------- Driver code ----------

module ellipseCut() {
    up(10 - elemDiffCorrection)
    position(TOP+FRONT) orient(BOT)
    {
        left(30)
        linear_extrude(20) ellipse([10, 26], anchor=FRONT);
        right(30)
        linear_extrude(20) ellipse([10, 26], anchor=FRONT);
    }
}

// Main Part
boomCutDiff()
boomCuboid(0, 2, boomDimensions) {
    position(FRONT) orient(FRONT)
    boomPlugBlock(0.5);
    
    tag("remove") {
        // hole before dipole
        // TODO dynamic adjust
        back(90)
        position(FRONT)
        cuboid([50 - 25, 10, 20]);

        up(elemDiffCorrection)
        position(FRONT+TOP)
            boomText();

        position(BACK) orient(FRONT)
        boomPlugBlock(0.0);
        
        // TODO dynamic cuts, adjust for different frequencies etc
        back(43)
        ellipseCut();
    }
}

// Additional Parts
for (i = [3 : directorCount + 1]) {
    part_i = i - 2;

    right(60 * part_i)
    fwd(80 * part_i)
    boomCutDiff()
    boomCuboid(i, i, boomDimensions) {
        position(FRONT) orient(FRONT)
        boomPlugBlock(0.5);

        tag("remove") {
            back(5)
            up(elemDiffCorrection)
            position(FRONT+TOP)
            text3d(str("Director #", i - 1), 0.5, size=3,
                anchor = TOP, font = "Osifont");

            position(BACK) orient(FRONT)
            boomPlugBlock(0.0);
        }

        // TODO dynamic cuts, adjust for different frequencies etc
        tag("remove")
        ellipseCut();
    }
}

/// ---------------------------------


// --------- Implementation ---------

module hole(position, diameter) {
    back(position)
        circle(d = diameter);
}

module element(position, length, width) {
    back(position)
        rect([length, width], anchor=FRONT);
}

module dipole(position, length, gap, width) {
    left(length / 4 + gap / 2)
        element(position, length / 2, width);
    right(length / 4 + gap / 2)
        element(position, length / 2, width);
}

// Extrudes elements slightly higher so that preview doesn't glitch the side.
elemDiffCorrection = ($preview) ? 0.1 : 0;

// True iff element is driven, that is index of element is `1`. 
function isElementDriven(element_index) = (element_index == 1);

module allElements(boomDims) {
    linear_extrude(boomDims("element_thickness") + elemDiffCorrection)
    for (i = [0 : 1 : len(elementParameters) - 1]) {
        param = elementParameters[i];
        
        pos = boomDims("reflector_position") + param[_ElemParamPosition];
        if (isElementDriven(i)) {
            dipole(pos, param[_ElemParamLength], boomDims("dipole_gap"), boomDims("element_width"));
        }
        else {
            element(pos, param[_ElemParamLength], boomDims("element_width"));
        }
    }
}

module allHoles(boomDims) {
    linear_extrude(boomDims("thickness")) 
    back(boomDims("element_width") / 2)
    for (i = [0 : 1 : len(elementParameters) - 1]) {
        param = elementParameters[i];
        
        pos = boomDims("reflector_position") + param[_ElemParamPosition];
        if (isElementDriven(i)) {
            left (boomDims("dipole_offset")) hole(pos, boomDims("hole_diameter"));
            right(boomDims("dipole_offset")) hole(pos, boomDims("hole_diameter"));
        }
        else {
            hole(pos, boomDims("hole_diameter"));
        }
    }
}

// Returns part origin and end position `[A, B]` on boom length.
function boomPartEndpoints(element_i, dims) = (
    /* Antenna Part Dimensions
            .----------.
       (i-1):      (i) :
        ||  :      ||  :     ||
        ||==+======||==+=====||
        ||  :      ||  :     ||
        :   :      :   :
        \___^      \___^
         w+p        w+p
    w - Element width
    p - Padding after element
    */
    assert(element_i < len(elementParameters), str("Boom part '", element_i ,"' out of range."))
    let (
        padding_from_element = 15,
        spacing_offset  = padding_from_element + dims("element_width"),
        
        position_prev   = (element_i >= 1) ? elementParameters[element_i - 1][_ElemParamPosition] : (-dims("reflector_position")-spacing_offset),
        position_this   = elementParameters[element_i][_ElemParamPosition],
        
        position_origin = position_prev + spacing_offset + dims("reflector_position"),
        position_end    = position_this + spacing_offset + dims("reflector_position")
    )

    [ position_origin, position_end ]
);

// Returns origin and end position of range of parts between `start_i` and `end_i`.
function boomPartEndpointsRange(start_i, end_i, dims) = (
    [ boomPartEndpoints(start_i, dims)[0], boomPartEndpoints(end_i, dims)[1] ]
);

module boomCuboid(start_i, end_i, dims) {
    points = boomPartEndpointsRange(start_i, end_i, dims);
    origin = points[0];
    length = points[1] - points[0];
    size = [dims("width"), length, dims("thickness")];

    back(origin)
    cuboid(size, anchor = DOWN+FRONT, rounding=3, edges="Z")
        children();
}

// TODO adjust for different sizes
module boomText() {
    back(55)
    text3d("QAGI 868", 0.5, size=5,
        anchor = TOP, font = "Osifont");

    back(51)
    text3d("3-element", 0.5, size=3,
        anchor = TOP, font = "Osifont");

    back(45)
    text3d(str("v", MODEL_VERSION), 0.5, size=3,
        anchor = TOP, font = "Overpass");
}

module boomCutDiff() {
    tag_scope()
    diff() {
        children();

        tag("remove") {
            up(boomDimensions("thickness") - boomDimensions("element_thickness"))
            allElements(boomDimensions);
            allHoles(boomDimensions);
        }
    }
}

module boomPlugBlock(plug_middle_gap = 0.0) {
    width = 10;
    height = 3;
    thickness = 2;

    plugBlock(n = 9, width, height, spacing = 4)
        plug(width, height, thickness, middle_gap = plug_middle_gap);
}

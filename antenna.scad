// Yagi antenna boom model made by sqbi-q.
// Designed for flat element shape (3G-Aerial DL6WU calculator).

MODEL_VERSION = "0.1.0";

include <./BOSL2/std.scad> // from local dir
//include <BOSL2/std.scad> // from library dir

use <./connector.scad>

/// Load fonts
use <./fonts/osifont-lgpl3fe.ttf>
use <./fonts/overpass-regular.otf>
///

$fn = 20;


elementParameters = [
//    Position   Length   Is driven
    [    0,      166,     false ],
    [   69,      158,     true  ],
    [ 94.9,      142,     false ],
    [  157,      139,     false ],
    [  231,      137,     false ]
];

boomLength = 300;


module hole(position, diameter) {
    back(position)
        circle(d = diameter);
}

module element(position, length, width = 10) {
    back(position)
        rect([length, width], anchor=FRONT);
}

module dipole(position, length, gap, width = 10) {
    left(length / 4 + gap / 2)
        element(position, length / 2, width = width);
    right(length / 4 + gap / 2)
        element(position, length / 2, width = width);
}

// Extrudes elements slightly higher so that preview doesn't glitch the side.
elemDiffCorrection = ($preview) ? 0.1 : 0;

module allElements(reflector_position = 30, dipole_gap = 2, element_width = 10) {
    // Element parameters indexes
    _position  = 0;
    _length    = 1;
    _is_driven = 2;

    linear_extrude(2 + elemDiffCorrection)
    for (param = elementParameters) {
        pos = reflector_position + param[_position];
        if (param[_is_driven]) {
            dipole(pos, param[_length], dipole_gap, width = element_width);
        }
        else {
            element(pos, param[_length], width = element_width);
        }
    }
}

module allHoles(
    reflector_position = 30, dipole_offset = 20, hole_diameter = 3.5, 
    element_width = 10
) {
    // Element parameters indexes
    _position  = 0;
    // _length    = 1;
    _is_driven = 2;

    linear_extrude(height = 20) 
    back(element_width / 2)
    for (param = elementParameters) {
        pos = reflector_position + param[_position];
        if (param[_is_driven]) {
            left (dipole_offset) hole(pos, hole_diameter);
            right(dipole_offset) hole(pos, hole_diameter);
        }
        else {
            hole(pos, hole_diameter);
        }
    }
}


module boomShape(boom_length = 300, width = 50) {
    tag_scope()
    diff() {
        // base rectangle
        rect([width, boom_length], anchor=FRONT, rounding=3);

        tag("remove") {
            // hole before dipole
            back(90) rect([width - 25, 10]);

            // side flowing cut thingy
            back(43) {
                right(width/2 + 5) ellipse([10, 26], anchor=FRONT);
                left (width/2 + 5) ellipse([10, 26], anchor=FRONT);
            }
            back(140) {
                right(width/2 + 5) ellipse([10, 20], anchor=FRONT);
                left (width/2 + 5) ellipse([10, 20], anchor=FRONT);
            }
            back(200) {
                right(width/2 + 5) ellipse([10, 30], anchor=FRONT);
                left (width/2 + 5) ellipse([10, 30], anchor=FRONT);
            }
        }
        //
    }
}

module boom(boom_length = 300, width = 50, thickness = 10) {
    half_length = boom_length / 2;
    ymove(half_length)
    zmove(thickness)
    attachable(size=[width, thickness, boom_length], 
        offset=[0, 0, 0], cp=[0, 5, -half_length], axis=FRONT
    ) {
        linear_extrude(thickness, center=true)
            boomShape(boom_length, width);

        up(thickness/2 + elemDiffCorrection)
            orient(BOT)
            children();
    }
}

module boomPlugBlock(plug_middle_gap = 0.0) {
    width = 10;
    height = 3;
    thickness = 2;

    plugBlock(n = 9, width, height, spacing = 4)
        plug(width, height, thickness, middle_gap = plug_middle_gap);
}

module boomWhole(boom_length = 300, width = 50, thickness = 10) {
    tag_scope()
    diff()
    boom(boom_length, width, thickness) {
        // Plug blocks at the beginning and at the end
        tag("keep") {
            // TODO optimize (probably it has to do with intersects
            // and usage of boomWhole() multiple times.
            position(FRONT) orient(FRONT)
            boomPlugBlock(0.5);

            position(BACK) orient(BACK)
            boomPlugBlock(0.5);
        }

        tag("remove") allElements();
        tag("remove") allHoles();
        
        // Etch information on boom
        tag("remove") {
            back(55)
            text3d("QAGI 868", 0.5, size=5,
                anchor = TOP, orient = DOWN,
                font = "Osifont");

            back(51)
            text3d("5-element", 0.5, size=3,
                anchor = TOP, orient = DOWN,
                font = "Osifont");


            back(45)
            text3d(str("v", MODEL_VERSION), 0.5, size=3,
                anchor = TOP, orient = DOWN,
                font = "Overpass");
        }

        tag("keep") children();
    }
}

module boomCutBox(
    elements_count, origin_element,
    boom_length = 300, boom_width = 50, boom_thickness = 10,
    element_width = 10, reflector_position = 30
) {
    // Element parameters indexes
    _position  = 0;
    // _length    = 1;
    // _is_driven = 2;

    // used for including connectors etc
    lengthBehindBoom = 50;
    lengthAfterBoom  = 50;

    // Calculate positions for cuts between elements
    positionsBetweenElements = [
        for (i = [0 : 1 : len(elementParameters) - 2])
        let(
            thisParam = elementParameters[i],
            nextParam = elementParameters[i + 1],

            thisPos = thisParam[_position] + element_width / 2,
            nextPos = nextParam[_position] + element_width / 2,

            midPos = (thisPos + nextPos) / 2
        )
        reflector_position + midPos
    ];
    cutPositions = concat(
        0 - lengthBehindBoom,         // first cut position, from the start
        positionsBetweenElements,
        boom_length + lengthAfterBoom // last cut position, until the end
    );

    originPosition = cutPositions[origin_element];
    
    lastElem = origin_element + elements_count;
    lastPosition = cutPositions[lastElem];

    boxLength = lastPosition - originPosition;

    width = boom_width + 30;

    back(originPosition)
    attachable(size=[width, boxLength, boom_thickness], anchor=BOT+FRONT) {
        cuboid([width, boxLength, boom_thickness]);
        children();
    }
}

module boomCut(elements_count, origin_element,
    boom_length = 300, boom_width = 50, boom_thickness = 10,
    element_width = 10, reflector_position = 30
) {
    tag_scope()
    intersect() {
        tag("") boomWhole(boom_length, boom_width, boom_thickness);
        tag("intersect") boomCutBox(
            elements_count, origin_element,
            boom_length, boom_width, boom_thickness,
            element_width, reflector_position
        );    
    }

    hide_this() 
    boomCutBox(
        elements_count, origin_element,
        boom_length, boom_width, boom_thickness,
        element_width, reflector_position
    )
    children();

}


/// Driver code:

boomWhole(boomLength);

module exampleBoomParts() {
    boomCut(3, 0)
        position(BACK) orient(BACK)
        boomPlugBlock(0.5);

    fwd(150) right(60)
    tag("remove")
    diff()
        boomCut(2, 3)
        socketInside()
        boomPlugBlock();
}
// exampleBoomParts();
// Connector plug and socket for modular parts.

include <./BOSL2/std.scad> // from local dir
//include <BOSL2/std.scad> // from library dir

_SIMPLE_PLUG_BLOCK_ON_PREVIEW = true;

$fn = 50;

module plug(width, height, thickness, angle=45,
    pin_size = [2, 1], pin_height=0.2, pin_rounding = 0.1,
    middle_gap = 0.0
) {
    module plugBase(width, height, thickness, angle) {
        attachable(anchor = TOP+FRONT, size=[width, height, thickness], orient=FRONT) {           
            shape = trapezoid(w1=width, h=height, ang=angle, rounding=[0.5, 0.5, 0, 0]);
            
            tag_scope()
            diff() {
                offset_sweep(shape, thickness)
                tag("remove") cuboid([width, height, middle_gap]);
            }

            children();
        }
    }

    module pin(h, anchor, orient) {
        pin_top_size = pin_size - [pin_height, pin_height] * 2;
        prismoid(pin_top_size, pin_size, height=pin_height,
            rounding=pin_rounding, anchor=anchor, orient=orient);
    }

    zrot(90)
    plugBase(width, height, thickness, angle)
    union() {
        children();
        color("red") {
            attach(BACK)
                pin(pin_height, anchor=TOP+FRONT, orient=BACK);

            zmove(thickness)
            attach(BACK)
                pin(pin_height, anchor=TOP+BACK, orient=FRONT);
        }
    }
}

//// Plug Block

module plugBlock(n, width, height, spacing) {
    if (_SIMPLE_PLUG_BLOCK_ON_PREVIEW && $preview) {
        epsilon=0.1; // fix glitching side
        color("pink")
        down(epsilon)
        cuboid([(spacing * n), width, height + epsilon], anchor=DOWN);
    } else {
        xcopies(spacing, n)
            children();
    }
}

////

//// Sockets

module socketDiff() {
    diff()
        tag_this("") children();
}

module socketInside(position = FRONT) {
    position(position) orient(-position)
        children();
}

////


//// Example usage:

//
// plug(10, 3.5, 1);
// 

// module plugBlock(anchor=CENTER, pin_attach=FRONT) {
//     cuboid(20, anchor=anchor)
//         attach(pin_attach)
//             xcopies(4, 5) plug(18, 6, 2);
// }

// module plugSocket() {
//     diff("remove")
//         cuboid(20)
//             tag("remove")
//                 position(FRONT) orient(FRONT)
//                     plugBlock(BOT, pin_attach=BOT);
// }

// plugBlock();
// xmove(25) plugSocket();

////
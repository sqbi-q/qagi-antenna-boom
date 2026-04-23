# QAGI Parametric Yagi Antenna Boom

![Qagi boom model](./img/openscad_model.webp)

---

A OpenSCAD model for 3D-Printing Yagi-Uda antenna boom.

Uses [BOSL2](https://github.com/BelfrySCAD/BOSL2) library, 
[Osifont](https://github.com/hikikomori82/osifont) 
and [Overpass](https://github.com/RedHatOfficial/Overpass) 
fonts.

Nightly build of OpenSCAD is recommended (tested on version *2026.02.27*).

## Parameters

By default, boom design follows result of 
[ported DL6WU library](https://github.com/sqbi-q/dl6wu.c) ([dl6wu.scad](./dl6wu.scad)) for
- frequency 869 MHz,
- 5 flat elements,
- 10 mm element width,
- 2 mm element thickness.

Elements are fitting thightly into positions, holes have diameter of 3.5 mm.

Custom trapezoidal connectors are used for modular parts.

## Installation

Clone this repo with submodules and export model to STL with `openscad`: 

```sh
git clone --recurse-submodules https://github.com/sqbi-q/qagi-antenna-boom.git
openscad -o antenna-out.stl -- antenna.scad
```

---

![Qagi antenna showcase photo](./img/yagi_antenna.webp)
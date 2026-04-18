// dl6wu.scad - port of dl6wu.c for OpenSCAD

// <SCAD_VERSION>-portof.<C_VERSION>
DL6WU_VERSION = "0.0.1-portof.0.0.3";

// Returns wavelength (in mm) for frequency (in MHz).
function frequencyToWavelength(freq) = 299793.0 / freq;

element_spacings = [
    0,   // Reflector
    0.2, // Driven to Reflector
    0.075, 0.180, 0.215, 0.250, 0.280, 0.300, 0.315,
    0.330, 0.345, 0.360, 0.375, 0.390, 0.400, 0.400 //... repeating
];
element_spacings_length = len(element_spacings);

element_distances = [
    0,   // Reflector
    0.2, // Driven to Reflector
    0.275, 0.455, 0.670, 0.920, 1.200, 1.500, 1.815,
    2.145, 2.490, 2.850, 3.225, 3.615, 4.015, 4.415
    //... sequence 4.415 + n * 0.400
];
element_distances_length = len(element_distances);

standard_diameters = [ .001, .003, .005, .007, .01, .015, .02 ];
standard_diameters_length = len(standard_diameters);

standard_factors = [
    [ 0.47110, 0.01800, 0.08398, 0.96500 ], // diam .001
    [ 0.46200, 0.01941, 0.08543, 0.96970 ], // diam .003
    [ 0.45380, 0.02117, 0.09510, 1.00700 ], // diam .005
    [ 0.44910, 0.02274, 0.08801, 0.90040 ], // diam .007
    [ 0.44210, 0.02396, 0.10270, 1.03800 ], // diam .010
    [ 0.43580, 0.02558, 0.11490, 1.03400 ], // diam .015
    [ 0.42680, 0.02614, 0.11120, 1.03600 ], // diam .020
];
standard_factors_length = standard_diameters_length;

// Returns interpolation factor for diameter between two standard ones.
function diameterInterpolationFactor(
    parasitic_diameter,
    low_diameter,
    high_diameter
) = (parasitic_diameter - low_diameter) / (high_diameter - low_diameter);

function FactorsInterpolate(parasitic_diameter) = (
    let (isBound = function (d) 
            (d >= standard_diameters[0]
            && d <= standard_diameters[standard_diameters_length - 1]))
    
    let (iterInterpolate = function () (
        [for (q = [0 : 1 : standard_diameters_length - 1])
         let (
             diameter_q = standard_diameters[q],
             factors_q  = standard_factors[q],
             // potential wrong index (q - 1) < 0
             diameter_p = standard_diameters[q - 1],
             factors_p  = standard_factors[q - 1]
         )
         if (diameter_q == parasitic_diameter)
             [ factors_q, [], 0.0 ]
         else if (diameter_q > parasitic_diameter)
             [factors_p, factors_q, 
                 diameterInterpolationFactor(
                     parasitic_diameter, diameter_p, diameter_q)]
        ][0] // get first result
    ))

    !isBound(parasitic_diameter) ? (-1) : (
        iterInterpolate()
    )
);

function fi_lowFactors(src)           = src[0];
function fi_highFactors(src)          = src[1];
function fi_interpolationFactors(src) = src[2];

// Returns i-th director length (indexed from 0).
function directorLengthFromFactors(i, factors) = ( // for exact factors
    let (n = i + 1)
    assert(len(factors) == 4, "factors has to be 4-element vector")
    (factors[0] - factors[1] * ln(n)) * (1 - factors[2] * exp(-factors[3] * n))
);

function directorLengthFromInterpolate(i, src) = ( // for interpolated factors
    (fi_lowFactors(src) == 0 || fi_highFactors(src) == [])
        ? directorLengthFromFactors(i, fi_lowFactors(src))
        : (
            let (l = directorLengthFromFactors(i, fi_lowFactors(src)))
            let (h = directorLengthFromFactors(i, fi_highFactors(src)))
            let (f = fi_interpolationFactors(src))
            l + f * (h - l)
        )
);

function reflectorLength(parasitic_diameter) = (
    let (reflector_reactance = 20)

    ((( reflector_reactance - 40 )
      / ( 186.8769 * ln( 2.0 / parasitic_diameter ) - 320 ))
     + 1 ) / 2
);
function drivenLength(driven_diameter) = (       // For simple dipole
    ( 0.4777 - (1.0522 * driven_diameter)
    + ( 0.43363 * pow(driven_diameter, -0.014891) )) / 2
);     
function drivenFoldedLength(driven_diameter) = ( // For folded dipole
    drivenLength(driven_diameter) * 1.02
);     

/* [NOT IMPLEMENTED]
// Returns metalic boom correction (in wavelengths) for diameter in valid range.
// Such correction is added to element length that pass through boom.
// Value should be halved if
// - if element passes through boom but is insulated,
// - or if element is mounted on top.
// Value isn't applied for elements mounted on insulators with 
// spacing of boom and element greater than radius of a boom.
// TODO error handling
double boomCorrection(double boom_diameter);            // For circle cross-section
double boomCorrectionSquare(double boom_diameter);      // For square cross-section
*/

// Returns space between `i`-th element (indexed from 0) and previous element:
// - For reflector (0-th element) space is `0.0`.
// - For driven (1-th) element space is equal to constant Reflector Spacing `0.2`.
// - For 16-th element and above spacing is of 15-th element.
function elementSpacing(i) = (
    (i < element_spacings_length) 
        ? element_spacings[i]
        : element_spacings[element_spacings_length - 1]
);


// Returns space between `i`-th element (indexed from 0) and reflector.
function elementDistance(i) = (
    (i < element_distances_length) 
        ? element_distances[i] 
        : (
            let (j = i - element_distances_length + 1,
                repeating_spacing = elementSpacing(i), // should be 0.400
                base_total = element_distances[element_distances_length - 1])
            
            base_total + j * repeating_spacing
        )
);

/* [NOT IMPLEMENTED]
// Returns `n`-element antenna forward gain estimate (in dBd).
double gainEstimate(size_t n);

// Returns VK1OD correlation value between H-plane and E-plane beamwidths.
double beamwidthFactor(double gain);

// Returns beamwidth (in degrees) for forward gain (in dBd).
double electricFieldBeamwidth(double gain);     // for electric field, E-plane
double magneticFieldBeamwidth(double gain);     // for magnetic field, H-plane

// Returns suggested distance (in wavelengths) between stacked antennas from beamwidth.
double stackingDistance(double beamwidth);

// Returns equivalent diameter for square elements.
double diameterFromSquare(double width, double thickness);
*/

function calculateAntenna(
    director_count,
    wavelength,
    driven_diameter,
    parasitic_diameter
) = (
    let (driven_wavelengths    = driven_diameter    / wavelength,
         parasitic_wavelengths = parasitic_diameter / wavelength,
         factors               = FactorsInterpolate(parasitic_wavelengths))

    assert(factors != -1, "Factors Interpolate initalized unsuccessfully")
    
    concat (
        [
         [reflectorLength(parasitic_wavelengths), elementSpacing(0)],
         [drivenLength(driven_wavelengths), elementSpacing(1)]
        ],
        [for (i = [0 : 1 : director_count])
         let (director_i = i + 2)
         [directorLengthFromInterpolate(i, factors), elementDistance(director_i)]
        ]
    ) * wavelength
);

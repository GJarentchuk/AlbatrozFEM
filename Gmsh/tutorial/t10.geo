/********************************************************************* 
 *
 *  Gmsh tutorial 10
 * 
 *  Homology computation
 *
 *********************************************************************/
 
// Homology computation in Gmsh finds representative chains of (relative) homology spaces using a mesh of a model. Those representatives generate the (relative) homology spaces of the model. Alternatively, Gmsh can only look for the ranks of the (relative) homology spaces, the Betti numbers of the model. 

// The generators chains are stored in a given .msh-file as physical groups, whose mesh elements are oriented such that their coefficients are 1 in the generator chain.


// Create an example geometry

m=0.5; // mesh characteristic length
h=2;

Point(newp) = {0, 0, 0, m};
Point(newp) = {10, 0, 0, m};
Point(newp) = {10, 10, 0, m};
Point(newp) = {0, 10, 0, m};
Point(newp) = {4, 4, 0, m};
Point(newp) = {6, 4, 0, m};
Point(newp) = {6, 6, 0, m};
Point(newp) = {4, 6, 0, m};

Point(newp) = {2, 0, 0, m};
Point(newp) = {8, 0, 0, m};
Point(newp) = {2, 10, 0, m};
Point(newp) = {8, 10, 0, m};

Point(newp) = {0, 0, h, m};
Point(newp) = {10, 0, h, m};
Point(newp) = {10, 10, h, m};
Point(newp) = {0, 10, h, m};
Point(newp) = {4, 4, h, m};
Point(newp) = {6, 4, h, m};
Point(newp) = {6, 6, h, m};
Point(newp) = {4, 6, h, m};

Point(newp) = {2, 0, h, m};
Point(newp) = {8, 0, h, m};
Point(newp) = {2, 10, h, m};
Point(newp) = {8, 10, h, m};
Line(1) = {16, 23};
Line(2) = {23, 11};
Line(3) = {11, 4};
Line(4) = {4, 16};
Line(5) = {24, 12};
Line(6) = {12, 3};
Line(7) = {3, 15};
Line(8) = {15, 24};
Line(9) = {10, 2};
Line(10) = {2, 14};
Line(11) = {14, 22};
Line(12) = {22, 10};
Line(13) = {21, 9};
Line(14) = {9, 1};
Line(15) = {1, 13};
Line(16) = {13, 21};
Line Loop(17) = {3, 4, 1, 2};
Ruled Surface(18) = {17};
Line Loop(19) = {6, 7, 8, 5};
Ruled Surface(20) = {19};
Line Loop(21) = {9, 10, 11, 12};
Ruled Surface(22) = {21};
Line Loop(23) = {14, 15, 16, 13};
Ruled Surface(24) = {23};
Line(25) = {16, 13};
Line(26) = {1, 4};
Line(27) = {11, 12};
Line(28) = {24, 23};
Line(29) = {21, 22};
Line(30) = {10, 9};
Line(31) = {2, 3};
Line(32) = {15, 14};
Line(33) = {20, 19};
Line(34) = {19, 18};
Line(35) = {18, 17};
Line(36) = {17, 20};
Line(37) = {8, 7};
Line(38) = {7, 6};
Line(39) = {6, 18};
Line(40) = {5, 6};
Line(41) = {5, 8};
Line(42) = {20, 8};
Line(43) = {17, 5};
Line(44) = {19, 7};
Line Loop(45) = {27, -5, 28, 2};
Ruled Surface(46) = {45};
Line Loop(47) = {25, -15, 26, 4};
Ruled Surface(48) = {47};
Line Loop(49) = {29, 12, 30, -13};
Ruled Surface(50) = {49};
Line Loop(51) = {32, -10, 31, 7};
Ruled Surface(52) = {51};
Line Loop(53) = {41, -42, -36, 43};
Ruled Surface(54) = {53};
Line Loop(55) = {35, 43, 40, 39};
Ruled Surface(56) = {55};
Line Loop(57) = {34, -39, -38, -44};
Ruled Surface(58) = {57};
Line Loop(59) = {33, 44, -37, -42};
Ruled Surface(60) = {59};
Line Loop(61) = {27, 6, -31, -9, 30, 14, 26, -3};
Line Loop(62) = {37, 38, -40, 41};
Plane Surface(63) = {61, 62};
Line Loop(64) = {25, 16, 29, -11, -32, 8, 28, -1};
Line Loop(65) = {34, 35, 36, 33};
Plane Surface(66) = {64, 65};
Surface Loop(67) = {46, 63, 20, 52, 66, 48, 24, 50, 22, 18, 60, 58, 56, 54};
Volume(68) = {67};

// Create physical groups, which are used to define the domain of the homology computation and the subdomain of the relative homology computation.

// Whole domain
Physical Volume(69) = {68};
// Four "terminals" of the model
Physical Surface(70) = {18};
Physical Surface(71) = {20};
Physical Surface(72) = {22};
Physical Surface(73) = {24};
// Whole domain surface
Physical Surface(74) = {46, 18, 20, 52, 22, 50, 24, 48, 66, 63, 60, 58, 56, 54};
// Complement of the domain surface respect to the four terminals
Physical Surface(75) = {46, 63, 66, 52, 50, 48, 54, 60, 58, 56};

// Create a mesh of the model
Mesh 3;

// Find generators of relative homology spaces of the domain modulo the 
// four terminals.
// Save the generator chains to t10_hom.msh.
HomGen("t10_hom.msh") = {{69}, {70, 71, 72, 73}};

// Find the corresponding thin cuts, 
// generators of relative homology spaces modulo the 
// non-terminal domain surface.
// Save the cut chains to t10_hom.msh.
HomGen("t10_hom.msh") = {{69}, {75}};

// Find the corresponding thick cuts.
// Save the cut chains to t10_hom.msh.
HomCut("t10_hom.msh") = {{69}, {70, 71, 72, 73}};

// More examples (uncomment):
//  HomGen("t10_hom.msh") = {{69}, {}}; 
//  HomGen("t10_hom.msh") = {{}, {}};
//  HomGen("t10_hom.msh") = {{69}, {74}}; 
//  HomGen("t10_hom.msh") = {{}, {74}}; 

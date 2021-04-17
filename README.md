# AlbatrozFEM

Albatroz FEM is a Finite Element Method (FEM) software developed for simplified structural analysis, mostly developed in Lua. It uses unidimensional (1D) modified Euler beam elements, with corrections that attempts to better represent shear stresses for shorter beams.

![](Doc.%20Images/Intro.png?raw=true "Introduction")


Most of the program was developed back in 2012 to assist [Albatroz Team](https://equipealbatroz.com.br/) from Santa Catarina State University (UDESC - Joinville, Brazil) aircraft design for the national SAE Aerodesign competition. This version is a patch of the original code to provide minor bug fixes and to run the program without having to install many additional dependencies.

The goal was to provide a structural analysis tool with a mathematical model that could be learned relatively quickly by a novice engineering student, but robust enough to be used as reliable design tool for a large array of potential structural configurations the aircraft could have. In fact, the team had a design philosophy of always to conceive a strutural design that could be evaluated by a combination of numerical models + empirical tests and corrections.

Internally among Albatroz members, this program is known as Albatroz Parametric, as it was intended later on adding structural optimization tools.

AlbatrozFEM is written in Lua and was only tested for Windows. It uses the following third party tools:
  * A simple linear system solver written in C, by Guilherme Espíndola;
  * treeview.lua is part of nadzoru, by Yuri Kaszubowski Lopes;
  * [Gmsh](https://gmsh.info/) as 3D mesh and result visualisation tool, by Christophe Geuzaine and Jean-François Remacle.

## Table of contents
- [Instalation](#instalation)
- [Basic Usage](#basic-usage)
   - [Finite Elements tab](#finite-elements-tab)
     - [Running the simulation - Config and run simulation button](#running-the-simulation---config-and-run-simulation-button)
     - [View results](#view-results)
   - [Material-component tab](#material-component-tab)
   - [MeshTools tab -unfinished-](#meshtools-tab--unfinished-)
- [Known Issues](#known-issues)
- [License](#license)


## Instalation

It's a portable program, just download all the contents to a local folder. After that, open "Config.lua" and change the file path of "working_directory" and "default_project". Beware that double backslahses are needed.

If running the program manually from CMD (useful for seeing terminal error messages), run as the following:

    SET PATH=%CD%\GTK2;%PATH% & lua AlbatrozFEM.lua

This repo already provides some materials and an example project in "Projects" folder called "Example-Fuselage-Flight.pro", very similar to one case study of the 2012 aircraft.


## Basic Usage

Each study case is stored in .pro files that are lua parsable. Projects contain mesh information (nodes and elements), loads, constraints and "material-component".

Upon creating a new project, go first to the "Material-component" tab to assign at least one for the project. Doing so may prevent some crashes.

Top toolbar buttons:<br>
(note: these will be the only buttons shown if the program is launched without a default project set up, see Config.lua)
1. Create new project;
2. Open project;
3. Save project;
4. Save project as;
5. Set this project as default to load upon program launch (green arrow);
6. Options (very few actually);

Upon creating or loading a project:

### Finite Elements tab

![](Doc.%20Images/FEM.png?raw=true "")

* Add node: adds a new unique node at the bottom of the list, with coordinates [0, 0, 0]. All nodes must have a unique name.
* Pattern add node: opens a dialog to create multiple nodes. The value you put on ID, X, Y, or Z fields will be kept the same throughout the "n" nodes. The exception is for "ID", as this field must be unique for each node, setting a value for it will count as a prefix for all the "n" nodes, with a number suffix added after each generated node.
* Delete node: select one or more nodes on the table and then press the button.
* Add constraint: pressing this button after selecting one or more nodes from the node table creates a constraint list for each one of them.
  * Checking a constraint box will lock one degree of freedom from that node, making its displacement or rotation = zero.
* Delete constraint: similar to "Delete node".
* View on Gmsh: opens Gmsh for mesh visualisation. It doesn't work in parallel to AlbatrozFEM, so Gmsh must be closed before further using AlbatrozFEM.
  * On Gmsh view:
  * Blue arrows are forces and red arrows are moments (torque). If green arrows are shown instead it means there are only forces or only moments added to the mesh.
  * You can view node and elements ids, that are hidden by default. Example on the next figure.
  
![](Doc.%20Images/Gmsh_ids.png?raw=true "")

* **Add element**: to add an element, be sure to have at least one material assigned to the project (see Material-component tab).
  * First toggle "Add element";
  * Be sure that the desired material is selected on the "Element material" combo box;
  * Select two nodes from the node list;
  * Press "a" key on the keyboard to create an element with these two nodes and the selected material. Node selection order doesn't matter;
  * Untoggle "Add element" after finishing;
  * Each element also have a unique ID that can be changed.
* Change element material: first select a new material from its combo box, then select all the elements you want to change and then click the "Change element material" button.
* Delete element: similar to "Delete node".
* Import nodes from/to "Excel" (tsv) buttons:
  * Import or export the node list to a Tab Separated Values file (.tsv).
* **Add load**: select one or more nodes, press this button. It opens a dialog:
  * Each force and moment vector component is added as a seperate load.
  * Several text fields to add prefixes. It is useful to add the same load to different nodes all at once.
* Delete load: similar to "Delete node".
Add inertia loads: adds loads to simulate inertial forces, like weight or accelerations. The acceleration component values typed in the dialog fields are then multiplied individually by each element mass. The resulting load vectors are then split between both element nodes. 
 
#### Running the simulation - Config and run simulation button

Before running the simulation, the program shows the number of nodes and size of stiffness matrix. It also checks for data entry errors and tries to generate all the necessary calculation matrices. Possible error messages:
* Node with same id found! Make sure all node IDs are unique.
* Element with same id found! Make sure all elements IDs are unique.
* WARNING: Element "elem_name" x and z vectors aren't orthogonal! dotValue = "dot_product_not_zero_value".
* Non-orthogonal x and z vectors were found in one or more elements!

**Warning:** One common mistake is to constraint the model in such a way that mathematically the generated stiffness matrix becomes singular. Often this means that the mesh is statically indeterminate, and the application crashes. If AlbatrozFEM is run manually from CMD, a message will appear to indicate this: "Matriz singular. Sistema sem solucao unica."  

Two main sources of bad constraining are:
* The model actually lacks further constraining;
* There are loose nodes that aren't connected to anything but seems to be so when opening the mesh on Gmsh. Mind that the code doesn't prevent the user on creating two nodes at exactly the same location.

If the pre-check is successful, the user can press "Run simulation".

AlbatrozFEM uses a 1D modified Euler beam element model. Most relevant information may be found in Libraries\Simulation.lua. The mode local stiffness matrix is:

_(for an enlarged version, open Doc. Images\K.png)_ 

![](Doc.%20Images/K.png?raw=true "")

REPLACE:
* If element cross-section is tubular, replace:
![](Doc.%20Images/K_tube.png?)

WHERE:
* alpha = (12\*E\*Izz\*fsy)/(G\*A\*L^2)
* beta  = (12\*E\*Iyy\*fsz)/(G\*A\*L^2)
* E = Young modulus [Pa]
* G = Shear modulus [Pa]
* A = Cross section area [m<sup>2</sup>]
* L = Element length [m]
* I<sub>yy</sub> = Area moment of inertia, y axis [m<sup>4</sup>]
* I<sub>zz</sub> = Area moment of inertia, z axis [m<sup>4</sup>]
* f<sub>sy</sub> = Shear factor in y direction 
* f<sub>sz</sub> = Shear factor in z direction
* J = Polar area moment of inertia [m<sup>4</sup>]
* f<sub>t</sub> = Torsion factor
* A<sub>m</sub> = Median area (tube only) = (( pi\*( r<sub>i</sub> + (t/2) )^2 )) [m<sup>2</sup>]
* t = tickness (tube only) = r<sub>o</sub> - r<sub>i</sub> [m]
* r<sub>o</sub> = outer radius (tube only) [m]
* r<sub>i</sub> = inner radius (tube only) [m]
* S = (tube only) ((ro + ri)/2)\*pi\*2 [m]

The simulation will solve the linear system [K]._u_<sup>&#8594;</sup> = _F_<sup>&#8594;</sup> for displacement, where [K] is the global stiffness matrix, _F_<sup>&#8594;</sup> is the loads vector and _u_<sup>&#8594;</sup> is the displacement vector to be evaluated.

With the displacement in hand, local element forces, stresses and failure condition are evaluated. AlbatrozFEM has three equivalent stress methods to determine failure: "von Mises" for ductile, "Rankine" for fragile and "simplified Tsai-Hill" for 1D oriented fibres composites (like polymer extruded carbon fibre rods).

#### View results

After running a successful simulation, you may open "View results". At the top, there's the total mesh mass, summed from all the elements, and a button to save all the calculated element results and node displacements in more detail.

Below those, the deformed mesh may be visualised with a scaling factor, defaulted to 1.

Finally at the last section maximum stresses can be visualised.

**Note:** for the "Maximum stress" section, "Deformed mesh" and "With buckling" don't work. Buckling failure criteria development was interrupted.

### Material-component tab

![](Doc.%20Images/Material.png?)

In AlbatrozFEM, all elements require a "component". A component is a material type coupled with cross section and is defined in this tab. Unfortunately, while many cross section parameters can be calculated from basic geometry information (e.g. radius, width and height), all data must be inserted manually.

Note: for a material to be available for an element, it must be included in the project first.

#### Cross section shear and torsion coefficients

These coefficients are used to make compensations around some limitations of the 1D elements. Follow this list to select the best value for your component in AlbatrozFEM model:

* Shear factors, (in z dir and y dir): while two different input values, they're supposed to be the same in the current implementation. For circles and tubes, use 1.0. For rectangles, use 1.2.
  
* Torsion factor:

  Correction for non-circular cross sections for the stiffness matrix. For stresses the equivalent factor is calculated automatically.
  * Circular x-sec: use 1;
  * Tubular x-sec: use 1;
  * Rectangular x-sec: torsion factor =  J/(beta\*width\*(height^3)), where:
    * width > height
    * beta comes from interpolating between the following values: 
    ![](Doc.%20Images/Beta_table.png?)


### MeshTools tab -unfinished-

![](Doc.%20Images/MT.png?)

This tab was the last section being code before development interruption. There are three tools, all which have bugs:

* Export mesh to STEP: useful to add the mesh to a CAD project as skeleton. It exports to the neutral STEP format (a text file) and back in 2012 it loaded successfully on Pro/Engineer 5. While porting the code to AlbatrozFEM, some online STEP file viewers couldn't render it though.

* Linear interpolation: useful for mesh refining, it replaces an element by N smaller ones in place. While the interpolation does happen, it often crashes the program later on.

* Arc interpolation: transform what would be in the real life design an arc into a series straight elements. Also shares the same bugs as the linear tool.


## Known Issues

* There are two disabled buttons regarding "scenarios". It was a planned feature that would allow to have variations of loads, constraints and element material types within the same project. Due time constrains it was never finished.
* Clinking on "Save", "Save as" or "Set this as default project" (green arrow) without any project open crashes the application. 
* "Save as" button: user MUST manually write ".pro" extension on file name.
* "On Pre-run check" dialog (from "Config and run simulation"), "View calculation script does nothing.
* "View results" window:
  * If asked to plot results before any simulation had already run (like upon opening the application), it'll crash the program.
  * "Deformed mesh" doesn't work for stress plotting. It'll always plot undeformed.
* Anytime a file chooser dialog is brought up, there will be a message on the terminal complaining about a "gtk-file" icon missing.
* "Export mesh to STEP" file works, but the resulting .stp file may not be opened properly by some tools.
* Sometimes, nodes and elements generated by interpolation crashes the solver.
* Manual adding of new materials is still needed if .mat files are just copied into materials folder.
* No alphabetical sorting of materials.


## License
This program uses [GNU General Public License v3](License-gpl3.txt) license.

Some of the code is from nadzoru, licensed under LGPL3.

An old version Gmsh (2.5.0) is also packed with AlbatrozFEM as it is used for mesh and results visualisation. It is licensed under GPL2.

# AlbatrozFEM

Albatroz FEM is a Finite Element Method (FEM) software developed for simplified structural analysis, mostly developed in Lua. It uses unidimensional (1D) modified Euler beam elements, with corrections that attempts to better represent shear stresses for shorter beams.

Most of the program was developed back in 2012 to assist [Albatroz Team](https://equipealbatroz.com.br/) from Santa Catarina State University (UDESC - Joinville, Brazil) aircraft design for the national SAE Aerodesign competition. This version is a patch of the original code to provide minor bug fixes and to run the program without having to install many additional dependencies.

The goal was to provide a structural analysis tool with a mathematical model that could be learned relatively quickly by a novice engineering student, but robust enough to be used as reliable design tool for a large array of potential structural configurations the aircraft could have. In fact, the team had a design philosophy of always to conceive a strutural design that could be evaluated by a combination of numerical models + empirical tests and corrections.

Internally among Albatroz members, tis program is known as Albatroz Parametric, as it was intended later on to add structural optimization tools. **TCC adaptation missing**


## Table of contents

* [Known Issues](#known-issues)
* [License](#license)









**NEED TO SETUP GNU LICENCES**


**Acknowledge nadzoru**

Tab Separated Values file (.tsv)

## Known Issues

* "Save as": need to manually write .pro on file name.
* "View results":
  * If asked to plot results before any simulation had already ran (like upon opening the application), it'll crash.
  * Deformed mesh doesn't work for stress plotting.
* Anytime a file chooser dialog terminal will complain about a 'gtk-file" icon missing.
* Scenarios don't work.
* STEP export works, but stp file seems to have problems being opened by tools.
* Sometimes, nodes and elements generated by interpolation crashes the solver.
* Manual adding of new materials needed if files are just copied into materials folder.
* No alphabetical sorting of materials
* Disabled buttons:
  * Scenario bugged
  * About wasn't implemented


##License
This program uses [GNU General Public License v3](License-gpl3.txt) license.
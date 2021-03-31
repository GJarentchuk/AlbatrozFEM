// Gmsh - Copyright (C) 1997-2010 C. Geuzaine, J.-F. Remacle
//
// See the LICENSE.txt file for license information. Please report all
// bugs and problems to <gmsh@geuz.org>.

#ifndef _GMSH_CONFIG_H_
#define _GMSH_CONFIG_H_

/* #undef HAVE_64BIT_SIZE_T */
/* #undef HAVE_ACIS */
#define HAVE_ANN
#define HAVE_BAMG
#define HAVE_BLAS
#define HAVE_CHACO
/* #undef HAVE_DLOPEN */
#define HAVE_DINTEGRATION
#define HAVE_FLTK
#define HAVE_FL_TREE
/* #undef HAVE_FOURIER_MODEL */
#define HAVE_GMM
/* #undef HAVE_GMP */
#define HAVE_KBIPACK
#define HAVE_LAPACK
/* #undef HAVE_LIBCGNS */
#define HAVE_LIBJPEG
#define HAVE_LIBPNG
#define HAVE_LIBZ
#define HAVE_LUA
/* #undef HAVE_MATCH */
#define HAVE_MATHEX
#define HAVE_MED
#define HAVE_MESH
#define HAVE_METIS
#define HAVE_MPEG_ENCODE
/* #undef HAVE_MPI */
#define HAVE_NATIVE_FILE_CHOOSER
#define HAVE_NETGEN
#define HAVE_NO_SOCKLEN_T
/* #undef HAVE_NO_VSNPRINTF */
#define HAVE_OCC
#define HAVE_OPENGL
/* #undef HAVE_OSMESA */
#define HAVE_PARSER
#define HAVE_PETSC
#define HAVE_PLUGINS
#define HAVE_POST
/* #undef HAVE_QT */
/* #undef HAVE_READLINE */
#define HAVE_SLEPC
#define HAVE_SOLVER
/* #undef HAVE_TAUCS */
#define HAVE_TETGEN

#define GMSH_CONFIG_OPTIONS " Ann Bamg Blas Chaco DIntegration FlTree Fltk Gmm Jpeg(Fltk) Kbipack Lapack Lua MathEx Med Mesh Metis Mpeg NativeFileChooser Netgen NoSocklenT OpenCascade OpenGL PETSc Parser Plugins Png(Fltk) Post SLEPc Solver Tetgen Zlib(Fltk)"



#endif

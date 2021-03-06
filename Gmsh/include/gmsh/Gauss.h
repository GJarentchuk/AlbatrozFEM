// Gmsh - Copyright (C) 1997-2010 C. Geuzaine, J.-F. Remacle
//
// See the LICENSE.txt file for license information. Please report all
// bugs and problems to <gmsh@geuz.org>.

#ifndef _GAUSS_H_
#define _GAUSS_H_

#include "fullMatrix.h"

struct IntPt{
  double pt[3];
  double weight;
};

int GaussLegendreTri(int n1, int n2, IntPt *pts);
int GaussLegendreTet(int n1, int n2, int n3, IntPt *pts); 
int GaussLegendreHex(int n1, int n2, int n3, IntPt *pts);
int GaussLegendrePri(int n1, int n2, int n3, IntPt *pts); 

int getNGQLPts (int order);
IntPt *getGQLPts (int order);

int getNGQTPts(int order);
IntPt *getGQTPts (int order);

int getNGQQPts(int order);
IntPt *getGQQPts(int order);

int getNGQTetPts(int order);
IntPt *getGQTetPts(int order);

int getNGQPriPts(int order);
IntPt *getGQPriPts(int order);

int getNGQHPts(int order);
IntPt *getGQHPts(int order);

//For now this class is only for bindings but maybe the interface is
//cleaner (it does not add new types) and it can replace the other
//interface
class gaussIntegration {
  public:
  static void getTriangle(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void getLine(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void getQuad(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void getTetrahedron(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void getHexahedron(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void getPrism(int order, fullMatrix<double> &pts, fullMatrix<double> &weights);
  static void registerBindings(binding *b);
};

#endif

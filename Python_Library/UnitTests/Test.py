import sys
import logging
import time
sys.path.append('C:\\Users\\khanh\\Desktop\\Workspace\\\Multi-Unicycle-Coverage-Control\\Python_Library')
from VoronoiLib import *
from controlAlgo import *


from sympy.integrals.intpoly import *
poly = Polygon((800.000000, 300.000000),(363.806815, 38.284089),(194.428556, 164.098432),(151.089060, 451.089060),(300.000000, 600.000000))
mVi = polytope_integrate(poly, 1)

SCALE = 50
boundaryCoeff = np.array([[-1 , 0, 0 ],
                        [0 , -1, 0 ],
                        [-1 , 1, 6 * SCALE ],
                        [0.6, 1, 15.6 * SCALE ],
                        [0.6, -1, 3.6 * SCALE ]])
thisCoord_2d = np.array([267.33906212, 209.55707012])
thisCVT_2d = np.array([410.04544520, 314.25357909])

adjCoord_2d = np.array([171.96908813, 81.16471269])
adjCVT_2d =  np.array([229.82786564, 64.04548757] )
vertex1_2d = np.array([194.42855637, 164.09843246])
vertex2_2d = np.array([363.80681520, 38.28408912])

import time

tic = time.time_ns()
dCi_dzi_AdjacentJ, dCi_dzj = Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
print("dCi_dzi_AdjacentJ", dCi_dzi_AdjacentJ)
print("dCi_dzj", dCi_dzj) 
toc = time.time_ns()
print(tic, toc, toc - tic)


dCi_dzi_AdjacentJ_list = []

myAgent = vorPrivateData()
myAgent.C = thisCVT_2d
myAgent.z = thisCoord_2d
myAgent.dCi_dzi = dCi_dzi_AdjacentJ

# Adding new neighbors
neighAgent = vorNeighborData()
neighAgent.C = adjCVT_2d
neighAgent.z = adjCoord_2d
neighAgent.dCj_dzi = dCi_dzj
dCi_dzi_AdjacentJ_list.append(dCi_dzj)


controlParam = controlParameter()
controlParam.eps = 5
controlParam.gain = 3
controlParam.P = 3
controlParam.Q_2x2 = 5 * np.identity(2)

[Vi, dVidzi, dVidzj_Arr] = Voronoi2D_cal_dV_dz(myAgent, dCi_dzi_AdjacentJ_list, boundaryCoeff, controlParam)
print([Vi, dVidzi, dVidzj_Arr])


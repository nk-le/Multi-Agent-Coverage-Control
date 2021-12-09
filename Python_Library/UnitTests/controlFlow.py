import sys
import logging
import time
sys.path.append('C:\\Users\\khanh\\Desktop\\Workspace\\\Multi-Unicycle-Coverage-Control\\Python_Library')
from VoronoiLib import *
from controlAlgo import *
from sympy.integrals.intpoly import *

## World parameter - declare once
SCALE = 50
boundaryCoeff = np.array([[-1 , 0, 0 ],
                        [0 , -1, 0 ],
                        [-1 , 1, 6 * SCALE ],
                        [0.6, 1, 15.6 * SCALE ],
                        [0.6, -1, 3.6 * SCALE ]])
poly = Polygon((800.000000, 300.000000),(363.806815, 38.284089),(194.428556, 164.098432),(151.089060, 451.089060),(300.000000, 600.000000))
mVi = polytope_integrate(poly, 1)
controlParam = controlParameter()
controlParam.eps = 5
controlParam.gain = 3
controlParam.P = 3
controlParam.Q_2x2 = 5 * np.identity(2)

# My info
myAgent = vorPrivateData()
thisCoord_2d = np.array([267.33906212, 209.55707012])
thisCVT_2d = np.array([410.04544520, 314.25357909])
myAgent.C = thisCVT_2d
myAgent.z = thisCoord_2d
myAgent.dCi_dzi = 0
dCi_dzj_list = []
dCj_dzi_list = []

# Adding new neighbors
neighAgent1 = vorNeighborData()
adjCoord_2d = np.array([171.96908813, 81.16471269])
adjCVT_2d =  np.array([229.82786564, 64.04548757] )
vertex1_2d = np.array([194.42855637, 164.09843246])
vertex2_2d = np.array([363.80681520, 38.28408912])
neighAgent1.C = adjCVT_2d
neighAgent1.z = adjCoord_2d
dCi_dzi_AdjacentJ, dCi_dzj = Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
myAgent.dCi_dzi += dCi_dzi_AdjacentJ
dCi_dzj_list.append(dCi_dzj)
dCj_dzi_list.append(np.array([[-0.17206108, 0.41213731], [0.07749889, 0.15671052]]))


neighAgent2 = vorNeighborData()
adjCoord_2d = np.array([111.34574850, 185.99995350])
adjCVT_2d =  np.array([99.01992217, 266.48174406])
vertex1_2d = np.array([194.42855637, 164.09843246])
vertex2_2d = np.array([151.08905982, 451.08905982])
neighAgent2.C = adjCVT_2d
neighAgent2.z = adjCoord_2d
dCi_dzi_AdjacentJ, dCi_dzj = Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
myAgent.dCi_dzi += dCi_dzi_AdjacentJ
dCi_dzj_list.append(dCi_dzj)
dCj_dzi_list.append(np.array([[0.31357862, -0.28482718], [ 0.22651851, -0.50107141]]))

[Vi, dVidzi, dVidzj_Arr] = Voronoi2D_cal_dV_dz(myAgent, dCi_dzj_list, boundaryCoeff, controlParam)

print("Vi", Vi)
print("dVidzi", dVidzi)
print("dVidzj_Arr", dVidzj_Arr)

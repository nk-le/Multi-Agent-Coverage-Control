import sys
import logging
import time
sys.path.append('C:\\Users\\khanh\\Desktop\\Workspace\\\Multi-Unicycle-Coverage-Control\\Python_Library')
from VoronoiLib import *

print("Hello World")

thisCoord_2d = [0, 0]
thisCVT_2d = [2,1]
mVi = 1
adjCoord_2d = [44, 1]
vertex1_2d = [1,3]
vertex2_2d = [44, 2]

import time

tic = time.time_ns()
dCi_dzi_AdjacentJ, dCi_dzj = Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
dCi_dzi_AdjacentJ.print()
dCi_dzj.print() 
toc = time.time_ns()
print(tic, toc, toc - tic)


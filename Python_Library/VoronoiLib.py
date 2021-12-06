import math
import numpy as np
import scipy.integrate as integrate

class dC_dz:
    dCx_dzx = 0
    dCx_dzy = 0 
    dCy_dzx = 0 
    dCy_dzy = 0


def dq__dZix_n_func(qX, ziX, dZiZj):
    return (qX - ziX) / dZiZj

def dq__dZiy_n_func(qY, ziY, dZiZj):
    return (qY - ziY) / dZiZj

def dq__dZjx_n_func(qX, zjX, dZiZj):
    return (zjX - qX) / dZiZj

def dq__dZjy_n_func(qY, zjY, dZiZj):
    return (zjY - qY) / dZiZj;    

# Integration parameter: t: 0 -> 1
def XtoT_func(t, v1x, v2x):
    return v1x + (v2x - v1x)* t

def YtoT_func(t, v1y, v2y):
    return v1y + (v2y - v1y)* t


def dCix_dzix_func(t, v1x, v2x, ziX, dZiZj, dqTodtParam):
    return XtoT_func(t,v1x,v2x) * dq__dZix_n_func(XtoT_func(t,v1x,v2x), ziX, dZiZj) * dqTodtParam

def dCiy_dzix_func(t, v1x, v2x, v1y, v2y, ziX, dZiZj, dqTodtParam):
    return YtoT_func(t,v1y,v2y) * dq__dZix_n_func(XtoT_func(t,v1x,v2x), ziX, dZiZj) * dqTodtParam
 


def Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d):
    # Function definition for partial derivative
    distanceZiZj = math.sqrt((thisCoord_2d[0] - adjCoord_2d[0])**2 + (thisCoord_2d[1] - adjCoord_2d[1])**2)
   
    # Factorization of dq = param * dt for line integration
    v1x = vertex1_2d[0]
    v2x = vertex2_2d[0]
    v1y = vertex1_2d[1]
    v2y = vertex2_2d[1]
    dqTodtParam = math.sqrt((v2x - v1x)**2 + (v2y - v1y)**2)  

    # dCi_dzix
    dCi_dzix_secondTermInt = integrate.quad(lambda t: dq__dZix_n_func(XtoT_func(t,v1x, v2x), thisCoord_2d[0], distanceZiZj) * dqTodtParam , 0, 1)
    dCix_dzix_firstTermInt = integrate.quad(dCix_dzix_func, 0, 1, args = (v1x, v2x, thisCoord_2d[0], distanceZiZj, dqTodtParam))
    dCiy_dzix_firstTermInt = integrate.quad(dCiy_dzix_func, 0, 1, args = (v1x, v2x, v1y, v2y, thisCoord_2d[0], distanceZiZj, dqTodtParam))
    dCix_dzix = (dCix_dzix_firstTermInt[0] - dCi_dzix_secondTermInt[0] * thisCVT_2d[0])/ mVi
    dCiy_dzix = (dCiy_dzix_firstTermInt[0] - dCi_dzix_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # dCi_dziy
    dCi_dziy_secondTermInt = integrate.quad(lambda t: dq__dZiy_n_func(YtoT_func(t, v1y, v2y), thisCoord_2d[1], distanceZiZj) * dqTodtParam , 0, 1)
    dCix_dziy = (integrate.quad(lambda t: XtoT_func(t,v1x,v2x) * dq__dZiy_n_func(YtoT_func(t,v1y,v2y), thisCoord_2d[1], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dziy_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dziy = (integrate.quad(lambda t: YtoT_func(t,v1y,v2y) * dq__dZiy_n_func(YtoT_func(t,v1y,v2y), thisCoord_2d[1], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dziy_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # dCi_dzjx
    dCi_dzjx_secondTermInt = integrate.quad(lambda t: dq__dZjx_n_func(XtoT_func(t,v1x, v2x), adjCoord_2d[0], distanceZiZj) * dqTodtParam , 0, 1 )
    dCix_dzjx = (integrate.quad(lambda t: XtoT_func(t,v1x,v2x) * dq__dZjx_n_func(XtoT_func(t,v1x,v2x), adjCoord_2d[0], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dzjx = (integrate.quad(lambda t: YtoT_func(t,v1y,v2y) * dq__dZjx_n_func(XtoT_func(t,v1x,v2x), adjCoord_2d[0], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # dCi_dzjy
    dCi_dzjy_secondTermInt = integrate.quad(lambda t: dq__dZjy_n_func(YtoT_func(t, v1y, v2y), adjCoord_2d[1], distanceZiZj) * dqTodtParam , 0, 1 )
    dCix_dzjy =  (integrate.quad(lambda t: XtoT_func(t,v1x,v2x) * dq__dZjy_n_func(YtoT_func(t,v1y,v2y), adjCoord_2d[1], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dzjy =  (integrate.quad(lambda t: YtoT_func(t,v1y,v2y) * dq__dZjy_n_func(YtoT_func(t,v1y,v2y), adjCoord_2d[1], distanceZiZj) * dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # Return
    dCi_dzi_AdjacentJ = dC_dz()
    dCi_dzi_AdjacentJ.dCx_dzx = dCix_dzix
    dCi_dzi_AdjacentJ.dCx_dzy = dCix_dziy
    dCi_dzi_AdjacentJ.dCy_dzx = dCiy_dzix
    dCi_dzi_AdjacentJ.dCy_dzy = dCiy_dziy

    dCi_dzj = dC_dz()
    dCi_dzj.dCx_dzx = dCix_dzjx
    dCi_dzj.dCx_dzy = dCix_dzjy
    dCi_dzj.dCy_dzx = dCiy_dzjx
    dCi_dzj.dCy_dzy = dCiy_dzjy

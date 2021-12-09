import math
import numpy as np
import scipy.integrate as integrate

class grad_2d:
    dx_dx = 0
    dx_dy = 0 
    dy_dx = 0 
    dy_dy = 0

    def __init__(self, mat2x2):
        self.dx_dx = mat2x2[0,0]
        self.dx_dy = mat2x2[0,1]
        self.dy_dx = mat2x2[1,0]
        self.dy_dy = mat2x2[1,1]
        pass

   
    def npForm(self):
        return np.array([[self.dx_dx, self.dx_dy],
                        [self.dy_dx, self.dy_dy]])

    def __call__(self):
        return np.array([[self.dx_dx, self.dx_dy],
                        [self.dy_dx, self.dy_dy]])

    def print(self):
        print("dCx_dzx", self.dx_dx, "dCx_dzy", self.dx_dy, "dCy_dzx", self.dy_dx, "dCy_dzy", self.dy_dy)

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

def dCix_dziy_func(t, v1x, v2x, v1y, v2y, ziY, dZiZj, dqTodtParam):
    return XtoT_func(t,v1x,v2x) * dq__dZiy_n_func(YtoT_func(t,v1y,v2y), ziY, dZiZj) * dqTodtParam

def dCiy_dziy_func(t, v1y, v2y, ziY, dZiZj, dqTodtParam):
    return YtoT_func(t,v1y,v2y) * dq__dZiy_n_func(YtoT_func(t,v1y,v2y), ziY, dZiZj) * dqTodtParam
  
def dCix_dzjx_func(t, v1x, v2x, zjx, dZiZj, dqTodtParam):
    return XtoT_func(t,v1x,v2x) * dq__dZjx_n_func(XtoT_func(t,v1x,v2x), zjx, dZiZj) * dqTodtParam

def dCiy_dzjx_func(t, v1x, v2x, v1y, v2y, zjx, dZiZj, dqTodtParam):
    return YtoT_func(t,v1y,v2y) * dq__dZjx_n_func(XtoT_func(t,v1x,v2x), zjx, dZiZj) * dqTodtParam

def dCix_dzjy_func(t, v1x, v2x, v1y, v2y, zjy, dZiZj, dqTodtParam):
    return XtoT_func(t,v1x,v2x) * dq__dZjy_n_func(YtoT_func(t,v1y,v2y), zjy, dZiZj) * dqTodtParam

def dCiy_dzjy_func(t, v1y, v2y, zjy, dZiZj, dqTodtParam):
    return YtoT_func(t,v1y,v2y) * dq__dZjy_n_func(YtoT_func(t,v1y,v2y), zjy, dZiZj) * dqTodtParam

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
    dCiy_dzix = (dCiy_dzix_firstTermInt[0] - dCi_dzix_secondTermInt[0] * thisCVT_2d[1])/ mVi
    
    # dCi_dziy
    dCi_dziy_secondTermInt = integrate.quad(lambda t: dq__dZiy_n_func(YtoT_func(t, v1y, v2y), thisCoord_2d[1], distanceZiZj) * dqTodtParam , 0, 1)
    dCix_dziy_firstTermInt = integrate.quad(dCix_dziy_func, 0, 1, args = (v1x, v2x, v1y, v2y, thisCoord_2d[1], distanceZiZj, dqTodtParam))
    dCiy_dziy_firstTermInt = integrate.quad(dCiy_dziy_func, 0, 1, args = (v1y, v2y, thisCoord_2d[1], distanceZiZj, dqTodtParam))
    dCix_dziy = (dCix_dziy_firstTermInt[0] - dCi_dziy_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dziy = (dCiy_dziy_firstTermInt[0] - dCi_dziy_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # dCi_dzjx
    dCi_dzjx_secondTermInt = integrate.quad(lambda t: dq__dZjx_n_func(XtoT_func(t,v1x, v2x), adjCoord_2d[0], distanceZiZj) * dqTodtParam , 0, 1 )
    dCix_dzjx_firstTermInt = integrate.quad(dCix_dzjx_func , 0, 1, args = (v1x, v2x, adjCoord_2d[0], distanceZiZj, dqTodtParam))
    dCiy_dzjx_firstTermInt = integrate.quad(dCiy_dzjx_func , 0, 1, args = (v1x, v2x, v1y, v2y, adjCoord_2d[0], distanceZiZj, dqTodtParam)) 
    dCix_dzjx = (dCix_dzjx_firstTermInt[0] - dCi_dzjx_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dzjx = (dCiy_dzjx_firstTermInt[0] - dCi_dzjx_secondTermInt[0] * thisCVT_2d[1]) / mVi

    # dCi_dzjy
    dCi_dzjy_secondTermInt = integrate.quad(lambda t: dq__dZjy_n_func(YtoT_func(t, v1y, v2y), adjCoord_2d[1], distanceZiZj) * dqTodtParam , 0, 1 )
    dCix_dzjy_firstTermInt =  integrate.quad(dCix_dzjy_func , 0, 1, args = (v1x, v2x, v1y, v2y, adjCoord_2d[1], distanceZiZj, dqTodtParam)) 
    dCiy_dzjy_firstTermInt =  integrate.quad(dCiy_dzjy_func , 0, 1, args = (v1y, v2y, adjCoord_2d[1], distanceZiZj, dqTodtParam)) 
    dCix_dzjy = (dCix_dzjy_firstTermInt[0] - dCi_dzjy_secondTermInt[0] * thisCVT_2d[0]) / mVi
    dCiy_dzjy = (dCiy_dzjy_firstTermInt[0] - dCi_dzjy_secondTermInt[0] * thisCVT_2d[1]) / mVi
    
    # Return
    dCi_dzi_AdjacentJ = np.array([[dCix_dzix, dCix_dziy], [dCiy_dzix, dCiy_dziy]])
    dCi_dzj = np.array([[dCix_dzjx, dCix_dzjy], [dCiy_dzjx, dCiy_dzjy]])
    
    return [dCi_dzi_AdjacentJ, dCi_dzj]
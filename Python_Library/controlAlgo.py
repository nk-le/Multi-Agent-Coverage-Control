from VoronoiLib import *

class vorAgentData:
    C = np.array([0, 0])
    z = np.array([0, 0])

class vorPrivateData(vorAgentData):
    dCi_dzi = grad_2d(np.array([[0, 0], [0, 0]]))

class vorNeighborData(vorAgentData):
    dCj_dzi = grad_2d(np.array([[0, 0], [0, 0]]))
    

class controlParameter:
    eps = 0
    P = 1
    Q_2x2 = np.array([[0, 0], [0, 0]])
    gain = 1

def Voronoi2D_cal_dV_dz(vorPrivateData, dCjdzi_Arr, boundaryCoeff, controlParameter):
    nNeighbor = len(dCjdzi_Arr)
    numCoeff = len(boundaryCoeff)
    # Update the Lyapunov state 
    # One shot computation before scanning over the adjacent matrix
    Ci = vorPrivateData.C
    zi = vorPrivateData.z
    sum_1_div_Hj = 0
    sum_aj_2HjSquared = np.array([0, 0])
    for j in range(numCoeff):
        hj = (boundaryCoeff[j,2]- (boundaryCoeff[j,0]*zi [0] + boundaryCoeff[j,1]*zi [1])) 
        sum_1_div_Hj = sum_1_div_Hj + 1/hj
        sum_aj_2HjSquared = sum_aj_2HjSquared + np.array([boundaryCoeff[j,0], boundaryCoeff[j,1]]) / hj**2 / 2; 
    
    # Matrix computation here
    Q_zDiff_div_hj = np.matmul(controlParameter.Q_2x2, (zi - Ci)) * sum_1_div_Hj
        
    # Compute the Partial dVi_dzi of itself
    dCi_dzi = vorPrivateData.dCi_dzi
    Vi = np.matmul(np.matmul(np.transpose(zi - Ci), controlParameter.Q_2x2), (zi - Ci)) * sum_1_div_Hj / 2
    # If Vi <= 0, the state constraint is already violated. Assert
    assert(Vi >= 0)
    
    dVidzi = (np.identity(2) - np.transpose(dCi_dzi)).dot(Q_zDiff_div_hj)\
            + sum_aj_2HjSquared * ((np.transpose(zi - Ci)).dot(controlParameter.Q_2x2).dot(zi - Ci))

    # Scan over the adjacent list and compute the corresponding partial derivative
    dVidzj_Arr = []
    for friendID in range(nNeighbor):
        dCjdzi = dCjdzi_Arr[friendID]
        print(friendID, "dCjdzi", dCjdzi)
        tmp = -np.transpose(dCjdzi).dot(Q_zDiff_div_hj)
        print("tmp", tmp)
        dVidzj_Arr.append(-np.transpose(dCjdzi).dot(Q_zDiff_div_hj))
       
    return [Vi, dVidzi, dVidzj_Arr]        
        
def compute_Lyapunov(dVidzi, dVjdzi_Arr):
    # Compute the Lyapunov partial derivative for each agents
    # Initialize the Lyapunov Gradient of itself
    sumdV_dzi = dVidzi
    for friendID in range(len(dVjdzi_Arr)):
        sumdV_dzi += dVjdzi_Arr[friendID]
    return sumdV_dzi
  
def compute_Control_Input(w0, theta, dV_dzi, controlParameter):
    # Compute the control output
    # Adjustable variable
    sigmoid_func = lambda x,eps:  x / (abs(x) + eps);  
    # Compute the control policy
    return w0 + controlParameter.P * w0 * sigmoid_func(dV_dzi[0] * math.cos(theta) + dV_dzi[1] * math.sin(theta), controlParameter.eps); 



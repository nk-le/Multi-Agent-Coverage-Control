classdef ControlParameter < handle
     properties
        V_CONST = 40;
        W_ORBIT = 0.8;
        Q2x2 = 5 * eye(2);
        P = 3;
        EPS_SIGMOID = 5
        W_LIMIT = 1.6;
    end
    
end


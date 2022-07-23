classdef ControlParameterBLF < ControlParameter
    properties  (SetAccess = immutable)
        V_CONST     % Constant heading velocity
        W_ORBIT     % Orbital (desired angular) velocity
        Q_2x2       % Q Norm _ Positive definit
        P           % Control Gain
    end
    
    methods
        function obj = Control_Parameter_Constraint_Lyapunov(i_V_CONST, i_W_ORBIT, i_Q_2x2, i_P)
           obj.V_CONST = i_V_CONST;
           obj.W_ORBIT = i_W_ORBIT;
           obj.Q_2x2 = i_Q_2x2;
           obj.P = i_P;
        end        
    end
end


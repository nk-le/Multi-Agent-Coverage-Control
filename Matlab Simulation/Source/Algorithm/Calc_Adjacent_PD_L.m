function [dVidzk] = Calc_Adjacent_PD_L(i_zi_2x1, i_Ci_2x1, i_dCi_dzk_2x2 , i_Q_2x2, i_aj_nx2, i_bj_n)
    %Computation of the partial derivative of th edesigned Lyapunov
    %function
    %% Assertion
    
    %% Computation
    hij_func = @(zi_2x1, aj_2x1, bj_1) bj_1 - aj_2x1' * zi_2x1;

    
    dVidzk = zeros(2,1);
    for j = 1: size(i_bj_n) 
        dVidzk = dVidzk + (-i_dCi_dzk_2x2' * i_Q_2x2 * (i_zi_2x1 - i_Ci_2x1)) / hij_func(i_zi_2x1, i_aj_nx2(j,:)', i_bj_n(j));
    end 
end


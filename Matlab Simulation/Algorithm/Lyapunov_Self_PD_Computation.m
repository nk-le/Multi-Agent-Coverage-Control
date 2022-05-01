function [Vk, dVkdzk] = Lyapunov_Self_PD_Computation(i_zk_2x1, i_Ck_2x1, i_dCk_dzk_2x2 , i_Q_2x2, i_aj_nx2, i_bj_n)
    %% Assertion
    

    %% Computation
    normQ_func = @(vec2x1, Q2x2) sqrt(vec2x1' * Q2x2 * vec2x1);
    hkj_func = @(zk_2x1, aj_2x1, bj_1) bj_1 - aj_2x1' * zk_2x1;
    Vj_k_func = @(zk_2x1, Ck_2x1, Q, hj_k) normQ_func(zk_2x1 - Ck_2x1, Q)^2 / hj_k / 2;
    Vk = 0;
    dVkdzk = zeros(2,1);
    
    for j = 1: size(i_bj_n)
        hj_k = hkj_func(i_zk_2x1, i_aj_nx2(j,:)', i_bj_n(j));
        assert(hj_k >= 0);
        Vj_k = Vj_k_func(i_zk_2x1, i_Ck_2x1, i_Q_2x2, hj_k);
        Vk = Vk + Vj_k;
        dVkdzk = dVkdzk + ((eye(2) - i_dCk_dzk_2x2') * i_Q_2x2 * (i_zk_2x1 - i_Ck_2x1) + i_aj_nx2(j,:)' * Vj_k) / hj_k;
    end    
end


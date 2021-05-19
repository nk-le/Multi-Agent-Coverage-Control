function [uk] = Compute_BLF_Controller(muk, thetak, w0, zk, Ck, listZi, listVertexesVk, worldBoundaryParameter)
    zkHeading = [cos(thetak) ; sin(thetak)];
    sum_gradVi = Compute_dVi_dz(zk, Ck, listZi, listVertexesVk, worldBoundaryParameter);
    uk = w0 + muk * sign(w0) * (sum_gradVi' * zkHeading) / norm(sum_gradVi' * zkHeading);
end


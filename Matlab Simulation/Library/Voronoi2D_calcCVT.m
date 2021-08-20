function [o_CVT_2d] = Voronoi2D_calcCVT(partitionVertexes)
    [cx,cy] = Function_PolyCentroid(partitionVertexes(:,1), partitionVertexes(:,2));
    o_CVT_2d = [cx, cy];
end


function [bndPara] = ComputePolygonParamter(pointVector)
    nPoints = size(pointVector,2);
    bndPara = zeros(nPoints,3);
    for i = 1: nPoints
        if i ~= 6
            startPoint = pointVector(i, :);
            endPoint = pointVector(i+1,:);
        else
            startPoint = pointVector(6, :);
            endPoint = pointVector(1,:);
        end
        if(startPoint(1) ~= endPoint(1))
            bndPara(i, 1) = (startPoint(2) - endPoint(2)) / (startPoint(1) - endPoint(1)); 
            b = startVy - a * startVx;
        else       
            a = 0;                                       % Recheck this thing !!!
            b = startVx;
        end
    end
end


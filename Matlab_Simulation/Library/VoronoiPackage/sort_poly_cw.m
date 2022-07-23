function [X, Y] = sort_poly_cw(x, y)
    % Compute the center of the polygon
    n = numel(x);
    cx = sum(x)/n;
    cy = sum(y)/n;
    angleList = zeros(n,1);
    for i = 1:numel(x)
        dx = x(i) - cx;
        dy = y(i) - cy;
        angle = atan2(dy,dx);
        if (angle < 0)
            angle = angle + 2 * pi;
        end
        angleList(i) = angle;	
    end
    [out,idSorted] = sort(angleList);
    X = x(idSorted);
    Y = y(idSorted);
end
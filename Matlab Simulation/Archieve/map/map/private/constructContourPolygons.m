function P = constructContourPolygons(L, xLimit, yLimit)
% Generate topologically consistent contour polygons from a line mapstruct
% array in which the lines are consistently ordered with uphill on the
% right when traversing vertex-to-vertex in the order given. L has fields X
% and Y. Return a polygon mapstruct array. As needed, close curves along
% the boundary of the rectangle defined by the intervals xLimit and yLimit.

% Copyright 2017-2020 The MathWorks, Inc.

    n = numel(L);
    switch(n)
        case 0
            xb = xLimit([1 1 2 2 1])';
            yb = yLimit([1 2 2 1 1])';
            P = polystruct(xb,yb);

        case 1
            P = [ ...
                lowestPolygon(L, xLimit, yLimit); ...
                uppermostPolygon(L, xLimit, yLimit) ...
                ];

        otherwise  % n > 1
            P = [ ...
                lowestPolygon(L, xLimit, yLimit); ...
                intermediatePolygons(L, xLimit, yLimit); ...
                uppermostPolygon(L, xLimit, yLimit) ...
                ];
    end
end


function P = lowestPolygon(L, xLimit, yLimit)
% Region below the lowest contour level. Assumes that L has at least one element.

    xp = flipud(L(1).X);
    yp = flipud(L(1).Y);
    [xp, yp] = map.internal.clip.closePolygonInRectangle(xp, yp, xLimit, yLimit);
    [x,y] = boundpoly(xp, yp, xLimit, yLimit);
    P = polystruct(x,y);
end


function P = uppermostPolygon(L, xLimit, yLimit)
% Region above the uppermost contour. Assumes that L has at least one element.
    xp = L(end).X;
    yp = L(end).Y;
    [xp, yp] = map.internal.clip.closePolygonInRectangle(xp, yp, xLimit, yLimit);
    [x,y] = boundpoly(xp, yp, xLimit, yLimit);
    P = polystruct(x,y);
end


function P = intermediatePolygons(L, xLimit, yLimit)
% Regions between the lowest and uppermost contours. Assumes that L has at
% least two elements.

    n = numel(L);
    P(n-1,1) = struct('Geometry',[],'BoundingBox',[],'X',[],'Y',[]);

    for k = 2:n
        xp = L(k-1).X;
        yp = L(k-1).Y;
        xk = L(k).X;
        yk = L(k).Y;

        % Concatenate the vertex lists from level k-1 with the reverse
        % of the vertex lists from level k, then close up to form polygon k.
        [xp, yp] = map.internal.clip.closePolygonInRectangle( ...
            [xp; NaN; flipud(xk)], [yp; NaN; flipud(yk)], xLimit, yLimit);

        % Even "intermediate" polygons can be unbounded.
        [x,y] = boundpoly(xp, yp, xLimit, yLimit);

        % Add this "difference" polygon to the mapstruct P.
        P(k-1) = polystruct(x,y);
    end
end


function [x,y] = boundpoly(xp, yp, xLimit, yLimit)
% Ensure that a polygon is bounded by enclosing it in the bounding
% rectangle (as defined by the limits), if necessary.

    if isBoundedPolygon(xp,yp)
        x = xp;
        y = yp;
    else
        % Enclose in bounding rectangle.
        xb = xLimit([1 1 2 2 1])';
        yb = yLimit([1 2 2 1 1])';
        x = [xb; NaN; xp];
        y = [yb; NaN; yp];
    end
end


function P = polystruct(x,y)
    bbox = [min(x) min(y); max(x) max(y)];
    P = struct('Geometry','polygon','BoundingBox',bbox,'X',x','Y',y');
end


function tf = isBoundedPolygon(x,y)
% Return true if the polygon defined by vectors x,y is bounded. By
% convention, this function assumes that the interior is on the right as we
% traverse the vertices in the order given. This is equivalent to using
% 'SolidBoundaryOrientation','cw' when constructing a polyshape. A polygon
% is bounded if it has a finite interior, which means a positive area in
% terms of polyshape. It also means that all points at infinity
% fall outside the polygon (although the isinterior method will say
% otherwise).

    % Construct a polyshape object, being specific about the vertex order
    % convention and suppressing the "simplify" step. The check the sign of
    % the value returned by the area method.
    w = warning('off','MATLAB:polyshape:boundary3Points');
    c = onCleanup(@() warning(w));
    p = polyshape(x,y,'SolidBoundaryOrientation','cw','Simplify',false);
    tf = (area(p) >= 0);
end

function [f, v] = poly2fv(x, y)
%POLY2FV Convert polygonal region to patch faces and vertices
%
%   [F, V] = POLY2FV(X, Y) converts the polygonal region represented by the
%   contours (X, Y) into a faces matrix, F, and a vertices matrix, V, that
%   can be used with the PATCH function to display the region. If the
%   polygon represented by X and Y has multiple parts, either the
%   NaN-separated vector format or the cell array format may be used. The
%   POLY2FV function creates triangular faces.
%
%   Most Mapping Toolbox functions adhere to the convention that individual
%   contours with clockwise-ordered vertices are external contours and
%   individual contours with counterclockwise-ordered vertices are internal
%   contours. Although the POLY2FV function ignores vertex order, you
%   should follow the convention when creating contours to ensure
%   consistency with other functions.
%
%   Example
%   -------
%   Display a rectangular region with two holes using a single patch
%   object.
%
%       % External contour, rectangle.
%       x1 = [0 0 6 6 0];
%       y1 = [0 3 3 0 0];
%      
%       % First hole contour, square.
%       x2 = [1 2 2 1 1];
%       y2 = [1 1 2 2 1];
%
%       % Second hole contour, triangle.
%       x3 = [4 5 4 4];
%       y3 = [1 1 2 1];
%
%       % Compute face and vertex matrices.
%       [f, v] = poly2fv({x1, x2, x3}, {y1, y2, y3});
%
%       % Display the patch.
%       patch('Faces',f,'Vertices',v,'FaceColor','r','EdgeColor','none');
%       axis off, axis equal
%
%   Note
%   ----
%   Some workflows with POLY2FV can be streamlined using the MATLAB
%   polyshape class and its triangulation and plot methods. For instance,
%   a plot similar to the one in the preceding example can be constructed
%   like this: plot(polyshape({x1, x2, x3}, {y1, y2, y3}))
%
%   See also ISPOLYCW, PATCH, POLY2CW, POLY2CCW, POLYSHAPE

% Copyright 2004-2018 The MathWorks, Inc.

if isempty(x)
   f = [];
   v = [];
   return;
end

if iscell(x)
    [x, y] = polyjoin(x,y);
else
    checkxy(x, y, mfilename, 'X', 'Y', 1, 2)
end

w = warning();
warning('off','MATLAB:polyshape:boundary3Points')
warning('off','MATLAB:polyshape:repairedBySimplify')
warning('off','MATLAB:polyshape:boolOperationFailed')
c = onCleanup(@() warning(w));
p = polyshape(x,y);
if p.NumRegions > 0
    tri = triangulation(p);
    v = tri.Points;
    f = tri.ConnectivityList;
else
    v = [];
    f = [];
end

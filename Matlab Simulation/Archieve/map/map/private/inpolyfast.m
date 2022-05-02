function q = inpolyfast(x, y, xv, yv)
%INPOLYFAST True for points inside a polygonal region.
%
%   Q = INPOLYFAST(X,Y,XV,YV) returns a matrix IN the size of X and Y.
%
% This function has the same behavior as INPOLYGON for points (X,Y) that
% are strictly inside or outside the polygonal region specified by the
% vertex arrays XV and YV, and it is much faster.  The result is
% indeterminate for points on edge.

% Copyright 2009-2013 The MathWorks, Inc.

% Convert NaN-separated vertex arrays to a constrained Delaunay
% triangulation.
dt = map.internal.triangulatePolygon(xv,yv);

% Obtain si, a column vector which si(k) equals the index of the simplex
% (triangle, in this case) containing the point x(k), y(k).  SI equals NaN
% for points outside the convex hull.
si = dt.pointLocation(x(:),y(:));

% Construct a preliminary version of the output array which is false for
% points outside the convex hull and true for all other points.
q = ~isnan(si);

% Obtain in, a logical array that equals true for each triangle that is
% within the polygonal region/Delaunay constraints and false for all other
% triangles.
in = dt.isInterior();

% Update the elements of q corresponding to points within the convex hull,
% changing the value from true to false for each point that is not also
% within the polygonal region defined by (xv, yv).
q(q) = in(si(q));

% Because x might not be column vector, ensure that q has the same size
% as x.
q = reshape(q,size(x));

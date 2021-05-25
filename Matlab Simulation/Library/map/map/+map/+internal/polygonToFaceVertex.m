function [faces, vertices] = polygonToFaceVertex(x,y)
%polygonToFaceVertex  Face-vertex decomposition of multipart polygon
%
%   Uses an implementation based on a constrained Delaunay triangulation.
%
%   See also POLY2FV

% Copyright 2009-2013 The MathWorks, Inc.

% Construct a constrained Delaunay triangulation.
dt = map.internal.triangulatePolygon(x,y);

% Get the vertices and faces.
vertices = dt.Points;
faces = dt.ConnectivityList;

% Discard faces that fall outside the polygon.
inside = dt.isInterior();
faces(~inside,:) = [];

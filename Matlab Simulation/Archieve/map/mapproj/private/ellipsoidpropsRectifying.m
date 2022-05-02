function [a, ecc, radius] = ellipsoidpropsRectifying(mstruct)
%ellipsoidpropsRectifying Semimajor axis, eccentricity, and rectifying radius from mstruct
%
%   [a, ecc, radius] = ellipsoidpropsRectifying(mstruct) returns the
%   semimajor axis a, eccentricity e, and rectifying radius corresponding to
%   the reference ellipsoid in the 'geoid' field of the map projection
%   structure mstruct.

% Copyright 2011 The MathWorks, Inc

[a, ecc] = ellipsoidprops(mstruct);
radius = rsphere('rectifying',[a ecc]);

function [a, ecc, radius] = ellipsoidpropsAuthalic(mstruct)
%ellipsoidpropsAuthalic Semimajor axis, eccentricity, and authalic radius from mstruct
%
%   [a, ecc, radius] = ellipsoidpropsAuthalic(mstruct) returns the
%   semimajor axis a, eccentricity e, and authalic radius corresponding to
%   the reference ellipsoid in the 'geoid' field of the map projection
%   structure mstruct.

% Copyright 2011 The MathWorks, Inc

[a, ecc] = ellipsoidprops(mstruct);
radius = rsphere('authalic',[a ecc]);

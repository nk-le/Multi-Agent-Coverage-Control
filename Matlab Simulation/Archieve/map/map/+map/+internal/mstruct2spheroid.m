function s = mstruct2spheroid(mstruct)
% Spheroid object equivalent to 'geoid' value of a map projection structure

% Copyright 2012 The MathWorks, Inc.

if isobject(mstruct.geoid)
    s = mstruct.geoid;
else
    ellipsoid = checkellipsoid(mstruct.geoid,'mstruct2spheroid','mstruct.geoid');
    s = oblateSpheroid;
    s.SemimajorAxis = ellipsoid(1);
    s.Eccentricity  = ellipsoid(2);
end

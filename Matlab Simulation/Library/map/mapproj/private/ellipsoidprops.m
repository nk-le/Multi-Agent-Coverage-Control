function [a, ecc] = ellipsoidprops(mstruct)
%ellipsoidprops Semimajor axis and eccentricity from mstruct
%
%   Given a map projection structure, mstruct, return the semimajor axis
%   and eccentricity of the reference ellipsoid.  Information on the
%   ellipsoid is stored in the 'geoid' field, either in a spheroid object
%   or in a 2-vector of the form [semimajor_axis, eccentricity], or
%   possibly as a scalar representing the semimajor axis only.

% Copyright 2011 The MathWorks, Inc.

spheroid = mstruct.geoid;
if isobject(spheroid)
    a   = spheroid.SemimajorAxis;
    ecc = spheroid.Eccentricity;
else
    a = spheroid(1);
    if isscalar(spheroid)
        ecc = 0;
    else
        ecc = spheroid(2);
    end
end

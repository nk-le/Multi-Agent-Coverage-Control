function rad=nm2rad(nm,sphere)
%NM2RAD Convert distance from nautical miles to radians
%
%   RAD = NM2RAD(NM) converts distances from nautical miles to radians as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (3440.065 nm), the mean radius of the Earth.
%
%   RAD = NM2RAD(NM,RADIUS) converts distances from nautical miles to
%   radians as measured along a great circle on a sphere having the
%   specified radius. RADIUS must be in units of nautical miles.
%
%   RAD = NM2RAD(NM,SPHERE) converts distances from nautical miles to
%   radians, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following:
%   'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also RAD2NM, NM2DEG, NM2KM, NM2SM.

% Copyright 1996-2017 The MathWorks, Inc.

km = nm2km(nm);

if nargin == 1
    rad = km2rad(km);
else
    if ~(ischar(sphere) || isStringScalar(sphere))
        sphere = nm2km(sphere);
    end
    rad = km2rad(km, sphere);
end

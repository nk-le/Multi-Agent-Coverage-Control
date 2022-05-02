function deg = nm2deg(nm,sphere)
%NM2DEG Convert distance from nautical miles to degrees
%
%   DEG = NM2DEG(NM) converts distances from nautical miles to degrees as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (3440.065 nm), the mean radius of the Earth.
%
%   DEG = NM2DEG(NM,RADIUS) converts distances from nautical miles to
%   degrees as measured along a great circle on a sphere having the
%   specified radius. RADIUS must be in units of nautical miles.
%
%   DEG = NM2DEG(NM,SPHERE) converts distances from nautical miles to
%   degrees, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following
%   strings: 'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also DEG2NM, NM2RAD, NM2KM, NM2SM.

% Copyright 1996-2015 The MathWorks, Inc.

if nargin == 1
    rad = nm2rad(nm);
else
    rad = nm2rad(nm, sphere);
end

deg = rad2deg(rad);

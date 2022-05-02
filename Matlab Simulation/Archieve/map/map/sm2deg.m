function deg = sm2deg(sm,sphere)
%SM2DEG Convert distance from statute miles to degrees
%
%   DEG = SM2DEG(SM) converts distances from statute miles to degrees as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (3958.748 sm), the mean radius of the Earth.
%
%   DEG = SM2DEG(SM,RADIUS) converts distances from statute miles to
%   degrees as measured along a great circle on a sphere having the
%   specified radius. RADIUS must be in units of statute miles.
%
%   DEG = SM2DEG(SM,SPHERE) converts distances from statute miles to
%   degrees, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following
%   strings: 'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also DEG2SM, SM2RAD, SM2NM, SM2KM.

% Copyright 1996-2015 The MathWorks, Inc.

if nargin == 1
    rad = sm2rad(sm);
else
    rad = sm2rad(sm, sphere);
end

deg = rad2deg(rad);

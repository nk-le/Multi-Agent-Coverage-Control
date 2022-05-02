function sm = rad2sm(rad,sphere)
%RAD2SM Convert distance from radians to statute miles
%
%   SM = RAD2SM(RAD) converts distances from radians to statute miles as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (3958.748 sm), the mean radius of the Earth.
%
%   SM = RAD2SM(RAD,RADIUS) converts distances from radians to statute
%   miles as measured along a great circle on a sphere having the specified
%   radius. RADIUS must be in units of statute miles.
%
%   SM = RAD2SM(RAD,SPHERE) converts distances from radians to statute
%   miles, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following:
%   'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also SM2RAD, RAD2DEG, RAD2KM, RAD2NM.

% Copyright 1996-2017 The MathWorks, Inc.

if nargin == 1
    km = rad2km(rad);
else
    if ~(ischar(sphere) || isStringScalar(sphere))
        sphere = sm2km(sphere);
    end
    km = rad2km(rad,sphere);
end

sm = km2sm(km);

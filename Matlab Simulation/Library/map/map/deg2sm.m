function sm = deg2sm(deg,sphere)
%DEG2SM Convert distance from degrees to statute miles
%
%   SM = DEG2SM(DEG) converts distances from degrees to statute miles as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (3958.748 sm), the mean radius of the Earth.
%
%   SM = DEG2SM(DEG,RADIUS) converts distances from degrees to statute
%   miles as measured along a great circle on a sphere having the specified
%   radius. RADIUS must be in units of statute miles.
%
%   SM = DEG2SM(DEG,SPHERE) converts distances from degrees to statute
%   miles, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following:
%   'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also SM2DEG, DEG2RAD, DEG2KM, DEG2NM.

% Copyright 1996-2017 The MathWorks, Inc.

rad = deg2rad(deg);

if nargin == 1
    sm = rad2sm(rad);
else
    sm = rad2sm(rad,sphere);
end

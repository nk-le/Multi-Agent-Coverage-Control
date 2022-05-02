function nm = deg2nm(deg,sphere)
%DEG2NM Convert distance from degrees to nautical miles
%
%   NM = DEG2NM(DEG) converts distances from degrees to nautical miles as
%   measured along a great circle on a sphere with a radius of 6371 km 
%   (3440.065 nm), the mean radius of the Earth.
%
%   NM = DEG2NM(DEG,RADIUS) converts distances from degrees to nautical
%   miles as measured along a great circle on a sphere having the specified
%   radius. RADIUS must be in units of nautical miles.
%
%   NM = DEG2NM(DEG,SPHERE) converts distances from degrees to nautical
%   miles, as measured along a great circle on a sphere approximating an
%   object in the Solar System.  SPHERE may be one of the following:
%   'sun', 'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter',
%   'saturn', 'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also NM2DEG, DEG2RAD, DEG2KM, DEG2SM.

% Copyright 1996-2017 The MathWorks, Inc.

rad = deg2rad(deg);

if nargin == 1
    nm = rad2nm(rad);
else
    nm = rad2nm(rad,sphere);
end

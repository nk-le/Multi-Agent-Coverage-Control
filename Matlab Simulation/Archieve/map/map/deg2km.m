function km = deg2km(deg,sphere)
%DEG2KM Convert distance from degrees to kilometers
%
%   KM = DEG2KM(DEG) converts distances from degrees to kilometers as
%   measured along a great circle on a sphere with a radius of 6371 km, the
%   mean radius of the Earth.
%
%   KM = DEG2KM(DEG,RADIUS) converts distances from degrees to kilometers
%   as measured along a great circle on a sphere having the specified
%   radius. RADIUS must be in units of kilometers.
%
%   KM = DEG2KM(DEG,SPHERE) converts distances from degrees to kilometers,
%   as measured along a great circle on a sphere approximating an object in
%   the Solar System.  SPHERE may be one of the following: 'sun',
%   'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn',
%   'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%   See also DEG2NM, DEG2RAD, DEG2SM, KM2DEG.

% Copyright 1996-2017 The MathWorks, Inc.

rad = deg2rad(deg);

if nargin == 1
    km = rad2km(rad);
else
    km = rad2km(rad,sphere);
end

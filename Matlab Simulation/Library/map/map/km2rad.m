function rad = km2rad(km,sphere)
%KM2RAD Convert distance from kilometers to radians
%
%   RAD = KM2RAD(KM) converts distances from kilometers to radians as
%   measured along a great circle on a sphere with a radius of 6371 km, the
%   mean radius of the Earth.
%
%   RAD = KM2RAD(KM,RADIUS) converts distances from kilometers to radians
%   as measured along a great circle on a sphere having the specified
%   radius. RADIUS must be in units of kilometers.
%
%   RAD = KM2RAD(KM,SPHERE) converts distances from kilometers to radians,
%   as measured along a great circle on a sphere approximating an object in
%   the Solar System.  SPHERE may be one of the following: 'sun',
%   'moon', 'mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn',
%   'uranus', 'neptune', or 'pluto', and is case-insensitive.
%
%  See also RAD2KM, KM2DEG, KM2NM, KM2SM.

% Copyright 1996-2017 The MathWorks, Inc.

if nargin == 1
    radius = earthRadius('km');
elseif nargin == 2 && (ischar(sphere) || isStringScalar(sphere))
    s = referenceSphere(sphere,'km');
    radius = s.Radius;
else
    radius = sphere;
end

rad = km / radius;

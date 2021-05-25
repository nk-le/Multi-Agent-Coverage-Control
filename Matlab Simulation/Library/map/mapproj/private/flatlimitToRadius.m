function radius = flatlimitToRadius(mstruct, auxiliaryLatitudeType)
%flatlimitToRadius Latitude frame limits to radius for azimuthal projection
%
%   Convert the 'flatlimit' field of the mstruct to the frame radius, in
%   radians, assuming an azimuthal projection. The frame radius is encoded
%   in flatlimit, as the second element. Account for ellipsoidal flattening
%   when working in a polar aspect, by ensuring that the latitude of the
%   bounding parallel exactly equals the polar latitude plus or minus the
%   specified radius. But in an oblique or equatorial aspect, work directly
%   on the auxiliary sphere. Note that when the radius is 90 degrees and
%   the aspect is equatorial, the frame will pass through the poles anyway,
%   because the auxiliary latitudes used in azimuthal projections (authalic
%   and conformal) coincide with geodetic latitude at the poles. (The
%   rectifying latitude does, too, but the equidistant azimuthal projection
%   is implemented on the sphere only, so rectifying latitude does not
%   appear in this context.)

% Copyright 2013 The MathWorks, Inc.

% Extract the latitude frame limits and convert to radians
flatlimit = toRadians(mstruct.angleunits, mstruct.flatlimit);

if mstruct.origin(1) == fromDegrees(mstruct.angleunits,90)
    % North polar aspect
    lat = pi/2 - max(flatlimit);
    lat = convertlat(mstruct.geoid, lat, ...
        'geodetic', auxiliaryLatitudeType, 'nocheck');
    radius = pi/2 - lat;    
elseif mstruct.origin(1) == fromDegrees(mstruct.angleunits,-90)
    % South polar aspect
    lat = max(flatlimit) - pi/2;
    lat = convertlat(mstruct.geoid, lat, ...
        'geodetic', auxiliaryLatitudeType, 'nocheck');
    radius = lat + pi/2;    
else
    % Oblique or equatorial aspect
    radius = max(flatlimit);
end

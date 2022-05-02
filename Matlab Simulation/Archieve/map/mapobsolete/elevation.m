function [elevationAngle, slantRange, azimuthAngle] = elevation( ...
    lat1, lon1, alt1, lat2, lon2, alt2, angleUnits, in8)
%ELEVATION Local vertical elevation angle, range, and azimuth
%
%   ELEVATION will be removed in a future release.  Use GEODETIC2AER instead.
%
%   The reference point comes second in the GEODETIC2AER argument list, and
%   the outputs are ordered differently.  The replacement pattern is:
%
%      [AZIMUTHANGLE, ELEVATIONANGLE, SLANTRANGE] = GEODETIC2AER( ...
%          LAT2, LON2, ALT2, LAT1, LON1, ALT1, SPHEROID, ...)
%
%   Unlike ELEVATION, GEODETIC2AER requires a spheroid input, and it must
%   be must be an oblateSpheroid, referenceEllipsoid, or referenceSphere
%   object, not a 2-by-1 ellipsoid vector.
%
%   You can use the following steps to convert an ellipsoid vector,
%   ELLIPSOID, to an oblateSpheroid object, SPHEROID:
% 
%        spheroid = oblateSpheroid;
%        spheroid.SemimajorAxis = ellipsoid(1);
%        spheroid.Eccentricity  = ellipsoid(2);
%
%   When ELEVATION is called with only 6 inputs, the GRS 80 reference
%   ellipsoid, in meters, is used by default.  To replace this usage,
%   use referenceEllipsoid('GRS80','meters') as the SPHEROID input for
%   GEODETIC2AER.
%
%   If an ANGLEUNITS input is included, it must follow the SPHEROID input
%   in the call to GEODETIC2AER, rather than preceding it.
%
%   ELEVATION can be called with a LENGTHUNITS value, but GEODETIC2AER
%   has no such input. Set the LengthUnit property of the input spheroid
%   to the desired value instead.  In this case a referenceEllipsoid or
%   referenceSphere object must be used (not an oblateSpheroid object).
%
%   [ELEVATIONANGLE, SLANTRANGE, AZIMUTHANGLE] = ELEVATION(LAT1, LON1, ...
%   ALT1, LAT2, LON2, ALT2) computes the elevation angle, slant range, and
%   azimuth angle of point 2 (with geodetic coordinates LAT2, LON2, and
%   ALT2) as viewed from point 1 (with geodetic coordinates LAT1, LON1, and
%   ALT1).  ALT1 and ALT2 are ellipsoidal heights.  The elevation angle is
%   the angle of the line of sight above the local horizontal at point 1.
%   The slant range is the three-dimensional Cartesian distance between
%   point 1 and point 2.  The azimuth is the angle from north to the
%   projection of the line of sight on the local horizontal. Angles are in
%   units of degrees, altitudes and distances are in meters. The figure of
%   the earth is the GRS 80 ellipsoid.
%
%   [...] = ELEVATION(LAT1,LON1, ALT1, LAT2, LON2, ALT2, ANGLEUNITS) uses
%   ANGLEUNITS to specify the units of the input and output
%   angles.  If omitted, 'degrees' is assumed.
%
%   [...] = ELEVATION(LAT1, LON1, ALT1, LAT2, LON2, ALT2, ANGLEUNITS,...
%   LENGTHUNITS) uses LENGTHUNITS to specify the altitude
%   and slant-range units.  If omitted, 'meters' is assumed.  Any units
%   recognized by UNITSRATIO may be used.
% 
%   [...] = ELEVATION(LAT1, LON1, ALT1, LAT2, LON2, ALT2, ANGLEUNITS,...
%   ELLIPSOID) uses the input ELLIPSOID to specify the ellipsoid.
%   ELLIPSOID is a reference ellipsoid (oblate spheroid) object, a
%   reference sphere object, or a vector of the form [semimajor_axis,
%   eccentricity]. If ELLIPSOID is supplied, the altitudes must be in the
%   same units as the semimajor axis and the slant range will be returned
%   in these units.  If ELLIPSOID is omitted, the GRS 80 reference
%   ellipsoid is used and distances are in meters unless otherwise
%   specified.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   The line-of-sight azimuth angles returned by ELEVATION will generally
%   differ slightly from the corresponding outputs of AZIMUTH and DISTANCE,
%   except for great-circle azimuths on a spherical earth. 
%
%   See also GEODETIC2AER, oblateSpheroid, referenceEllipsoid, referenceSphere

% Copyright 1999-2017 The MathWorks, Inc.

narginchk(6,8)

if nargin < 7
    angleUnits = 'degrees';
end

% assign ellipsoid/distance units
if nargin < 8
    spheroid = referenceEllipsoid('grs80','m');
else
    in8 = convertStringsToChars(in8);
    if ischar(in8)
        % in8 is the length unit string
        spheroid = referenceEllipsoid('grs80',in8);
    elseif isobject(in8)
        % in8 is a spheroid object
        spheroid = in8;
    else
        % in8 is an ellipsoid vector
        ellipsoid = checkellipsoid(in8,mfilename,'ELLIPSOID',8);
        spheroid = oblateSpheroid;
        spheroid.SemimajorAxis = ellipsoid(1);
        spheroid.Eccentricity  = ellipsoid(2);
    end
end

[azimuthAngle, elevationAngle, slantRange] = geodetic2aer( ...
    lat2, lon2, alt2, lat1, lon1, alt1, spheroid, angleUnits);

% The azimuth is undefined when point 1 is at a pole, so we choose a
% convention: 180 (or pi) at the north pole and 0 at the south pole. 
if map.geodesy.isDegree(angleUnits)
    azimuthAngle(lat1 >=  90) = 180;
    azimuthAngle(lat1 <= -90) =   0;
else
    azimuthAngle(lat1 >=  pi/2) = pi;
    azimuthAngle(lat1 <= -pi/2) =  0;
end

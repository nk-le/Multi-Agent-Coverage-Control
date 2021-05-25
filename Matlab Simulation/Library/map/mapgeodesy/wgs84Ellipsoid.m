function e = wgs84Ellipsoid(lengthUnit)
%wgs84Ellipsoid Reference ellipsoid for World Geodetic System 1984
%
%   E = wgs84Ellipsoid returns a referenceEllipsoid object representing the
%   World Geodetic System of 1984 (WGS 84) reference ellipsoid. The
%   semimajor axis and semiminor axis are expressed in meters.
%
%   E = wgs84Ellipsoid(LENGTHUNIT), where LENGTHUNIT is any unit accepted
%   by validateLengthUnit, returns a WGS 84 reference ellipsoid object in
%   which the semimajor axis and semiminor axis are expressed in the
%   specified unit.
%
%   This function provides a streamlined alternative to constructing a WGS
%   84 reference ellipsoid object via referenceEllipsoid.
%
%   Examples
%   --------
%   wgs84InMeters = wgs84Ellipsoid
%   wgs84InKilometers = wgs84Ellipsoid('km')
%
%   See also referenceEllipsoid.

% Copyright 2011-2020 The MathWorks, Inc.

%#codegen

coder.extrinsic('referenceEllipsoid')

persistent wgs84EllipsoidInMeters;
if isempty(wgs84EllipsoidInMeters)
    wgs84EllipsoidInMeters = coder.const(referenceEllipsoid('wgs84'));
end

e = wgs84EllipsoidInMeters;
if nargin > 0
    e.LengthUnit = validateLengthUnit(lengthUnit,mfilename,'LENGTHUNIT',1);
end
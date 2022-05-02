function phi = geocentric2geodeticLat(ecc, phi_g)
%GEOCENTRIC2GEODETICLAT  Convert geocentric to geodetic latitude
%
%   GEOCENTRIC2GEODETICLAT will be removed in a future release. Use
%   geodeticLatitudeFromGeocentric instead.
%
%   PHI = GEOCENTRIC2GEODETICLAT(ECC, PHI_G) converts an array of
%   geocentric latitude in radians, PHI_G, to geodetic latitude in
%   radians, PHI, on a reference ellipsoid with first eccentricity ECC.
%
%   See also geodeticLatitudeFromGeocentric

% Copyright 2006-2013 The MathWorks, Inc.

% Technical reference:
%    J. P. Snyder, "Map Projections - A Working Manual,"  US Geological
%    Survey Professional Paper 1395, US Government Printing Office,
%    Washington, DC, 1987, pp. 13-18.

phi = atan2( sin(phi_g), (1-ecc^2)*cos(phi_g) );

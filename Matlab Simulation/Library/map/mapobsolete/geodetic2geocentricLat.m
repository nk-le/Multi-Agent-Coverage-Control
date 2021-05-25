function phi_g = geodetic2geocentricLat(ecc, phi)
%GEODETIC2GEOCENTRICLAT  Convert geodetic to geocentric latitude
%
%   GEODETIC2GEOCENTRICLAT will be removed in a future release. Use
%   geocentricLatitude instead.
%
%   PHI_G = GEODETIC2GEOCENTRICLAT(ECC, PHI) converts an array of
%   geodetic latitude in radians, PHI, to geocentric latitude in
%   radians, PHI_G, on a reference ellipsoid with first eccentricity ECC.
%
%   See also geocentricLatitude

% Copyright 2006-2013 The MathWorks, Inc.

% Technical reference:
%    J. P. Snyder, "Map Projections - A Working Manual,"  US Geological
%    Survey Professional Paper 1395, US Government Printing Office,
%    Washington, DC, 1987, pp. 13-18.

phi_g = atan2( (1-ecc^2)*sin(phi), cos(phi) );

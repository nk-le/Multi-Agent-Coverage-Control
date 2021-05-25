function latout = geod2cen(varargin)
%GEOD2CEN  Convert geodetic latitude to geocentric latitude
%
%   GEOD2CEN will be removed in a future release. Use geocentricLatitude
%   instead.
%
%   lat = GEOD2CEN(lat0) converts from the geodetic latitude to the
%   geocentric latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2CEN(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2CEN(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = GEOD2CEN(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also geocentricLatitude

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2cen','GEOD2CEN','geocentricLatitude'))
latout = doLatitudeConversion(mfilename,'geodetic','geocentric',varargin{:});

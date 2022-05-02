function latout = cen2geod(varargin)
%CEN2GEOD  Convert geocentric latitude to geodetic latitude
%
%   CEN2GEOD will be removed in a future release. Use
%   geodeticLatitudeFromGeocentric instead.
%
%   lat = CEN2GEOD(lat0) converts from the geocentric latitude to the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = CEN2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = CEN2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = CEN2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also geodeticLatitudeFromGeocentric

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:cen2geod','CEN2GEOD', ...
    'geodeticLatitudeFromGeocentric'))
latout = doLatitudeConversion(mfilename,'geocentric','geodetic',varargin{:});

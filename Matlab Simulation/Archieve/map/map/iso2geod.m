function latout = iso2geod(varargin)
%ISO2GEOD  Convert isometric latitude to geodetic latitude
%
%   ISO2GEOD will be removed in a future release. Use
%   map.geodesy.IsometricLatitudeConverter instead.
%
%   lat = ISO2GEOD(lat0) computes the geodetic latitude given the isometric
%   latitude, using the GRS 80 reference elipsoid.
%
%   lat = ISO2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = ISO2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = ISO2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.IsometricLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:iso2geod','ISO2GEOD', ...
    'map.geodesy.IsometricLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'isometric','geodetic',varargin{:});

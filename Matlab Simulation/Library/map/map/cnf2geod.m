function latout = cnf2geod(varargin)
%CNF2GEOD  Convert conformal latitude to geodetic latitude
%
%   CNF2GEOD will be removed in a future release. Use
%   map.geodesy.ConformalLatitudeConverter instead.
%
%   lat = CNF2GEOD(lat0) converts from the conformal latitude to the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = CNF2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = CNF2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = CNF2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.ConformalLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:cnf2geod','CNF2GEOD', ...
    'map.geodesy.ConformalLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'conformal','geodetic',varargin{:});

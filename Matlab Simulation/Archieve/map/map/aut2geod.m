function latout = aut2geod(varargin)
%AUT2GEOD  Convert authalic latitude to geodetic latitude
%
%   AUT2GEOD will be removed in a future release. Use
%   map.geodesy.AuthalicLatitudeConverter instead.
%
%   lat = AUT2GEOD(lat0) converts from the authalic latitude to the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = AUT2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = AUT2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = AUT2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.AuthalicLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:aut2geod','AUT2GEOD', ...
    'map.geodesy.AuthalicLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'authalic','geodetic',varargin{:});

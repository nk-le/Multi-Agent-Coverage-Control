function latout = rec2geod(varargin)
%REC2GEOD  Convert rectifying latitude to geodetic latitude
%
%   REC2GEOD will be removed in a future release. Use
%   map.geodesy.RectifyingLatitudeConverter instead.
%
%   lat = REC2GEOD(lat0) converts from the rectifying latitude to the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = REC2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = REC2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = REC2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.RectifyingLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:rec2geod','REC2GEOD', ...
    'map.geodesy.RectifyingLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'rectifying','geodetic',varargin{:});

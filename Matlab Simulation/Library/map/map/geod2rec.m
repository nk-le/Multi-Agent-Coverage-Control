function latout = geod2rec(varargin)
%GEOD2REC  Convert geodetic latitude to rectifying latitude
%
%   GEOD2REC will be removed in a future release. Use
%   map.geodesy.RectifyingLatitudeConverter instead.
%
%   lat = GEOD2REC(lat0) converts from the geodetic latitude to the
%   rectifying latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2REC(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2REC(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = GEOD2REC(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.RectifyingLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2rec','GEOD2REC', ...
    'map.geodesy.RectifyingLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'geodetic','rectifying',varargin{:});

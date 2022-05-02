function latout = geod2aut(varargin)
%GEOD2AUT  Convert geodetic latitude to authalic latitude
%
%   GEOD2AUT will be removed in a future release. Use
%   map.geodesy.AuthalicLatitudeConverter instead.
%
%   lat = GEOD2AUT(lat0) converts from the geodetic latitude to the
%   authalic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2AUT(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2AUT(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed. If empty,
%   units of radians are assumed.
%
%   lat = GEOD2AUT(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.AuthalicLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2aut','GEOD2AUT', ...
    'map.geodesy.AuthalicLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'geodetic','authalic',varargin{:});

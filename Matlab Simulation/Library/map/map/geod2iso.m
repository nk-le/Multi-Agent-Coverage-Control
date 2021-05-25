function latout = geod2iso(varargin)
%GEOD2ISO  Convert geodetic latitude to isometric latitude
%
%   GEOD2ISO will be removed in a future release. Use
%   map.geodesy.IsometricLatitudeConverter instead.
%
%   lat = GEOD2ISO(lat0) computes the isometric latitude given the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2ISO(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2ISO(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = GEOD2ISO(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.IsometricLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2iso','GEOD2ISO', ...
    'map.geodesy.IsometricLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'geodetic','isometric',varargin{:});

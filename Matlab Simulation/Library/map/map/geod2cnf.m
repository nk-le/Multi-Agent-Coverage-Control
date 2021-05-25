function latout = geod2cnf(varargin)
%GEOD2CNF  Convert geodetic latitude to conformal latitude
%
%   GEOD2CNF will be removed in a future release. Use
%   map.geodesy.ConformalLatitudeConverter instead.
%
%   lat = GEOD2CNF(lat0) converts from the geodetic latitude to the
%   conformal latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2CNF(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2CNF(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = GEOD2CNF(lat0,ellipsoid,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also map.geodesy.ConformalLatitudeConverter

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2cnf','GEOD2CNF', ...
    'map.geodesy.ConformalLatitudeConverter'))
latout = doLatitudeConversion(mfilename,'geodetic','conformal',varargin{:});

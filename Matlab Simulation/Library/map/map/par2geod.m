function latout = par2geod(varargin)
%PAR2GEOD  Convert parametric latitude to geodetic latitude
%
%   PAR2GEOD will be removed in a future release. Use
%   geodeticLatitudeFromParametric instead.
%
%   lat = PAR2GEOD(lat0) converts from the parametric latitude to the
%   geodetic latitude, using the GRS 80 reference ellipsoid.
%
%   lat = PAR2GEOD(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = PAR2GEOD(lat0,'units') uses the units defined by the input
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = PAR2GEOD(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also geodeticLatitudeFromParametric

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:par2geod','PAR2GEOD', ...
    'geodeticLatitudeFromParametric'))
latout = doLatitudeConversion(mfilename,'parametric','geodetic',varargin{:});

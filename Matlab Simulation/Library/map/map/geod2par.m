function latout = geod2par(varargin)
%GEOD2PAR  Convert geodetic latitude to parametric latitude
%
%   GEOD2PAR will be removed in a future release. Use parametricLatitude
%   instead.
%
%   lat = GEOD2PAR(lat0) converts from the geodetic latitude to the
%   parametric latitude, using the GRS 80 reference ellipsoid.
%
%   lat = GEOD2PAR(lat0,ELLIPSOID) uses the ellipsoid defined by the input
%   ELLIPSOID, which can be a spheroid object or vector of the form
%   [semimajor_axis eccentricity].
%
%   lat = GEOD2PAR(lat0,'units') uses the units defined by the input 
%   'units'.  If omitted, default units of degrees are assumed.  If empty,
%   units of radians are assumed.
%
%   lat = GEOD2PAR(lat0,ELLIPSOID,'units') uses the ellipsoid and 'units'
%   definitions provided by the corresponding inputs.
%
%   See also parametricLatitude

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:geod2par','GEOD2PAR','parametricLatitude'))
latout = doLatitudeConversion(mfilename,'geodetic','parametric',varargin{:});

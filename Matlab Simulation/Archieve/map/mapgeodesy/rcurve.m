function r = rcurve(type,ellipsoid,lat,units)
%RCURVE  Ellipsoidal radii of curvature
%
%   R = RCURVE(ELLIPSOID,LAT) and R = RCURVE('parallel',ELLIPSOID,LAT)
%   return the parallel radius of curvature at the latitude LAT for a
%   reference ellipsoid defined by ELLIPSOID.  ELLIPSOID is a reference
%   ellipsoid (oblate spheroid) object, a reference sphere object, or a
%   vector of the form [semimajor_axis, eccentricity].  R is the radius of
%   the small circle encompassing the ellipsoid at the given latitude. LAT
%   is in degrees. LAT is in degrees. R is in units of length consistent
%   with those used for the semimajor axis.
%
%   R = RCURVE('meridian',ELLIPSOID,LAT) returns the meridional radius of
%   curvature, which is the radius of curvature in the plane of a meridian,
%   at the latitude LAT.
%
%   R = RCURVE('transverse',ELLIPSOID,LAT) returns the transverse radius of
%   curvature, which is the radius of curvature in a plane normal to the
%   surface of the ellipsoid and normal to a meridian, at the latitude LAT.
%
%   R = RCURVE(...,ANGLEUNITS) specifies the units of the input LAT.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   See also RSPHERE.

% Copyright 1996-2019 The MathWorks, Inc.

% Reference: J.P. Snyder, Map Project -- A Working Manual, U.S. Geological
% Survey Professional Paper 1395, U.S. Government Printing Office, 1987,
% page 25 (equations 4-19, 4-20, 4-21).

if nargin > 0
    type = convertStringsToChars(type);
end

if nargin > 2
    lat = convertStringsToChars(lat);
end

if nargin > 3
    units = convertStringsToChars(units);
end

if nargin < 2 || (nargin == 2 && ischar(type))
    error(message('map:validate:invalidArgCount'))
    
elseif (nargin == 2 && ~ischar(type)) || (nargin == 3 && ischar(type))
    if ~ischar(type)
        % Shift inputs since str omitted by user
        lat = ellipsoid;
        ellipsoid = type;
        type = 'parallel';
    else
        type = validatestring(type,{'parallel','meridian','transverse'},1);
    end
	units = [];

elseif nargin == 3 && ~ischar(type)
    % Shift inputs since type was omitted by user
    units = lat;
    lat = ellipsoid;
    ellipsoid = type;
    type = 'parallel';
else % nargin > 3
    type = validatestring(type,{'parallel','meridian','transverse'},1);
end

if isempty(units)
    units = 'degrees';
else
    units = checkangleunits(units);
end
ellipsoid = map.geodesy.internal.validateEllipsoid(ellipsoid,'RCURVE','ELLIPSOID');

if strcmp(units,'degrees')
    validateattributes(lat,{'double','single'},...
        {'real','>=',-90,'<=',90},'RCURVE','LAT')
    lat = deg2rad(lat);
else
    validateattributes(lat,{'double','single'},...
        {'real','>=',-pi/2,'<=',pi/2},'RCURVE','LAT')
end

a   = ellipsoid(1);
ecc = ellipsoid(2);

switch type
    case 'parallel'
        
        % Parallel radius of curvature: Distance from the polar
        % axis to any point on the small circle at latitude LAT
        r = cos(lat) .* transverseROC(lat, a, ecc);
        
    case 'meridian'
        
        % Meridional radius of curvature
        r   = a * (1 - ecc^2) ./ sqrt((1 - (ecc * sin(lat)).^2).^3);
        
    case 'transverse'
        
        % Transverse radius of curvature
        r = transverseROC(lat, a, ecc);
        
end

%--------------------------------------------------------------------------

function N = transverseROC(lat, a, ecc)
% Transverse radius of curvature (radius of curvature in the prime meridian).

N = a ./ sqrt(1 - (ecc * sin(lat)).^2);

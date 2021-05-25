function v = geopeaks(varargin)
%GEOPEAKS Continuous and smooth function of latitude and longitude
%
%   Z = GEOPEAKS(LAT,LON)
%   Z = GEOPEAKS(R)
%   Z = GEOPEAKS(___,SPHEROID)
%
%   Z = GEOPEAKS(LAT,LON) evaluates a "peaks-like" function at specific
%   latitudes and longitudes on the surface of a sphere. The function is
%   continuous and smooth at all points, including the poles. Reminiscent
%   of the MATLAB PEAKS function, GEOPEAKS undulates gently between values
%   of -10 and 8, with about a half dozen local extrema.
%
%   Z = GEOPEAKS(R) evaluates the GEOPEAKS function at cell centers or
%   sample posting points defined by a geographic raster reference object.
%
%   Z = GEOPEAKS(___,SPHEROID) evaluates the function on a specific
%   spheroid. (The choice of spheroid makes very little difference; this
%   option is exists mainly to support formal testing.)
%
%   Example 1
%   ---------
%   % Sample geopeaks along the meridian that includes Paris, France
%   lon = dms2degrees([2 21 3]);
%   lat = -90:0.5:90;
%   z = geopeaks(lat, lon, wgs84Ellipsoid);
%   figure
%   plot(lat,z)
%
%   Example 2
%   ---------
%   % Construct a 181-by-361 global raster with samples posted at 1-degree
%   % spacing in both latitude and longitude, and display the results on a
%   % world map.
%   latlim = [-90 90];
%   lonlim = [-180 180];
%   sampleSpacing = 1;
%   R = georefpostings(latlim,lonlim,sampleSpacing,sampleSpacing)
%   Z = geopeaks(R);
%   figure
%   worldmap world
%   geoshow(Z,R,'DisplayType','surface','CData',Z,'ZData',zeros(size(Z)))
%   load coastlines
%   geoshow(coastlat,coastlon,'Color','k')
%   colorbar
%
%   Input Arguments
%   ---------------
%   LAT -- Geodetic latitude of one or more points, specified as a scalar
%     value, vector, or matrix. Values must be in degrees.
%     Data Types: single | double
%
%   LON -- Geodetic longitude of one or more points, specified as a scalar
%     value, vector, or matrix. Values must be in degrees.
%     Data Types: single | double
%
%   R -- Scalar geographic raster reference object.
%
%   SPHEROID -- Reference spheroid, specified as a scalar
%     referenceEllipsoid, oblateSpheroid, or referenceSphere object.
%
%   If supplied, the LAT and LON inputs must match in size unless:
%   (a) either one is scalar (it will expand in size to match the other),
%   or (b) LAT is a column vector and LON is a row vector (they will
%   expand to form a plaid latitude-longitude mesh).
%
%   Output Argument
%   ---------------
%   Z -- Function value, returned as a scalar value, vector, or matrix.
%     The function is evaluated at each element of LAT and LON (following
%     expansion as noted above), or at each cell center or posting point
%     defined by R.
%
%   See also PEAKS

% Copyright 2015-2020 The MathWorks, Inc.

    narginchk(1,3)
    if isobject(varargin{1})
        R = varargin{1};
        validateattributes(R, ...
            {'map.rasterref.GeographicCellsReference', ...
             'map.rasterref.GeographicPostingsReference'}, ...
            {'scalar'})
        [lat, lon] = map.internal.geographicPointMesh(R);
        varargin(1) = [];
    else
        R = [];
        lat = varargin{1};
        lon = varargin{2};
        if isfloat(lat)
            validateattributes(lat(~isnan(lat)), ...
                {'double','single'},{'real','2d','>=',-90,'<=',90})
        else
            validateattributes(lat,{'double','single'},{})
        end
        validateattributes(lon,{'double','single'},{'real','2d'})
        if any(isinf(lon))
            % Allow lon to include NaN, but not +/- Inf. (Can't use the
            % 'finite' abbribute because it will reject NaN.)
            validateattributes(lon(~isnan(lon)), ...
                {'double','single'},{'real','>',-Inf,'<',Inf})
        end
        if ~isscalar(lat) && ~isscalar(lon) && ~isequal(size(lat),size(lon))
            if iscolumn(lat) && isrow(lon)
                [lon, lat] = meshgrid(lon, lat);
            else
                error(message('map:validate:inconsistentSizes','LAT','LON'))
            end
        end
        varargin([1 2]) = [];
    end
    
    if isempty(varargin)
        if ~isempty(R) && ~isempty(R.GeographicCRS) && ~isempty(R.GeographicCRS.Spheroid)
            spheroid = R.GeographicCRS.Spheroid;
        else
            spheroid = referenceSphere('unit sphere');
        end
    else
        spheroid = varargin{1};
        validateattributes(spheroid, ...
            {'oblateSpheroid', 'referenceEllipsoid', 'referenceSphere'},{'scalar'})
    end
    
    [x,y,z] = ellipsoid2unitSphere(lat,lon,spheroid);
    v = peaks3d(x,y,z);
end

function [x,y,z] = ellipsoid2unitSphere(lat,lon,spheroid)
% Map geodetic locations on the surface of spheroid to 3-D Cartesian
% coordinates on the surface of a unit sphere. This depends only on the
% shape of the ellipsoid (e.g., its flattening), not on its absolute size.

% Equivalent Formulation
% ----------------------
%   [x,y,z] = geodetic2ecef(spheroid,lat,lon,0);
% 
%   a = spheroid.SemimajorAxis;
%   b = spheroid.SemiminorAxis;
% 
%   x = x/a;
%   y = y/a;
%   z = z/b;

    beta = parametricLatitude(lat,spheroid.Flattening);
    unitSphere = referenceSphere('unit sphere');
    [x,y,z] = geodetic2ecef(unitSphere,beta,lon,0,'degrees');
end

function v = peaks3d(x,y,z)
% A peaks-like C-infinity function that maps R^3 to R.

    v = 8*(1-x).^2.*exp(-4*(x - 0.059).^2 - 2*(y + 0.337).^2 - 2*(z + 0.940).^2) ...
        - 30*(z/10 - x.^3 - y.^5) .* exp(-3*(x - 0.250).^2 - 2*(y - 0.433).^2 - 3*(z - 0.866).^2) ...
        + (20*y - 8*z.^3) .* exp(-2*(x + 0.696).^2 - 3*(y + 0.123).^2 - 2*(z - 0.707).^2) ...
        + (7*y - 10*x + 10*z.^3) .* exp(-3*(x - 0.296).^2 - 3*(y + 0.814).^2 - 3*(z + 0.5).^2);
end

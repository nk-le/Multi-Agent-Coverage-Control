function [latc, lonc, rho] = gc2sc(lat, lon, az, angleUnit)
%GC2SC  Center and radius of great circle
%
%   [LATC,LONC,RHO] = GC2SC(LAT,LON,AZ) returns the center (LATC, LONC)
%   and radius of a small circle equivalent to the great circle through the
%   geographic point (LAT,LON) on a sphere at the specified azimuth, AZ.
%   All inputs and outputs are in degrees. The radius, RHO, is always 90
%   degrees. A great circle has two (antipodal) centers and one is chosen
%   arbitrarily.
%
%   [...] = GC2SC(..., angleUnit) uses angleUnit, which matches either
%   'degrees' or 'radians', to specify the units of the input and output
%   arguments.
%
%   MAT = GC2SC(...) returns a single output, where MAT = [LAT LON RHO].
%
%   Example
%   -------
%   lat = -25;
%   lon = -79;
%   az = 45;
%   [latc,lonc,rho] = gc2sc(lat,lon,az)
%   % latc =
%   %   -39.8557
%   % lonc =
%   %    33.9098
%   % rho =
%   %     90
%
%   Note
%   ----
%   GC2SC, and the related functions GCXGC, GCXSC, and CROSSFIX, follow the
%   convention that a great circle starting from the north pole proceeds
%   down the meridian with longitude LON + 180 - AZ and a great circle
%   starting from the south pole proceeds up the meridian with longitude
%   LON + AZ.  Consistent with this, the longitude of the center of the
%   small circle returned by GC2SC is given by:
%
%         LATC = wrapTo180(LON + 90 - AZ) when LAT == 90
%         LATC = wrapTo180(LON + 90 + AZ) when LAT == -90.
%
%   These behaviors follow naturally from limits taken as LAT approaches 90
%   or -90 with fixed LON and AZ.
%
%   See also SCXSC, GCXGC, GCXSC

% Copyright 1996-2020 The MathWorks, Inc.

    inDegrees = nargin < 4 || map.geodesy.isDegree(angleUnit);
    
    if ~inDegrees
        lat = rad2deg(lat);
        lon = rad2deg(lon);
        az = rad2deg(az);
    end
    
    try
        [nx, ny, nz] = greatCircleNormal(lat, lon, az);

        if inDegrees
            latc = atan2d(nz, hypot(nx, ny));
            lonc = atan2d(ny, nx);
            rho = 90 + zeros(size(latc));
        else
            latc = atan2(nz, hypot(nx, ny));
            lonc = atan2(ny, nx);
            rho = pi/2 + zeros(size(latc));
        end
    catch me
        if strcmp(me.identifier,'MATLAB:dimagree') || ...
                strcmp(me.identifier,'MATLAB:sizeDimensionsMustMatch')
            error(message('map:validate:inconsistentSizes3', ...
                'GCXSC','LAT','LON','AZ'))
        else
            rethrow(me)
        end
    end
    
    if nargout < 3
        latc = [latc lonc rho];
    end
end

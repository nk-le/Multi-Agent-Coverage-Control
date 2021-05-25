function [x,y] = webmercfwd(lat,lon)
%WEBMERCFWD WGS 84 Web Mercator Forward Projection
%
%   [X,Y] = map.geodesy.internal.webmercfwd(LAT,LON) projects points from a
%   WGS 84 geographic coordinate reference system (EPSG 4326) to a
%   projected coordinate reference system used widely by popular web
%   mapping and visualization applications and known by various names
%   including "WGS 84 / Pseudo-Mercator" and "Web Mercator Auxiliary
%   Sphere." An early, informal identifier for this system was 900913.
%   Currently it is best known as EPSG 3857.
%
%   Input Arguments
%   ---------------
%   LAT -- WGS 84 geodetic latitudes of one or more points, specified as a
%     scalar value, vector, matrix, or N-D array. Values must be in units
%     of degrees. Data Type: double
%
%   LON -- WGS 84 longitudes of one or more points, specified as a scalar
%     value, vector, matrix, or N-D array. Values must be in units of
%     degrees. Data Type: double
%
%   Output Arguments
%   ----------------
%   X -- Projected x-coordinates (eastings) in meters of the input points
%     in the EPSG 3857 system, returned as a scalar value, vector, matrix,
%     or N-D array.
%
%   Y -- Projected y-coordinates (northings) in meters of the input points
%     in the EPSG 3857 system, returned as a scalar value, vector, matrix,
%     or N-D array.
%
%   Technical Definition
%   --------------------
%   The projection maps the WGS 84 reference ellipsoid to a plane in a way
%   that is somewhat, but not perfectly conformal. The results are roughly
%   similar to a direct application of the ellipsoidal form of the Mercator
%   Projection (with comparable defining parameters), but can differ by
%   over 10 kilometers in the output northing.
%
%   Although not ideal from a geodetic or cartographic perspective, "Web
%   Mercator" is an actual map projection and can be formally defined. From
%   a mathematical perspective, the projection can be thought of as
%   proceeding in two stages.
%
%   In the first stage, input geodetic latitudes and longitudes are mapped
%   from the WGS 84 reference ellipsoid to a sphere with a radius equal to
%   the semimajor axis of the ellipsoid. Many map projections are based on
%   a two stage mapping which takes the ellipsoid to an auxiliary sphere
%   and then takes the sphere to a plane. Usually the first stage is
%   performed in a way that preserves some specific property such as area
%   or conformality. But in Web Mercator, a simple identity is used, such
%   that a given point on the sphere is assigned a spherical latitude that
%   equals its geodetic latitude on the ellipsoid. Longitudes are likewise
%   identical. The directions of meridians and parallels are preserved, but
%   this first-stage mapping is non-conformal.
%
%   In the second stage, points are mapped from the sphere to the plane
%   using the standard spherical Mercator formulation. This stage is
%   conformal. But the composition of a conformal transformation with a
%   non-conformal transformation cannot be conformal, and thus the Web
%   Mercator projection is non-conformal.
%
%   Reference
%   ---------
%   OGP Publication 373-7-2, Geomatics Guidance Note number 7, part 2, June
%   2013, Section 1.3.7.1 (Oblique and Equatorial Stereographic; EPSG
%   dataset coordinate operation method code 1024).
%
%   See also map.geodesy.internal.webmercinv, wgs84Ellipsoid

% Copyright 2015 The MathWorks, Inc.

spheroid = wgs84Ellipsoid;
R = spheroid.SemimajorAxis;
x = R * deg2rad(wrapTo180(lon));
y = R * atanh(sind(lat));

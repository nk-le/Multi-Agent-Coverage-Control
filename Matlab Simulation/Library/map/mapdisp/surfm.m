function h = surfm(lat,lon,Z,varargin)
%SURFM  Project geolocated data grid on map axes
%
%   SURFM(LAT, LON, Z) constructs a surface to represent the data grid Z
%   in the current map axes.  The surface lies flat in the horizontal
%   plane with its 'CData' property set to Z. LAT and LON are 2-D arrays
%   or vectors that define the latitude-longitude graticule mesh on
%   which Z is displayed. The sizes and shapes of LAT and LON affect
%   their interpretation, and also determine whether the default
%   'FaceColor' property of the surface is 'flat' or 'texturemap'. There
%   are three options:
%
%   * 2-D arrays (matrices) having the same size as Z
%
%        LAT and LON are treated as geolocation arrays specifying the
%        precise location of each vertex.  'FaceColor' is 'flat'.
%
%   * 2-D arrays having a different size than Z
%
%        LAT and LON define a graticule mesh that may be either
%        larger or smaller than Z.  LAT and LON must match each
%        other in size.  FaceColor is 'texturemap'.
%
%   * Vectors having more than two elements
%
%        The elements of LAT and LON are repeated to form a graticule
%        mesh with size equal to numel(LAT)-by-numel(LON).  'FaceColor'
%        is 'flat' if the graticule mesh matches Z in size, and
%        'texturemap' otherwise.
%
%   SURFM will clear the current map if the hold state is 'off'.
%
%   SURFM(LATLIM, LONLIM, Z) defines the graticule using the latitude
%   and longitude limits LATLIM and LONLIM, which should match the
%   geographic extent of the data grid Z.  LATLIM is a two-element
%   vector of the form:
%
%               [southern_limit northern_limit]
% 
%   Likewise LONLIM has the form:
%
%                [western_limit eastern_limit]
%
%   A latitude-longitude graticule is constructed to match Z in size.
%   The surface 'FaceColor' property is 'flat' by default.
%
%   SURFM(LAT, LON, Z, ALT) sets the ZData property of the surface to
%   ALT, resulting in a 3-D surface.  LAT and LON must result in a
%   graticule mesh that matches ALT in size.  CData is set to Z.
%   'FaceColor' is 'texturemap' unless Z matches ALT in size, in which
%   case it is 'flat'.
%
%   SURFM(..., PROP1, VAL1, PROP2, VAL2,...) applies additional
%   MATLAB graphics properties to the surface, via property/value pairs.
%   Any property accepted by the SURFACE function can be specified,
%   except for XData, YData, and ZData.
%
%   H = SURFM(...) returns a handle to the surface object.
%
%  See also GEOSHOW, MESHM, SURFACEM, SURFLM

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3,Inf)

latlimlonlimSyntax = (numel(lat) == 2) && (numel(lon) == 2);
if latlimlonlimSyntax
    latlim = lat;
    lonlim = lon;
    [lat,lon] = map.internal.graticuleMesh(latlim,lonlim,size(Z));
end

%  Display the map
nextmap(varargin);
if nargout == 0
    surfacem(lat,lon,Z,varargin{:}); 
else
    h = surfacem(lat,lon,Z,varargin{:});
end

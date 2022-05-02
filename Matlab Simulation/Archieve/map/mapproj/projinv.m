function [lat, lon] = projinv(proj, x, y)
%PROJINV Unproject x-y map coordinates to latitude-longitude
%
%   [LAT, LON] = PROJINV(PROJ, X, Y) transforms the map coordinates
%   specified by X and Y in the projected coordinate reference system
%   specified by PROJ to the latitude-longitude coordinates LAT and LON in
%   degrees. PROJ may be either a projcrs object, a scalar map projection
%   structure (mstruct), or a GeoTIFF info structure. X and Y are arrays of
%   map coordinates. For a complete list of GeoTIFF info structure map
%   projections that may be used with PROJINV, see PROJLIST.
%
%   Class support for inputs X and Y:
%       float: double, single
%
%   Example - Overlay Concord roads on top of geographic axes
%   -------
%   % Get the x and y map coordinates of roads in Concord, MA.
%   roads = shaperead('concord_roads.shp');
%   x = [roads.X];
%   y = [roads.Y];
%   
%   % Obtain the projcrs for 'concord_roads.shp'.
%   info = shapeinfo('concord_roads.shp');
%   proj = info.CoordinateReferenceSystem;
%   
%   % Inverse project the x-y coordinates to latitude-longitude coordinates.
%   [lat,lon] = projinv(proj,x,y);
%   
%   % Display the coordinates on geographic axes
%   figure
%   geoplot(lat,lon)
%   hold on
%   geobasemap streets
%   
%   % The geodetic CRS of the x-y coordinates used in this example is 
%   % NAD83. You can find the geodetic CRS of a projcrs object by querying
%   % its GeodeticCRS property. The geodetic CRS underlying the 'streets'
%   % basemap is WGS84. NAD83 and WGS84 are similar, but not identical. 
%   % Therefore, at high zoom levels, the coordinates and basemap
%   % may appear misaligned.
%   
%   See also GEOTIFFINFO, PROJCRS, PROJFWD, PROJLIST

% Copyright 1996-2020 The MathWorks, Inc.

% Check the input arguments.
validateattributes(x, {'single', 'double'}, {'real'}, mfilename, 'X', 2);
validateattributes(y, {'single', 'double'}, {'real'}, mfilename, 'Y', 3);
map.internal.assert(isequal(size(x),size(y)), ...
    'map:validate:inconsistentSizes2', mfilename, 'X', 'Y')

% Inverse transform the X and Y points. Where supported, use PROJ.
list = projlist;
if ismstruct(proj) && ~any(strcmp({list.MapProjection}, proj.mapprojection))
    % Using PROJ is not supported for this projection. Use the MATLAB
    % implementation.
    
    % Warn when there is an alternative to the supplied projection.
    projsWithStandardVersion = ["cassini","eqaconic","eqdconic","lambert","polycon"];
    if any(strcmp(proj.mapprojection, projsWithStandardVersion))
        warning(message('map:projections:notStandardProjection', proj.mapprojection))
    elseif strcmp(proj.mapprojection, "globe")
        warning(message('map:projections:use3DForGlobe',mfilename,'ecef2geodetic'))
    end
    
    [lat, lon] = map.crs.internal.minvtran(proj, x, y);
else
    % Use PROJ
    [lat, lon] = projaccess('inv', proj, x, y);
end

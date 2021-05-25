function [x, y] = projfwd(proj, lat, lon)
%PROJFWD Project latitude-longitude to x-y map coordinates
%
%   [X, Y] = PROJFWD(PROJ, LAT, LON) transforms the latitude-longitude
%   coordinates specified by LAT and LON to the X and Y map coordinates in
%   the projected coordinate reference system specified by PROJ. PROJ may
%   be a projcrs object, a scalar map projection structure (mstruct), or a
%   GeoTIFF info structure. LAT and LON are arrays of latitude and
%   longitude coordinates in degrees. For a complete list of GeoTIFF info
%   structure map projections that may be used with PROJFWD, see PROJLIST.
%
%   Class support for inputs LAT and LON:
%       float: double, single
%
%   Example
%   -------
%   % Overlay landmarks on 'boston.tif'.
%   % Includes material (c) GeoEye, all rights reserved.
%
%   % Specify latitude and longitude coordinates of landmarks in Boston.
%   lat = [42.3604 42.3691 42.3469 42.3480 42.3612]; 
%   lon = [-71.0580 -71.0710 -71.0623 -71.0968 -71.0941];
%
%   % Obtain the projcrs object corresponding to 'boston.tif'.
%   info = georasterinfo('boston.tif');
%   proj = info.CoordinateReferenceSystem;
%
%   % Project the landmarks.
%   [x, y] = projfwd(proj, lat, lon);
%
%   % Read the 'boston.tif' image.
%   [RGB, R] = readgeoraster('boston.tif');
%
%   % Display the image and projected coordinates.
%   figure
%   mapshow(RGB, R)
%   mapshow(x,y,'DisplayType','point','Marker','o', ...
%       'MarkerFaceColor','y','MarkerEdgeColor','none')
%   xlabel('Easting in Survey Feet')
%   ylabel('Northing in Survey Feet')
%
%   See also GEOTIFFINFO, PROJCRS, PROJINV, PROJLIST

% Copyright 1996-2020 The MathWorks, Inc.

% Check the input arguments
validateattributes(lat, {'single', 'double'}, {'real'}, mfilename, 'LAT', 2);
validateattributes(lon, {'single', 'double'}, {'real'}, mfilename, 'LON', 3);
map.internal.assert(isequal(size(lat),size(lon)), ...
    'map:validate:inconsistentSizes2', mfilename, 'LAT', 'LON')

% Project the latitude and longitude points. Where supported, use PROJ.
list = projlist;
if ismstruct(proj) && ~any(strcmp({list.MapProjection}, proj.mapprojection))
    % Using PROJ is not supported for this projection. Use the MATLAB
    % implementation.
    
    % Warn when there is an alternative to the supplied projection.
    projsWithStandardVersion = ["cassini","eqaconic","eqdconic","lambert","polycon"];
    if any(strcmp(proj.mapprojection, projsWithStandardVersion))
        warning(message('map:projections:notStandardProjection', proj.mapprojection))
    elseif strcmp(proj.mapprojection, "globe")
        warning(message('map:projections:use3DForGlobe',mfilename,'geodetic2ecef')) 
    end
    
    [x,y] = map.crs.internal.mfwdtran(proj, lat, lon);
else
    % Use PROJ
    [x,y] = projaccess('fwd', proj, lat, lon);
end

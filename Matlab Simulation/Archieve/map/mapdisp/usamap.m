function h = usamap(varargin)
%USAMAP Construct map axes for United States of America
%
%   USAMAP STATE or USAMAP(STATE) constructs an empty map axes with a
%   Lambert Conformal Conic projection and map limits covering a U.S. state
%   or group of states specified by input STATE.  STATE may be a string,
%   character vector or a cell array of character vectors, where each value
%   contains the name of a state or 'District of Columbia'.  Alternatively,
%   STATE may be a standard two-letter U.S. Postal Service abbreviation.
%   The map axes is created in the current axes and the axis limits are set
%   tight around the map frame.
%
%   USAMAP 'conus' or USAMAP('conus') constructs an empty map axes for the
%   conterminous 48 states (i.e. excluding Alaska and Hawaii).
%
%   USAMAP with no arguments asks you to choose from a menu of state names
%   plus 'District of Columbia', 'conus', 'all', and 'allequal'.
%
%   USAMAP(LATLIM, LONLIM) constructs an empty Lambert Conformal map axes
%   for a region of the U.S. defined by its latitude and longitude limits
%   in degrees.  LATLIM and LONLIM are two-element vectors of the form
%   [southern_limit northern_limit] and [western_limit eastern_limit],
%   respectively.
% 
%   USAMAP(Z, R) derives the map limits from the extent of a regular data
%   grid georeferenced by R. R can be a geographic raster reference object,
%   a referencing vector, or a referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel.
%
%   h = USAMAP(...) returns the handle of the map axes.
%
%   h = USAMAP('all') constructs three empty map axes, inset within a
%   single figure, for the conterminous states, Alaska, and Hawaii, with a
%   spherical Earth model and other projection parameters suggested by the
%   U.S. Geological Survey. The maps in the three axes are shown at
%   approximately the same scale. The handles for the three map axes are
%   returned in h. h(1) is for the conterminous states, h(2) is for
%   Alaska, and h(3) is for Hawaii. USAMAP('allequal') is the same as
%   USAMAP('all'); usage of 'allequal' will be removed in a future release.
% 
%   All axes created with USAMAP are initialized with a spherical Earth
%   model having a radius of 6,371,000 meters.
%
%   In some cases, USAMAP uses TIGHTMAP to adjust the axes limits around
%   the map. If you change the projection, or just want more white space
%   around the map frame, use TIGHTMAP again or AXIS AUTO.
%
%   Example 1
%   ---------
%   % Map of Alabama only
%   figure; usamap('Alabama')
%   alabamahi = shaperead('usastatehi', 'UseGeoCoords', true,...
%                   'Selector',{@(name) strcmpi(name,'Alabama'), 'Name'});
%   geoshow(alabamahi, 'FaceColor', [0.3 1.0, 0.675])
%   textm(alabamahi.LabelLat, alabamahi.LabelLon, alabamahi.Name,...
%       'HorizontalAlignment', 'center')
%
%   Example 2
%   ---------
%   % Map of a region extending from California to Montana
%   figure; ax = usamap({'CA','MT'});
%   set(ax, 'Visible', 'off')
%   latlim = getm(ax, 'MapLatLimit');
%   lonlim = getm(ax, 'MapLonLimit');
%   states = shaperead('usastatehi',...
%       'UseGeoCoords', true, 'BoundingBox', [lonlim', latlim']);
%   geoshow(ax, states, 'FaceColor', [0.5 0.5 1])
%
%   lat = [states.LabelLat];
%   lon = [states.LabelLon];
%   tf = ingeoquad(lat, lon, latlim, lonlim);
%   textm(lat(tf), lon(tf), {states(tf).Name}, ...
%       'HorizontalAlignment', 'center')
%
%   Example 3
%   ---------
%   % Map of the Conterminous United States with a different
%   % fill color for each state
%   figure; ax = usamap('conus');
%   states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector',...
%       {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
%   faceColors = makesymbolspec('Polygon',...
%       {'INDEX', [1 numel(states)], 'FaceColor', polcmap(numel(states))});
%   geoshow(ax, states, 'DisplayType', 'polygon', 'SymbolSpec', faceColors)
%   framem off; gridm off; mlabel off; plabel off
%
%   Example 4
%   ---------
%   % Map with separate axes for Alaska and Hawaii
%   figure; ax = usamap('allequal');
%   set(ax, 'Visible', 'off')
%   states = shaperead('usastatelo', 'UseGeoCoords', true);
%   names = {states.Name};
%   indexHawaii = strcmp('Hawaii',names);
%   indexAlaska = strcmp('Alaska',names);
%   indexConus = 1:numel(states);
%   indexConus(indexHawaii | indexAlaska) = [];
%   stateColor = [0.5 1 0.5];
%   geoshow(ax(1), states(indexConus),  'FaceColor', stateColor)
%   geoshow(ax(2), states(indexAlaska), 'FaceColor', stateColor)
%   geoshow(ax(3), states(indexHawaii), 'FaceColor', stateColor)
%   for k = 1:3
%       setm(ax(k), 'Frame', 'off', 'Grid', 'off',...
%           'ParallelLabel', 'off', 'MeridianLabel', 'off')
%   end
%
%   See also AXESM, AXESSCALE, GEOSHOW, PAPERSCALE, TIGHTMAP, WORLDMAP

% Copyright 1996-2019 The MathWorks, Inc.

narginchk(0,2)
ax = regionmap(mfilename, varargin);

% Avoid command-line output if no output variable is specified.
if nargout == 1
    h = ax;
end

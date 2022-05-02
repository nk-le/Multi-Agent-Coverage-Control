function h = worldmap(varargin)
%WORLDMAP Construct map axes for given region of world
%
%   WORLDMAP REGION or WORLDMAP(REGION) sets up an empty map axes with
%   projection and limits suitable to the part of the world specified in
%   REGION.  REGION may be a string, character vector or a cell array of
%   character vectors. Permissible strings include names of continents,
%   countries, and islands, as well as 'World', 'North Pole', 'South Pole',
%   and 'Pacific'.
%
%   WORLDMAP with no arguments presents a menu from which you can select
%   the name of a single continent, country, island, or other region.
%   
%   WORLDMAP(LATLIM, LONLIM) allows you to define a custom geographic
%   region in terms of its latitude and longitude limits in degrees. LATLIM
%   and LONLIM are two-element vectors of the form [southern_limit
%   northern_limit] and [western_limit eastern_limit], respectively.
%   
%   WORLDMAP(Z, R) derives the map limits from the extent of a regular data
%   grid georeferenced by R.  R can be a geographic raster reference
%   object, a referencing vector, or a referencing matrix.
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
%   H = WORLDMAP(...) returns the handle of the map axes.
%  
%   All axes created with WORLDMAP are initialized with a spherical Earth
%   model having a radius of 6,371,000 meters.
%
%   WORLDMAP uses TIGHTMAP to adjust the axes limits around the map. If you
%   change the projection, or just want more white space around the map
%   frame, use TIGHTMAP again or AXIS AUTO.
%
%   Example 1
%   ---------
%   % World map with coarse coastlines
%   worldmap('World')
%   load coastlines
%   plotm(coastlat,coastlon)
%
%   Example 2
%   ---------
%   % Worldmap with land areas, major lakes and rivers, and cities and
%   % populated places
%   ax = worldmap('World');
%   setm(ax,'Origin',[0 180 0])
%   land = shaperead('landareas','UseGeoCoords',true);
%   geoshow(ax,land,'FaceColor',[0.5 0.7 0.5])
%   lakes = shaperead('worldlakes','UseGeoCoords',true);
%   geoshow(lakes,'FaceColor','blue')
%   rivers = shaperead('worldrivers','UseGeoCoords',true);
%   geoshow(rivers,'Color','blue')
%   cities = shaperead('worldcities','UseGeoCoords',true);
%   geoshow(cities,'Marker','.','Color','red')
%
%   Example 3
%   ---------
%   % Map of Antarctica
%   worldmap('antarctica')
%   antarctica = shaperead('landareas','UseGeoCoords',true,...
%       'Selector',{@(name) strcmp(name,'Antarctica'),'Name'});
%   patchm(antarctica.Lat,antarctica.Lon,[0.5 1 0.5])
%
%   Example 4
%   ---------
%   % Map of Africa and India with major cities and populated places
%   worldmap({'Africa','India'})
%   land = shaperead('landareas.shp','UseGeoCoords',true);
%   geoshow(land,'FaceColor',[0.15 0.5 0.15])
%   cities = shaperead('worldcities','UseGeoCoords',true);
%   geoshow(cities,'Marker','.','Color','blue')
%
%   Example 5
%   ---------
%   % Map of the geoid over South America and the central Pacific
%   latlim = [-50  50];
%   lonlim = [160 -30];
%   worldmap(latlim,lonlim)
%   R = georefcells([-90 90],[0 360],1,1);
%   N = egm96geoid(R);
%   geoshow(N,R,'DisplayType','texturemap');
%   load coastlines
%   geoshow(coastlat,coastlon)
%
%   Example 6
%   ---------
%   % Map of terrain elevations in Korea
%   load korea5c
%   h = worldmap(korea5c,korea5cR);
%   set(h,'Visible','off')
%   geoshow(h,korea5c,korea5cR,'DisplayType','texturemap')
%   demcmap(korea5c)
%
%   Example 7
%   ---------
%   % Map of the United States of America
%   ax = worldmap('USA');
%   load coastlines
%   geoshow(ax,coastlat,coastlon,...
%       'DisplayType','polygon','FaceColor',[.45 .60 .30])
%   states = shaperead('usastatelo','UseGeoCoords',true);
%   faceColors = makesymbolspec('Polygon',...
%       {'INDEX', [1 numel(states)],'FaceColor',polcmap(numel(states))});
%   geoshow(ax,states,'DisplayType','polygon','SymbolSpec',faceColors)
%
%   See also AXESM, FRAMEM, GEOSHOW, GRIDM, MLABEL, PLABEL, TIGHTMAP, USAMAP

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(0,2)
ax = regionmap(mfilename, varargin);

% Avoid command-line output if no output variable is specified.
if nargout == 1
    h = ax;
end

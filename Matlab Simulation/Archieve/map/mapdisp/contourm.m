function [c, g] = contourm(varargin)
%CONTOURM Project 2-D contour plot of map data
%
%  CONTOURM(Z,R) creates a contour plot of the regular data grid Z. R can
%  be a geographic raster reference object, a referencing vector, or a
%  referencing matrix.
%
%  If R is a geographic raster reference object, its RasterSize property
%  must be consistent with size(Z).
%
%  If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%  If R is a referencing matrix, it must be 3-by-2 and transform raster
%  row and column indices to/from geographic coordinates according to:
%
%                    [lon lat] = [row col 1] * R.
%
%  If R is a referencing matrix, it must define a (non-rotational,
%  non-skewed) relationship in which each column of the data grid falls
%  along a meridian and each row falls along a parallel. If the current
%  axis is a map axis, the coordinates of Z will be projected using the
%  projection structure from the axis. The contours are drawn at their
%  corresponding Z level.
%
%  CONTOURM(LAT, LON, Z) displays a contour plot of the geolocated M-by-N
%  data grid, Z.  LAT and LON can be the size of Z or can specify the 
%  corresponding row and column dimensions for Z.
%
%  CONTOURM(Z, R, N) or CONTOURM(LAT, LON, Z, N) where N is a positive
%  scalar integer, draws N contour levels.
%
%  CONTOURM(Z, R, V) or CONTOURM(LAT, LON, Z, V) where V is a vector, draws 
%  contours at the levels specified by the input vector V. Use V = [v v] to 
%  compute a single contour at level v. 
%
%  CONTOURM(..., LINESPEC) uses any valid LineSpec to draw the contour
%  lines.
%
%  CONTOURM(..., PARAM1, VAL1, PARAM2, VAL2, ...) allows you to set the
%  following optional parameters: Fill, LevelStep, LineColor, LineStyle,
%  LineWidth, and ShowText. See the CONTOURM reference page for full
%  descriptions. In addition, any of the following hggroup properties
%  may be specified: HandleVisibility, Parent, Tag, UserData, and
%  Visible.
%
%  C = CONTOURM(...) returns a standard contour matrix, C, with the first
%  row representing longitude data and the second row representing latitude
%  data.
%
%  [C,H] = CONTOURM(...) returns the contour matrix and the handle to the
%  contour patches drawn onto the current axes. The handle is type hggroup.
%
%  % Example 1
%  % ---------
%  % Contour the EGM96 geoid heights, label them, and add a legend.
%  R = georefpostings([-90 90],[0 360],1,1);
%  N = egm96geoid(R);
%  [c,h] = contourm(N,R,'LevelStep',20,'ShowText','on');
%  xlabel('Longitude')
%  ylabel('Latitude')
%  clegendm(c,h,-1)
%
%  % Example 2
%  % ---------
%  % Contour geoid heights for an area including Korea with a backdrop of
%  % terrain elevations and bathymetry.
%
%  % Load the data.
%  load korea5c
%  R = georefpostings([-90 90],[0 360],1,1);
%  N = egm96geoid(R);
%
%  % Create a map axes that includes Korea.
%  figure
%  worldmap(korea5c,korea5cR)
%
%  % Display the digital elevation data and apply a colormap.
%  geoshow(korea5c,korea5cR,'DisplayType','texturemap');
%  demcmap(korea5c)
%
%  % Contour the geoid values from -100 to 100 in increments of 5.
%  [c,h] = contourm(N,R,-100:5:100,'k');
%
%  % Add red labels with white backgrounds to the contours.
%  ht = clabelm(c,h);
%  set(ht,'Color','r','BackgroundColor','white','FontWeight','bold')
%
%  See also CLABELM, CONTOUR, CONTOUR3M, CONTOURFM, GEOSHOW

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2, inf)

% Get the data grid, reference object, contour level list vector,
% and a cell array of optional property name-value pairs.
[varargin{:}] = convertStringsToChars(varargin{:});
[Z, R, levelList, pvpairs] = parseContourInputs(varargin);

% Obtain axes, and get ready to plot if it's a map axes.
[ax, pvpairs] = map.internal.findNameValuePair('Parent', NaN, pvpairs{:});
if isequaln(ax,NaN)
    ax = gca;
end
if ismap(ax)
    nextmap(ax)
end

% Construct a geographic contour graphics object and associated hggroup
h = internal.mapgraph.GeographicContourGroup(ax, Z, R, levelList);

% Set any properties supplied by the user (or contourfm or contour3m).
if ~isempty(pvpairs)
    set(h, pvpairs{:})
end

% Update the default line and fill colormaps by scaling the figure's
% colormap, then refresh to construct the contour lines and polygons
% themselves.
refresh(h)

% Set the Tag property of the hggroup unless it's already been set
% (which could happen if it appeared in the property-value list).
tag = get(h.HGGroup,'Tag');
if isempty(tag)
    set(h.HGGroup,'Tag','Contour')
end

if nargout > 0
    c = geostructToContourMatrix(h.getContourLines());
end

if nargout > 1
    g = h.HGGroup;
end

end

%-------------------------------------------------------------------

function c = geostructToContourMatrix(L)
% Convert contour line geostruct L to geographic contour matrix c.

% Allocate contour matrix.
ncols = 0;
for k = 1:numel(L)
    ncols = ncols + numel(L(k).Lon) + 1;
end
c = zeros(2,ncols);

% Fill in contour matrix.
n = 1;
for k = 1:numel(L)
    % Process the k-th level.
    lonk = L(k).Lon;
    latk = L(k).Lat;
    [first, last] = internal.map.findFirstLastNonNan(lonk);
    for j = 1:numel(first)
        % Process the j-th part of the k-th level.
        s = first(j);
        e = last(j);
        lon = lonk(s:e);
        lat = latk(s:e);
        count = numel(lon);
        c(:,n) = [L(k).Level; count];
        m = n + count;
        n = n + 1;
        c(1,n:m) = lon(:)';
        c(2,n:m) = lat(:)';
        n = m + 1;
    end
end
c(:,n:end) = [];

end

%-------------------------------------------------------------------

function deletePatch(p) %#ok<DEFNU>
% Avoid errors when closing re-opened figures from R2013b and earlier
if ishghandle(p,'patch')
    delete(p)
end
end

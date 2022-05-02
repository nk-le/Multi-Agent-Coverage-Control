function [latb,lonb] = bufferm(lat,lon,bufwidth,direction,npts,outputformat)
%BUFFERM Buffer zones for latitude-longitude polygons
%
%   [LATB, LONB] = BUFFERM(LAT, LON, BUFWIDTH) computes the buffer zone
%   around a line or polygon. If the vectors LAT and LON, in units of
%   degrees, define a line, then LATB and LONB define a polygon that
%   contains all the points that fall within a certain distance,
%   BUFWIDTH, of the line. BUFWIDTH is a scalar specified in degrees of
%   arc along the surface. If the vectors LAT and LON define a polygon,
%   then LATB and LONB define a region that contains all the points
%   exterior to the polygon that fall within BUFWIDTH of the polygon.
%
%   [LATB, LONB] = BUFFERM(LAT, LON, BUFWIDTH, DIRECTION) uses the optional
%   DIRECTION value to specify whether the buffer zone is inside ('in')
%   or outside ('out') of the polygon. A third option, 'outPlusInterior'
%   returns the union of an exterior buffer (as would be computed using
%   'out') with the interior of the polygon. If you do not supply a
%   direction value, BUFFERM uses 'out' as the default and returns a
%   buffer zone outside the polygon. If you supply 'in' as the direction
%   value, BUFFERM returns a buffer zone inside the polygon. If you are
%   finding the buffer zone around a line, 'out' is the only valid option.
%
%   [LATB, LONB] = BUFFERM(LAT, LON, BUFWIDTH, DIRECTION, NPTS) controls
%   the number of points used to construct circles about the vertices of
%   the polygon. A larger number of points produces smoother buffers, but
%   requires more time. If NPTS is omitted, 13 points per circle are used.
%
%   Example
%   -------
%   load conus
%   tol = 0.05; % Tolerance for simplifying polygon outlines
%   [latr, lonr] = reducem(gtlakelat, gtlakelon, tol);
%   bufwidth = 1;  % Buffer width in degrees
%   [latb, lonb] = bufferm(latr, lonr, bufwidth, 'out');
%   [lati, loni] = bufferm(latr, lonr, 0.3*bufwidth, 'in');
%   figure('Color','w')
%   ax = usamap({'MN','NY'});
%   setm(ax,'MLabelLocation',5)
%   geoshow(latb, lonb, 'DisplayType', 'polygon', 'FaceColor', 'yellow')
%   geoshow(latr, lonr, 'DisplayType', 'polygon', 'FaceColor', 'blue')
%   geoshow(lati, loni, 'DisplayType', 'polygon', 'FaceColor', 'magenta')
%   geoshow(uslat, uslon)
%   geoshow(statelat, statelon)

% Copyright 1996-2019 The MathWorks, Inc.

% The following syntax remains supported but is not recommended and is
% intentionally undocumented:
%
%   [LATB, LONB] = BUFFERM(LAT, LON, BUFWIDTH, DIRECTION, NPTS, OUTPUTFORMAT)
%   controls the format of the returned buffer zones. OUTPUTFORMAT 'vector'
%   returns NaN-clipped vectors. OUTPUTFORMAT 'cutvector' returns
%   NaN-clipped vectors with cuts connecting holes to the exterior of the
%   polygon. OUTPUTFORMAT 'cell' returns cell arrays in which each element
%   of the cell array is a separate polygon. Each polygon may consist of
%   an outer contour followed by holes separated with NaNs.

w = warning('off','MATLAB:polyshape:repairedBySimplify');
clean = onCleanup(@() warning(w));

% Validate argument BUFWIDTH.
validateattributes(bufwidth, {'numeric'}, ...
    {'positive','finite','scalar'}, mfilename, 'BUFWIDTH')

% Set/validate optional 4-th argument DIRECTION.
if nargin < 4
    direction = 'out';
else
    direction = validatestring(direction, ...
        {'in','out','outPlusInterior'}, mfilename, 'direction', 4);
end

% Set/validate optional 5-th argument NPTS.
if nargin < 5
    npts = 13;
else
    validateattributes(npts, {'numeric'}, ...
        {'positive','integer','scalar'}, mfilename, 'NPTS')
    if mod(npts,2) == 0
        % Ensure that npts is odd
        npts = npts + 1;
    end
end

% Set/validate optional 6-th argument OUTPUTFORMAT.
if nargin < 6
    outputformat = 'vector';
else
    formats = {'vector','cell','cutvector'};
    assert(any(strcmp(outputformat,formats)), ...
        'map:bufferm:unknownFormatFlag', ...
        'Output format must be ''%s'', ''%s'', or ''%s''.', formats{:})        
end

% Validate/convert vertex arrays: convert possible cell array inputs to
% NaN-separated form; remove duplicate vertices; ensure column vectors.
if iscell(lat)
    checkcellvector(lat,lon)
    [lat, lon] = polyjoin(lat,lon);
else
    checklatlon(lat,lon,mfilename,'LAT','LON',1,2);
end
[lat, lon] = removeDuplicateVertices(lat, lon);
lat = lat(:);
lon = lon(:);

% Perform buffering operations using NaN-separated vectors.
[latb, lonb] = dobufferm(lat, lon, bufwidth, direction, npts - 1);

% Convert to alternative output format if requested.
if ~strcmp(outputformat,'vector')
    [latb, lonb] = polysplit(latb, lonb);
    if strcmp(outputformat,'cutvector')
        [latb,lonb] = polycut(latb,lonb);
    end
end

%-----------------------------------------------------------------------

function checkcellvector(lat, lon)

if ~isa(lat,'cell') || ~isa(lon,'cell')
    error('map:bufferm:expectedCellArrays', ...
        'Expected latitude and longitude to be cell arrays.')
end

if ~isequal(size(lat),size(lon))
    error('map:bufferm:inconsistentSizes', ...
        'Inconsistent dimensions on latitude and longitude input.');
end

for k = 1:numel(lat)
    if ~isequal(size(lat{k}),size(lon{k}))
        error('map:bufferm:inconsistentSizesInCell', ...
            'Inconsistent latitude and longitude dimensions within a cell.')
    end
    
    [lat{k}, lon{k}] = removeDuplicateVertices(lat{k}, lon{k});
end

%-----------------------------------------------------------------------

function [latb, lonb] = dobufferm(lat, lon, bufwidth, direction, n)
% Operate on NaN-separated column vectors with no duplicate vertices.

% Work with row vectors throughout, but keep track of input shape.
rowVectorInput = (size(lat,2) > 1);
lat = lat(:)';
lon = lon(:)';

latlim = [ -90  90];
lonlim = [-180 180];

% Identify open and closed curves.
[first, last] = internal.map.findFirstLastNonNan(lat);
isClosed = ((lat(first) == lat(last)) ...
    & (mod(lon(first) - lon(last), 360) == 0));
firstClosed = first(isClosed);
lastClosed  = last(isClosed);

if strcmp(direction,'in')
    % Process polygons only, as defined by closed curves.
    if ~isempty(firstClosed)
        % Buffer the edges of closed polygons using a planar topology;
        % convert the input polygons to the same topology and longitude
        % limits; keep only the buffered areas that fall within an
        % input polygon.
        [latClosed, lonClosed] = subsetCurves( ...
            lat, lon, firstClosed, lastClosed);
        pb = geolinebuf(latClosed, lonClosed, bufwidth, n);
        pa = clipToLimits(latClosed, lonClosed, latlim, lonlim);
        pb = intersect(pa,pb);
    else
        pb = polyshape();
    end
    [lonb, latb] = boundary(pb);
else
    if ~isempty(firstClosed)
        % Buffer the edges of closed polygons using a planar topology;
        % convert the input polygons to the same topology and longitude
        % limits; subtract the (interiors of) the closed polygons.
        [latClosed, lonClosed] = subsetCurves( ...
            lat, lon, firstClosed, lastClosed);
        pc = geolinebuf(latClosed, lonClosed, bufwidth, n);
        pa = clipToLimits(latClosed, lonClosed, latlim, lonlim);
        if strcmp(direction,'out') && ~isempty(boundary(pc))
            pc = subtract(pc,pa);
        else
            % direction is 'outPlusInterior'
            pc = union(pc,pa);
        end
    end
    
    firstOpen = first(~isClosed);
    lastOpen  = last(~isClosed);
    if ~isempty(firstOpen)
        % Buffer the open curves, if any.
        [latOpen, lonOpen] = subsetCurves(lat, lon, firstOpen, lastOpen);
        po = geolinebuf(latOpen, lonOpen, bufwidth, n);
    end
    
    % Combine the results for the open and closed curves.
    if isempty(firstClosed)
        if isempty(firstOpen)
            latb = [];
            lonb = [];
        else
            [lonb, latb] = boundary(po);
        end
    else
        if isempty(firstOpen)
            [lonb, latb] = boundary(pc);
        else
            pb = union(pc,po);
            [lonb, latb] = boundary(pb);
        end
    end
end

[latb, lonb] = planarToSpherical(latb, lonb, lonlim);

% Make shape consistent with input.
latb = latb(:);
lonb = lonb(:);

if rowVectorInput
    latb = latb';
    lonb = lonb';
end

%---------------------------------------------------------------------------

function [x, y] = subsetCurves(x, y, first, last)
% Keep the subset of the NaN-separated curve X,Y defined by the indices
% in first and last. Discard other elements, except for required
% NaN-separators.
    
keep = false(size(x));
for k = 1:numel(first)
    keep(first(k):last(k)) = true;
end
x(~keep) = NaN;
y(~keep) = NaN;
[x, y] = removeExtraNanSeparators(x, y);

%---------------------------------------------------------------------------

function p = clipToLimits(lat, lon, latlim, lonlim)
[lat, lon] = maptrimp(lat, lon, latlim, lonlim);
p = polyshape(lon, lat, 'KeepCollinearPoints', true);

%---------------------------------------------------------------------------

function [latb, lonb] = planarToSpherical(latb, lonb, lonlim)
% Convert from planar topology to spherical topology. Interpolate vertices
% as need to keep the vertex separation within 2 degrees, in case collinear
% vertices have been filtered out by the polygon operations.

if ~isempty(latb)
    maxsep = 2;
    [latb, lonb] = densifyLinear(latb, lonb, maxsep);
    tolSnap = 100*eps(180);
    [lonb, latb] = map.internal.clip.snapOpenEndsToLimits(lonb(:), latb(:), lonlim, tolSnap);
    [lonb, latb] = map.internal.clip.gluePolygonOnCylinder(lonb, latb, lonlim);
    [latb, lonb] = removeExtraPolarVertices(latb, lonb, tolSnap);
end

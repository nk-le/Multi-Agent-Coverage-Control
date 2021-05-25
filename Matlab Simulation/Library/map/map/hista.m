function [latbin, lonbin, count] = hista(lat, lon, in3, in4, in5)
%HISTA  Bin counts for geographic points using equal-area bins
%
%   [LATBIN, LONBIN, COUNT] = HISTA(LAT, LON) bins the geographic
%   locations indicated by vectors LAT and LON, using equal area binning on
%   a sphere. The default bin area is 100 square kilometers. The LATBIN and
%   LONBIN outputs are column vectors indicating the centers of non-empty
%   bins. COUNT matches LATBIN and LONBIN in size, with each element
%   containing a positive integer equal to the number of occurrences in the
%   corresponding bin.
%
%   Binning is performed on a mesh within a quadrangle whose latitude and
%   longitude limits match the extrema of the input locations. The input
%   and output latitudes and longitudes are in units of degrees.
%
%   [LATBIN, LONBIN, COUNT] = HISTA(LAT, LON, BINAREA) uses the bin size
%   specified by the input BINAREA, which must be in square kilometers.
%
%   [LATBIN, LONBIN, COUNT] = HISTA(LAT, LON, BINAREA, SPHEROID) bins the
%   data on the reference spheroid defined by SPHEROID. SPHEROID is a
%   reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity]. The
%   eccentricity/flattening of the spheroid is used in determining the
%   latitude extent of the bins. The semimajor axis of the spheroid is used
%   to determine the longitude extent of the bins, but if the length unit
%   of the spheroid is unspecified, the mean radius of the earth in
%   kilometers is used as the equatorial radius.
%
%   [LATBIN, LONBIN, COUNT] = HISTA(..., ANGLEUNITS) uses ANGLEUNITS 
%   to define the angle units of the inputs and outputs.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%  See also HISTR

% Copyright 1996-2017 The MathWorks, Inc.

narginchk(2,5)

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','HISTA','LAT','LON'))
end

defaultSpheroid = referenceSphere('earth','km');

switch nargin
    case 2
        % hista(lat,lon)
        binAreaInSquareKilometers = 100;
        spheroid = defaultSpheroid;
        angleUnit = 'degrees';
        
    case 3
        spheroid = defaultSpheroid;
        if ischar(in3) || isStringScalar(in3)
            % hista(lat,lon,angleunits)
            binAreaInSquareKilometers = 100;
            angleUnit = in3;
        else
            % hista(lat,lon,binarea)
            binAreaInSquareKilometers = in3;
            angleUnit = 'degrees';
        end
        
    case 4
        binAreaInSquareKilometers = in3;
        if ischar(in4) || isStringScalar(in4)
            % hista(lat,lon,binarea,angleunits)
            angleUnit = in4;
            spheroid = defaultSpheroid;
        else
            % hista(lat,lon,binarea,spheroid)
            angleUnit = 'degrees';
            spheroid = in4;
        end
        
    otherwise % 5
        % hista(lat,lon,binarea,spheroid,angleunits)
        binAreaInSquareKilometers = in3;
        spheroid = in4;
        angleUnit = in5;
end

if map.geodesy.isDegree(angleUnit)
    validateattributes(lat,{'double','single'},{'real','finite','>=',-90,'<=',90})
else
    validateattributes(lat,{'double','single'},{'real','finite','>=',-pi,'<=',pi})
end
validateattributes(lon,{'double','single'},{'real','finite'})

if ~isobject(spheroid)
    ellipsoid = checkellipsoid(spheroid,mfilename,'SPHEROID',4);
    spheroid = oblateSpheroid;
    spheroid.SemimajorAxis = ellipsoid(1);
    spheroid.Eccentricity  = ellipsoid(2);
end

validateattributes(binAreaInSquareKilometers,{'double'}, ...
    {'real','positive','finite','scalar'}, 'HISTA', 'BINAREA', 3)

% Work in degrees; ensure column vectors.
[lat, lon] = toDegrees(angleUnit, lat(:), lon(:));

% Define the bins and count the instances
[latbin, lonbin, count] = eqabin(lat, lon, binAreaInSquareKilometers, spheroid);

% Convert the mesh to the specified angle unit.
[latbin, lonbin] = fromDegrees(angleUnit, latbin, lonbin);

%-----------------------------------------------------------------------

function [latbin, lonbin, count] ...
    = eqabin(lat, lon, binAreaInSquareKilometers, spheroid)
% Define equal area cells, count the number of (lat,lon) points per cells,
% and return the centers of non-empty cells ("bins") as vectors in latitude
% and longitude, along with the count per bin.

if isempty(lat)
    latbin = [];
    lonbin = [];
    count = [];
else
    [converter, longitudeOrigin] = setUpProjection(spheroid,lon);
    [x,y] = forwardProject(converter, longitudeOrigin, lat, lon);
    cellwidth = cellWidthInRadians(binAreaInSquareKilometers, spheroid);
    R = rasterReferenceInEqualAreaSystem(x, y, cellwidth);
    [xbin, ybin, count] = pointsPerCell(R,x,y);
    [latbin, lonbin] = inverseProject(converter, longitudeOrigin, xbin, ybin);
end

%-----------------------------------------------------------------------

function [converter, longitudeOrigin] = setUpProjection(spheroid,lon)
% Set up an equal area cylindrical projection defined by an authalic
% latitude converter and a longitude origin in degrees.

converter = map.geodesy.AuthalicLatitudeConverter(spheroid);
[~, lonlim] = geoquadpt(zeros(size(lon)), lon);
longitudeOrigin = centerlon(lonlim);

%-----------------------------------------------------------------------

function [x,y] = forwardProject(converter, longitudeOrigin, lat, lon)
% Map latitude-longitude locations to equal area cylindrical coordinates.

x = deg2rad(wrapTo180(lon - longitudeOrigin));
y = sind(forward(converter, lat, 'degrees'));

%-----------------------------------------------------------------------

function [lat, lon] = inverseProject(converter, longitudeOrigin, x, y)
% Unproject equal area cylindrical coordinates to latitude-longitude.

lat = inverse(converter, asind(y), 'degrees');
lon = longitudeOrigin + rad2deg(x);

%-----------------------------------------------------------------------

function width = cellWidthInRadians(binAreaInSquareKilometers, spheroid)

if isprop(spheroid,'LengthUnit') && ~isempty(spheroid.LengthUnit)
    lengthUnit = spheroid.LengthUnit;
    kilometersPerUnit = unitsratio('km', lengthUnit);
    radiusInKilometers = kilometersPerUnit * spheroid.SemimajorAxis;
else
    % The length unit of the spheroid is unspecified; assume kilometers.
    radiusInKilometers = spheroid.SemimajorAxis;
end
cellWidthInKilometers = sqrt(binAreaInSquareKilometers);
width = cellWidthInKilometers/radiusInKilometers;

%-----------------------------------------------------------------------

function lon = centerlon(lonlim)
% Center of an interval in longitude
%
%   Accounts for wrapping.  Returns the longitude of the meridian halfway
%   from the western limit to the eastern limit, when traveling east.
%   All angles are in degrees.

lon = wrapTo180(lonlim(1) + wrapTo360(diff(lonlim))/2);

%-----------------------------------------------------------------------

function R = rasterReferenceInEqualAreaSystem(x, y, cellwidth)
% Define a the referencing object grid of cells into which to bin the input
% points, working in the equal area cylindrical system of x and y. This
% system runs from -pi to pi in x and -1 to 1 in y.

halfwidth = cellwidth/2;

xmin = max(min(x - halfwidth), -pi);
xmax = min(max(x + halfwidth),  pi);

ymin = max(min(y - halfwidth), -1);
ymax = min(max(y + halfwidth),  1);

nrows = ceil((ymax - ymin)/cellwidth);
ncols = ceil((xmax - xmin)/cellwidth);

R = maprasterref('RasterSize', [nrows ncols], ...
    'XWorldLimits',[xmin xmax],'YWorldLimits',[ymin ymax]);

%-----------------------------------------------------------------------

function [xbin, ybin, count] = pointsPerCell(R,x,y)
% Map each point to a cell and determine the number of points per non-empty
% cell. Return the center coordinates of each non-empty cell (aka "bin") in
% column vector xbin and ybin, with corresponding number of points in
% column vector count.

[rows, cols] = worldToDiscrete(R,x,y);
nrows = R.RasterSize(1);
[urows, ucols, count] = uniquesub(nrows, rows, cols);
[xbin, ybin] = intrinsicToWorld(R, ucols, urows);

%-----------------------------------------------------------------------

function [urows, ucols, count] = uniquesub(nrows, rows, cols)
% Given row and column indices into a nrows-by-M array, return vectors
% listing the row and column indices of each unique (row,col) pair, and the
% number of elements having those indices.

% Linear indices of row-column mapping results; k will typically contain
% many repeated values:
%   k = sub2ind([nrows ncols], rows, cols);
k = sort(rows + nrows * (cols - 1));

% Once the index k is sorted, determine the number of points per cell by
% finding the locations at which k jumps to a new value.
p = find(diff([0; k; Inf]) ~= 0);
count = diff(p);
p(end) = [];

% Row and column indices of non-empty cells:
%   [urows, ucols] = ind2sub([nrows ncols], unique(k));
index = k(p);
urows = 1 + rem(index-1, nrows);
ucols = 1 + (index - urows)/nrows;

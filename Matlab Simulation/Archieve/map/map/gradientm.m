function [aspectAngle,slopeAngle,dFdyNorth,dFdxEast] = gradientm(varargin)
%GRADIENTM Calculate gradient, slope and aspect of data grid
%
%   [ASPECT,SLOPE,dFdyNorth,dFdxEast] = GRADIENTM(F,R) approximates the
%   slope angle, aspect angle, and local north and east gradient components
%   for a regular data grid F. R can be a geographic raster reference
%   object, a referencing vector, or a referencing matrix. If the grid
%   contains elevations in meters, the resulting aspect and slope angles
%   are in units of degrees clockwise from north and up from the
%   horizontal. The north and east gradient components are the change in F
%   per meter of distance in the north and east directions, and are
%   computed with respect to the GRS 80 reference ellipsoid.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(F).
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
%   [...] = GRADIENTM(LAT,LON,F) computes the gradient of a geolocated
%   data grid.  LAT and LON, the latitudes and longitudes of the
%   geolocation points, are in degrees.
%
%   [...] = GRADIENTM(___,SPHEROID) computes the gradient on the specified
%   reference object.  SPHEROID can be a reference ellipsoid (oblate
%   spheroid) object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity]. If the grid F contains elevations in
%   the same units as the semimajor axis, the slope and aspect are in units
%   of degrees. The GRS 80 reference ellipsoid is used by default.
% 
%   [...] = GRADIENTM(___,SPHEROID, ANGLEUNIT) specifies the angle
%   unit of the latitude and longitude inputs. If omitted, 'degrees' is
%   assumed.  For elevation grids in the same units as the length unit of
%   the spheroid, the resulting slope and aspect are in the specified angle
%   unit.
%
%   The components of the gradient indicate the change in F with distance
%   in the local east and local north directions, with the unit of
%   distance matching the length unit of the reference spheroid.
%
%   Example
%   -------
%   % Compute and display the slope for 5 arc-minute Korea elevation data.
%   % Slopes in the Sea of Japan are up to 8 degrees at this grid resolution.
%   load korea5c
%   R = korea5cR;
%   [aspect,slope,dFdyNorth,dFdxEast] = gradientm(korea5c,R);
%   worldmap(slope,R)
%   geoshow(slope,R,'DisplayType','texturemap')
%   colorbar
%   bbox = [R.LongitudeLimits' R.LatitudeLimits'];
%   land = shaperead('landareas','UseGeoCoords',true,'BoundingBox',bbox);
%   geoshow([land.Lat],[land.Lon])
%
%   See also GRADIENT

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,5)

size1 = size(varargin{1});
size2 = size(varargin{2});

if nargin >= 3 && isequal(size1, size2, size(varargin{3})) ...
    % GRADIENTM(LAT, LON, F, ...)
    
    latmesh = varargin{1};
    lonmesh = varargin{2};
    F = varargin{3};
    varargin(1:3) = [];
    
    [spheroid, angleUnit] = parseSpheroidAndAngleUnit(varargin);
    
    checklatlon(latmesh, lonmesh, mfilename, 'LAT', 'LON', 1, 2)
    validateattributes(F, {'numeric'}, {'2d'}, mfilename, 'F')

    meshIsRegular = map.internal.isRegularGeographicMesh(latmesh,lonmesh);
    
    % Ensure that the mesh vertices are expressed in degrees.
    [latmesh, lonmesh] = toDegrees(angleUnit, latmesh, lonmesh);
else
    % GRADIENTM(F, R, ...)

    narginchk(2,4)
    F = varargin{1};
    R = varargin{2};
    varargin(1:2) = [];
    
    if isa(R, 'map.rasterref.GeographicRasterReference') && isscalar(R) ...
            && ~isempty(R.GeographicCRS) && ~isempty(R.GeographicCRS.Spheroid)
        spheroid = R.GeographicCRS.Spheroid;
        angleUnit = R.GeographicCRS.AngleUnit;
    else
        spheroid = [];
        angleUnit = 'degrees';
    end
    
    if isempty(spheroid) || ~isempty(varargin)
        [spheroid, angleUnit] = parseSpheroidAndAngleUnit(varargin);
    end
    
    % If R is already spatial referencing object, validate it. Otherwise
    % convert the input referencing vector or matrix.
    R = internal.map.convertToGeoRasterRef( ...
        R, size(F), angleUnit, 'GRADIENTM', 'R', 2);
    
    % Construct a latitude-longitude mesh, in degrees, with a point-wise
    % correspondence to the grid.
    [latmesh, lonmesh] = map.internal.geographicPointMesh(R);
    
    % The mesh corresponding to a geographic raster reference object is
    % always rectilinear with respect to the meridians and parallels.
    meshIsRegular = true;
end

% Validate the raster size.
if size(F,1) < 2 || size(F,2) < 2
    error('map:gradientm:smallerThan2by2', ...
        'Input data grid must be 2-by-2 or larger.')
end

if meshIsRegular
    [dFdxEast, dFdyNorth] ...
        = gradientRegular(F,latmesh,lonmesh,spheroid);
else
    [dFdxEast, dFdyNorth] ...
        = gradientNonRectilinear(F,latmesh,lonmesh,spheroid);
end

% Derive the aspect angle and slope angle from the components of the
% gradient vector.
[slopeAngle, aspectAngle] = deriveSlopeAndAspect(dFdxEast,dFdyNorth,angleUnit);

%--------------------------------------------------------------------------

function [spheroid, angleUnit] = parseSpheroidAndAngleUnit(args)
% The input cell vector args can:
%
%   1. Be empty
%   2. Contain only the spheroid input
%   3. Contain the spheroid input followed by the angleUnit input
%
% Validate the spheroid input. If an "ellipsoid vector" of the form
% [a] or [a ecc] is supplied, convert it to an oblateSpheroid object.

if isempty(args)
    spheroid = referenceEllipsoid('grs80');
else
    spheroid = args{1};
    args(1) = [];
    
    try
        spheroid = checkellipsoid(spheroid,'GRADIENTM','SPHEROID');
    catch matlabException
        throwAsCaller(matlabException)
    end
    
    if ~isobject(spheroid)
        a = spheroid(1);
        if isscalar(spheroid)
            ecc = 0;
        else
            ecc = spheroid(2);
        end
        spheroid = oblateSpheroid;
        spheroid.SemimajorAxis = a;
        spheroid.Eccentricity = ecc;
    end
end

% Validate the angle units
if isempty(args)
    angleUnit = 'degrees';
else
    angleUnit = args{1};
end

%--------------------------------------------------------------------------

function [dFdxEast, dFdyNorth] ...
    = gradientNonRectilinear(F, latmesh, lonmesh, spheroid)
% Approximate the gradient of F given an geolocation mesh that may not be
% regular (or even rectilinear) with respect to the latitude-longitude
% graticule.
%
% The conversion of gradient components from the intrinsic system to the
% local east-north system is given by the multivariate chain rule:
%
%   [dFdxEast  = [dxIntrinsicdxEast  dyIntrinsicdxEast] * [dFdxIntrinsic
%    dFdyNorth]   dxIntrinsicdyNorth dyIntrinsicdyNorth]   dFdyIntrinsic]
%
% where "d" denote partial differentiation. (Note: this actually is the
% transpose of how the chain rule is typically expressed, which turns out
% to be more convenient in this application.) The partial derivatives of F
% with respect to the intrinsic coordinates are easy to approximate with
% first differences. But the matrix above is not. However, from the
% multivariate inverse function theorem, it is the inverse of the matrix:
%
%          A = [dxEastdxIntrinsic  dyNorthdxIntrinsic
%               dxEastdyIntrinsic  dyNorthdyIntrinsic]
%
% and the partial derivates in this matrix, like the partials of F, can be
% easily approximated with first differences. Rather than compute the
% inverse explicitly, of course, we should instead solve the linear system
%
%                           A*x = b
%
% where  b = [dFdxIntrinsic   is known and  x = [dFdxEast     is not.
%             dFdyIntrinsic]                     dFdyNorth]
%
%
% Normally we would use the backslash operator or mldivide function, but in
% this case A is a "matrix of matrices" and b and x are "column vectors of
% matrices".  We actually need to solve M-times-N 2-by-2 linear systems,
% that is, where M and N are the sizes of F. We use a private function,
% solve2x2 to do this efficiently, but it is equivalent to calling mldivide
% M-times-N times, cycling through all the elements of dFdxIntrinsic,
% dFdyIntrinsic, dxEastdxIntrinsic, etc.

angleUnit = 'degrees';

% Partial derivatives of ECEF coordinates in intrinsic system
[xECEF,yECEF,zECEF] = geodetic2ecef(spheroid,latmesh,lonmesh,0,angleUnit);

[dxECEFdxIntrinsic, dxECEFdyIntrinsic] = gradientIntrinsic(xECEF);
[dyECEFdxIntrinsic, dyECEFdyIntrinsic] = gradientIntrinsic(yECEF);
[dzECEFdxIntrinsic, dzECEFdyIntrinsic] = gradientIntrinsic(zECEF);

% Approximate partial derivatives of local East and North in with respect
% to xIntrinsic via vector rotation of the set of first outputs.
[dxEastdxIintrinsic, dyNorthdxIntrinsic] = ecef2enuv( ...
    dxECEFdxIntrinsic, dyECEFdxIntrinsic, dzECEFdxIntrinsic, ...
    latmesh, lonmesh, angleUnit);

% Approximate partial derivatives of local East and North in with respect
% to yIntrinsic via vector rotation of the set of second outputs.
[dxEastdyIntrinsic, dyNorthdyIntrinsic] = ecef2enuv( ...
    dxECEFdyIntrinsic, dyECEFdyIntrinsic, dzECEFdyIntrinsic, ...
    latmesh, lonmesh, angleUnit);

% Approximate gradient of F in the intrinsic coordinate system
[dFdxIntrinsic, dFdyIntrinsic] = gradientIntrinsic(F);

% Solve the elementwise linear system (A*x = b above):
%
%  [dxEastdxIntrinsic  dyNorthdxIntrinsic  * [dFdxEast   = [dFdxIntrinsic
%   dxEastdyIntrinsic  dyNorthdyIntrinsic]    dFdyNorth]    dFdyIntrinsic]
%
[dFdxEast, dFdyNorth] = solve2x2( ...
    dxEastdxIintrinsic, dyNorthdxIntrinsic, ...
    dxEastdyIntrinsic,  dyNorthdyIntrinsic, ...
    dFdxIntrinsic, dFdyIntrinsic);

%--------------------------------------------------------------------------

function [dFdxEast, dFdyNorth] ...
    = gradientRegular(F, latmesh, lonmesh, spheroid)
% Approximate the gradient of F given a regular geolocation mesh that is
% regular with respect to the latitude-longitude graticule: All columns of
% latmesh are identical and all rows of lonmesh are identical with equal
% steps in longitude.

% Column vector of unique latitudes
lat = latmesh(:,1);

% Row vector of unique longitudes
lon = lonmesh(1,:);

% Derivative of yNorth with respect to yIntrinsic at each latitude
dLatdyIntrinsic = stepSizeInLatitude(lat);

% Derivative of longitude with respect to xIntrinsic; This is scalar
% because the same value applies to all mesh points.
dLondxIntrinsic = stepSizeInLongitude(lon);

% Radius radius of curvature in the plane of the meridian M and radius of
% curvature of the parallel R at each latitude
angleUnit = 'degrees';
M = rcurve('meridian',spheroid,lat,angleUnit);
R = rcurve('parallel',spheroid,lat,angleUnit);

% Derivatives of local east with respect to intrinsic X and local north
% with respect to intrinsic Y
dxEastdxIntrinsic  = R .* deg2rad(dLondxIntrinsic);
dyNorthdyIntrinsic = M .* deg2rad(dLatdyIntrinsic);

% Replicate columns to match full-sized mesh.
rowOfOnes = ones(size(lon));
dxEastdxIntrinsic  = dxEastdxIntrinsic( :,rowOfOnes);
dyNorthdyIntrinsic = dyNorthdyIntrinsic(:,rowOfOnes);

% Gradient in the intrinsic coordinate system
[dFdxIntrinsic, dFdyIntrinsic] = gradientIntrinsic(F);

% The linear equation described in gradientNonRectilinear still applies,
% but it is trivial to solve because dyNorthdxIntrinsic == 0 and
% dxEastdyIntrinsic == 0.
dFdxEast  = dFdxIntrinsic ./ dxEastdxIntrinsic;
dFdyNorth = dFdyIntrinsic ./ dyNorthdyIntrinsic;

%--------------------------------------------------------------------------

function stepSize = stepSizeInLatitude(lat)
% Column vector input and output.
steps = diff(lat);
stepSize = zeros(size(lat));
stepSize(1) = steps(1);
stepSize(2:end-1) = (steps(1:end-1) + steps(2:end))/2;
stepSize(end) = steps(end);

%--------------------------------------------------------------------------

function stepSize = stepSizeInLongitude(lon)
% LON is a row vector of longitudes in degrees.
% Row vector input and scalar output.
ascending = all(diff(lon > 0));
if ~ascending
    angleUnit = 'degrees';
    lon = unwrapMultipart(lon,angleUnit);
end

steps = diff(lon);
stepSize = sum(steps) / numel(steps);

%--------------------------------------------------------------------------

function [dFdxIntrinsic, dFdyIntrinsic] = gradientIntrinsic(F)
% Approximate the partial derivatives of F with respect to intrinsic X
% (column index) and intrinsic Y (row index) coordinates. Invoking this
% function is roughy equivalent to calling the MATLAB GRADIENT function
% with a single input argument:
%
%      [dFdxIntrinsic, dFdyIntrinsic] = gradientIntrinsic(F);
%
% except along the edges, where the simple first-difference approach of
% GRADIENT is replaced with a quadratic-fitting approach.

dFdyIntrinsic = diff1(F);     % Differentiate the columns of F
dFdxIntrinsic = diff1(F')';   % Differentiate the rows of F

%--------------------------------------------------------------------------

function F1 = diff1(F)
% Numerically differentiate the matrix F along its first dimension,
% assuming a uniform sampling interval of 1 and fitting a quadratic to each
% set of three adjacent samples. The quadratics are centered for the
% interior rows, giving a result equivalent to centered differences. The
% quadratics are off-center to the left and right for the first and last
% rows, respectively. This approach reduces approach produces somewhat
% cleaner results than simply using first differences to compute values for
% the first and last rows.

F1 = zeros(size(F));
if size(F,1) == 2
    firstdiff = F(2,:) - F(1,:);
    F1(1,:) = firstdiff;
    F1(2,:) = firstdiff;
elseif size(F,1) >= 3
    F1(1,:) = leftdiff(F(1,:), F(2,:), F(3,:));
    F1(2:end-1,:) = centerdiff(F(1:end-2,:), F(3:end,:));
    F1(end,:) = rightdiff(F(end-2,:), F(end-1,:), F(end,:));
end

%--------------------------------------------------------------------------

function ypLeft = leftdiff(yLeft, yCenter, yRight)
% ypLeft = leftdiff(yLeft, yCenter, yRight)
%
% Given the sequence yLeft, yCenter, yRight representing samples of a
% univariate function sampled at locations xLeft, xCenter, xRight,
% where xLeft = xCenter - 1 and xRight = xCenter + 1, compute a numerical
% derivative at the xLeft by fitting a quadratic to the three points and
% differentiating it.
ypLeft = 2*yCenter - (yRight + 3*yLeft)/2;

%--------------------------------------------------------------------------

function ypCenter = centerdiff(yLeft, yRight)
% ypCenter = centerdiff(yLeft, yRight)
%
% Given the sequence yLeft, yCenter, yRight representing samples of a
% univariate function sampled at locations xLeft, xCenter, xRight,
% where xLeft = xCenter - 1 and xRight = xCenter + 1, compute a numerical
% derivative at the xLeft by fitting a quadratic to the three points and
% differentiating it. The center value drops out of the result, which is
% identical to a straightforward centered difference.
ypCenter = (yRight - yLeft)/2;

%--------------------------------------------------------------------------

function ypRight = rightdiff(yLeft, yCenter, yRight)
% ypRight = rightdiff(yLeft, yCenter, yRight)
%
% Given the sequence yLeft, yCenter, yRight represening samples of a
% univariate function sampled at locations xLeft, xCenter, xRight,
% where xLeft = xCenter - 1 and xRight = xCenter + 1, compute a numerical
% derivative at xRight by fitting a quadratic polynomial to the three
% points and differentiating it.
ypRight = (3*yRight + yLeft)/2 - 2*yCenter;

%--------------------------------------------------------------------------

function [slopeAngle, aspectAngle] ...
    = deriveSlopeAndAspect(dFdxEast, dFdyNorth, angleUnit)
% The slope is the magnitude of the gradient vector. Use the arc tangent to
% convert it to an angle, although that's physically meaningful only when F
% is an elevation grid expressed in the same length unit as the semimajor
% axis of the spheroid.
%
% The aspect angle is the direction of steepest descent expressed as an
% azimuth measured clockwise from north.

slope = hypot(dFdyNorth, dFdxEast);
if map.geodesy.isDegree(angleUnit)
    slopeAngle = atand(slope);
    aspectAngle = wrapTo360(atan2d(-dFdxEast,-dFdyNorth));
else
    slopeAngle = atan(slope);
    aspectAngle = wrapTo2Pi(atan2(-dFdxEast,-dFdyNorth));
end

% The aspect angle is indeterminate in regions of uniform F, so set it to
% NaN when both components of the gradient vector vanish.
aspectAngle(dFdyNorth == 0 & dFdxEast == 0) = NaN;

function [L, P] = geocontours(Z, R, levels)
%GEOCONTOURS Contour lines and polygons in latitude-longitude
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [L, P] = GEOCONTOURS(Z, R, levels) contours the 2-D data grid Z,
%   which is spatially-referenced to latitude-longitude by R, at
%   contour levels specified in the vector LEVELS, and returns the
%   results in the form of line and polygon geostructs L and P.
%
%   R can be a referencing vector or matrix, a spatial referencing
%   object, or scalar "geomesh" structure with the fields:
%
%       AngleUnit
%       LatMesh
%       LonMesh
%
%   AngleUnit is either 'degree' or 'radian', and LatMesh and LonMesh
%   are 2-D arrays that match Z in size and constitute a valid
%   latitude-longitude mesh.
%
%   The outputs, L and P, are line and polygon geostructs. The line
%   mapstruct L one element per contour level, and has the fields:
%
%       Geometry
%       BoundingBox
%       Lat
%       Lon
%       Level
%
%   The polygon mapstruct P has one more element than L, and has fields:
%
%       Geometry
%       BoundingBox
%       Lat
%       Lon
%       MinLevel
%       MaxLevel
%
%   L(k).Lat and L(k).Lon are vertex arrays including all the contour
%   lines at the k-th contour level, L(k).Level. The vertices are
%   ordered such that, in a spherical topology, the "uphill" side of
%   each line is on its right-hand side. MinLevel and MaxLevel are
%   scalars such that the polygon defined by P(k).Lat and P(k).Lon
%   bounds an area on the sphere in which the value of Z remains between
%   P(k).MinLevel and P(k).MaxLevel. Specifically, if we let:
%
%      levelsInLimits = levels(Zmin <= levels & levels <= Zmax);
%
%   and:
%
%      n = numel(levelsInLimits);
%
%   then:
%
%      P(1).MinLevel = min([Zmin max(levels(levels <= Zmin))]);
%      P(k).MinLevel = levelsInLimits(k - 1);  % for k > 1
%      P(k).MaxLevel = levelsInLimits(k);      % for k <= n
%      P(n+1).MaxLevel = max([Zmax min(levels(levels >= Zmax))]);
%
%   Notice the up-down symmetry here. If we were to replace Z with
%   an inverted grid covering the same range of values:
%
%        max(Z(:)) + min(Z(:)) - Z
%
%   and perform a similar operation on levels, then we'd end up with the
%   same set of polygons except that their order would be reversed (and
%   for each k = 2:n the values of P(k).MaxLevel and P(k).MinLevel
%   values would be swapped).

% Copyright 2010-2017 The MathWorks, Inc.

% contourc requires real-valued input of class double.
validateattributes(Z, {'double'}, {'real'}, 'contourIntrinsic','Z',1)

% Z must contain at least one finite value.
if isempty(Z) || all(isnan(Z(:)) | isinf(Z(:)))
    [L, P] = emptyContourStructures();
    return
end

if isstruct(R)
    % Augment the mesh structure R so that it simulates an object by
    % setting two additional "properties" and assigning a function
    % handle to a field that simulates an intrinsicToGeographic method.
    R.RasterInterpretation = 'postings';
    edgesampling = edgeSamplingGeolocated(R);
    xLimit = [1 size(Z,2)];
    yLimit = [1 size(Z,1)];
    if isPlaid(R.LatMesh,R.LonMesh)
        lonmesh1 = unwrapMultipart(R.LonMesh(1,:),'degrees');
        if min(lonmesh1) < -180
            lonmesh1 = lonmesh1 + 360;
        end
        R.LonMesh = repmat(lonmesh1, size(R.LonMesh,1));
        lonlim = [min(lonmesh1) max(lonmesh1)];
        interplon = @interpolatePlaidLongitudeMesh;
    else
        lonlim = [-Inf Inf];
        interplon = @interpolateGeneralLongitudeMesh;
    end
    R.intrinsicToGeographic = ...
        @(x, y) intrinsicToGeographicGeolocated(R, x, y, interplon);
    
    preservesOrientation = meshPreservesOrientation(R);
else
    R = internal.map.convertToGeoRasterRef( ...
        R, size(Z), 'degrees', 'internal.map.geocontours', 'R', 2);
    edgesampling = edgeSamplingRegular(R);
    xLimit = R.XIntrinsicLimits;
    yLimit = R.YIntrinsicLimits;
    lonlim = R.LongitudeLimits;
    preservesOrientation = rasterrefPreservesOrientation(R);
end

% If the transformations between intrinsic and geographic coordinates
% fail to preserve the orientation of features, then if we transform a
% curve with uphill on its right in the intrinsic system, uphill will be
% on its left in the geographic system. To correct for that, we'll need
% to reverse the order of the vertices at the time we do the transformation.
reverseVertexOrder = ~preservesOrientation;
intrinsicToGeographic = @(x, y) R.intrinsicToGeographic(x, y);

% Translate information on edge configurations that requires a
% geographic context to information on how to pad or adjust the edges of
% the grid when contouring it in its intrinsic coordinate system.
edgefix.AverageFirstAndLastColumns = edgesampling.VerticalEdgesMeet;
edgefix.AverageFirstRow = edgesampling.SparseOnFirstHorizontalEdge;
edgefix.AverageLastRow  = edgesampling.SparseOnLastHorizontalEdge;

if nargout > 1
    % Compute a contour polygon geostruct only when it is requested.
    [L, P] = contourIntrinsic(Z, levels, R.RasterInterpretation, edgefix);
    
    P = intrinsicToGeostruct(P, 'Polygon', intrinsicToGeographic, ...
           reverseVertexOrder, xLimit, yLimit, lonlim, edgesampling);
else
    L = contourIntrinsic(Z, levels, R.RasterInterpretation, edgefix);
end

% Always compute a contour line geostruct.
L = intrinsicToGeostruct(L, 'Line', intrinsicToGeographic, ...
       reverseVertexOrder, xLimit, yLimit, lonlim, edgesampling);

%-----------------------------------------------------------------------

function tf = isPlaid(lat,lon)
% True if (lat,lon) defines a plaid mesh

latc = lat(:,1);   % Column vector of latitudes
lonr = lon(1,:);   % Row vector of longitudes
[lonm,latm] = meshgrid(lonr,latc);
tf = isequal(lat,latm) && isequal(lon,lonm);

%-----------------------------------------------------------------------

function tf = rasterrefPreservesOrientation(R)
% True if and only if the mapping between intrinsic raster coordinates
% and latitude-longitude, as defined by referencing object R, does not
% require a reflection.

tf = ~xor(columnsRunSouthToNorth(R), rowsRunWestToEast(R));

%-----------------------------------------------------------------------

function tf = meshPreservesOrientation(R)
% True if and only if the mapping between intrinsic raster coordinates
% and latitude-longitude, as defined by the mesh, does not require a
% reflection. R is a structure that simulates a "GeoMesh" object.

latmesh = R.LatMesh;
lonmesh = R.LonMesh;

if all(size(latmesh) > 1)
    % The mesh is M-by-N with M >=2 and N >= 2. Check the relative
    % azimuths of the line from (1,1) to (2,1) and the line from (1,1)
    % to (1,2), with special handling for the case where (1,1) falls on
    % a pole.
    
    [phi0, phi1, phi2] = toRadians( ...
        R.AngleUnit, latmesh(1,1), latmesh(2,1), latmesh(1,2));
    
    [deltaLambda1, deltaLambda2] = toRadians(R.AngleUnit, ...
        wrapTo180(lonmesh(2,1) - lonmesh(1,1)), ...
        wrapTo180(lonmesh(1,2) - lonmesh(1,1)));
    
    if phi0 <= -pi/2
        % The first (1,1) corner falls on the South Pole.
        tf = wrapTo2Pi(deltaLambda2 - deltaLambda1) < pi;
    elseif phi0 >= pi/2
        % The first (1,1) corner falls on the North Pole.
        tf = wrapTo2Pi(deltaLambda1 - deltaLambda2) < pi;
    else
        sinphi0 = sin(phi0);
        cosphi0 = cos(phi0);
        cosphi1 = cos(phi1);
        cosphi2 = cos(phi2);
        
        az1 = atan2(cosphi1 .* sin(deltaLambda1),...
            cosphi0 .* sin(phi1) - sinphi0 .* cosphi1 .* cos(deltaLambda1));
        
        az2 = atan2(cosphi2 .* sin(deltaLambda2),...
            cosphi0 .* sin(phi2) - sinphi0 .* cosphi2 .* cos(deltaLambda2));
        
        tf = wrapTo2Pi(az2 - az1) < pi;
    end
else
    % The mesh is degenerate: row vector, column vector, scalar, or empty,
    % so the mapping is 1-D (at most) and thus cannot affect feature
    % orientation.
    tf = true;
end

%-----------------------------------------------------------------------

function [lat, lon] = intrinsicToGeographicGeolocated(R, x, y, interplon)
% Convert intrinsic raster coordinates to latitude-longitude;
% R is a structure that simulates a "GeoMesh" object.

indx = isnan(x);
x(indx) = 1;
y(indx) = 1;

lat = interp2(R.LatMesh, x, y, '*linear');
lon = interplon(R.LonMesh, x, y);

lat(indx) = NaN;
lon(indx) = NaN;

%-----------------------------------------------------------------------

function lon = interpolateGeneralLongitudeMesh(lonmesh, x, y)
% Avoid discontinuities by interpolating the sine and cosine of the
% longitude mesh instead of the longitudes themselves.
slon = interp2(sind(lonmesh), x, y, '*linear');
clon = interp2(cosd(lonmesh), x, y, '*linear');
lon = atan2d(slon,clon);

%-----------------------------------------------------------------------

function lon = interpolatePlaidLongitudeMesh(lonmesh, x, ~)
% Each row of lonmesh is the same as all the others.

lonmesh1 = lonmesh(1,:);
lon = interp1(lonmesh1, x, '*linear');

% Handle limits explicitly to avoid possible 360-degree offsets.
lon(x(:) == 1) = lonmesh1(1);
lon(x(:) == length(lonmesh1)) = lonmesh1(end);

%-----------------------------------------------------------------------

function edgesampling = edgeSamplingGeolocated(R)
% Configuration of edges for a geolocated geographic data grid;
% R is a structure that simulates a "GeoMesh" object. In the field names
% of the scalar edgesampling structure, "Lower" and "Upper" refer to the
% orientation of the intrinsic system, corresponding to row 1 and row
% "end", respectively.

[latmesh, lonmesh] = toDegrees(R.AngleUnit, R.LatMesh, R.LonMesh);

edgesampling.VerticalEdgesMeet ...
    = all(wrapTo360(lonmesh(:,end) - lonmesh(:,1)) == 360);

% In the following, check both poles because we don't know if the
% columns run south-to-north or north-to-south.

edgesampling.SparseOnFirstHorizontalEdge ...
    = all(latmesh(1,:) == -90) || all(latmesh(1,:) == 90);

edgesampling.SparseOnLastHorizontalEdge ...
    = all(latmesh(end,:) == -90) || all(latmesh(end,:) == 90);

%-----------------------------------------------------------------------

function edgesampling = edgeSamplingRegular(R)
% Configuration of edges for a regular geographic data grid; R is a
% spatial referencing object. In the field names of the scalar
% edgesampling structure, "Lower" and "Upper" refer to the orientation of
% the intrinsic system, corresponding to row 1 and row "end",
% respectively.

xLim = R.XIntrinsicLimits;
yLim = R.YIntrinsicLimits;

[lLat, lLon] = R.intrinsicToGeographic(xLim(1),yLim(1));
[uLat, rLon] = R.intrinsicToGeographic(xLim(2),yLim(2));

[lLat, lLon, uLat, rLon] = toDegrees(R.AngleUnit, lLat, lLon, uLat, rLon);

edgesampling.VerticalEdgesMeet = (wrapTo360(rLon - lLon) == 360);
edgesampling.SparseOnFirstHorizontalEdge = (lLat == -90) || (lLat == 90);
edgesampling.SparseOnLastHorizontalEdge  = (uLat == -90) || (uLat == 90);

%-----------------------------------------------------------------------

function S = intrinsicToGeostruct(C, geometry, intrinsicToGeographic, ...
    reverseVertexOrder, xLimit, yLimit, lonlim, edgesampling)
% Map a line or polygon mapstruct C in intrinsic raster coordinates to a
% line or polygon geostruct S in latitude-longitude using the function
% handle provided in intrinsicToGeographic and reversing the vertex
% order as required to preserve feature orientation (handedness). Leave
% the BoundingBox field set to [] for all elements of S.

lines = strcmpi(geometry,'Line');

if isempty(C)
    % There's nothing in the mapstruct.
    if lines
        S = emptyContourStructures();
    else
        [~,S] = emptyContourStructures();
    end
else
    if lines
        S(numel(C),1) = struct( ...
            'Geometry',[],'BoundingBox',[],'Lat',[],'Lon',[],'Level',[]);
    else
        S(numel(C),1) = struct('Geometry',[], ...
            'BoundingBox',[],'Lat',[],'Lon',[],'MinLevel',[],'MaxLevel',[]);
    end
end

for k = 1:numel(C)
    x = C(k).X;
    y = C(k).Y;
    
    if reverseVertexOrder
        [x, y] = reverseVerticesPartByPart(x, y);
    end
    
    [x, y] = densifyOnIntegers(x, y, xLimit, yLimit, edgesampling);
    [lat, lon] = intrinsicToGeographic(x, y);
    
    if lines
        % Enhancement: Perform line gluing here so that linear features
        % can be traced across the bounding meridian if the data set
        % covers 360 degrees in longitude.
    else
        % Glue polygons along a meridian (if the data set covers 360
        % degrees in longitude) and remove extra polar vertices to
        % ensure a valid proper polygon topology on the sphere.
        tolSnap = 100 * eps(180);
        if (lonlim(2) - lonlim(1) == 360)
            lon = lonlim(1) + wrapTo360(lon - lonlim(1));
            [lon, lat] = map.internal.clip.snapOpenEndsToLimits(lon(:), lat(:), lonlim, tolSnap);
            [lon, lat] = map.internal.clip.gluePolygonOnCylinder(lon, lat, lonlim);
       end
       [lat, lon] = removeExtraPolarVertices(lat(:), lon(:), tolSnap);
    end
    
    S(k).Geometry = C(k).Geometry;
    S(k).Lat = lat(:)';
    S(k).Lon = lon(:)';
    if lines
        S(k).BoundingBox = [lonlim(1) min(lat); lonlim(2) max(lat)];
        S(k).Level = C(k).Level;
    else
        S(k).MinLevel = C(k).MinLevel;
        S(k).MaxLevel = C(k).MaxLevel;
    end
end

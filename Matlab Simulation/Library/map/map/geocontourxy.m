function [L,P] = geocontourxy(X, Y, Z, lat0, lon0, h0, varargin)
%geocontourxy Contour grid in local system with latitude-longitude results
%
%   [contourLines, contourPolygons] = geocontourxy(X,Y,Z,lat0,lon0,h0)
%   [___] = geocontourxy(___,Name,Value)
%
%   This function is non-graphical. It returns line and polygon geoshapes
%   containing contour lines and contour fill polygons, respectively.
%   These can be plotted with geoshow, if desired.
%
%   Input Arguments
%   ---------------
%   X - Vector or matrix defining the x-component of a mesh that locates
%       each element of Z in a local x-y plane. Data Types: single | double
%
%   Y - Vector or matrix defining the y-component of a mesh that locates
%       each element of Z in a local x-y plane. Data Types: single | double
%
%   Z - 2D array of data to be contoured. Data Types: single | double |
%       int8 | int16 | int32 | int64 | uint8 | uint16 | uint32 | uint64
%
%   lat0 - Geodetic latitude of local origin (reference) point, specified
%       as a scalar value in units of degrees. Data Types: single | double
%
%   lon0 - Geodetic longitude of local origin (reference) point, specified
%       as a scalar value in units of degrees. Data Types: single | double
%
%   h0 - Ellipsoidal height of local origin (reference) point, specified as
%       a scalar value. Data Types: single | double
%
%   The units of X, Y, and h0 are determined by the LengthUnit property of
%   the Spheroid input, if provided. Input in meters is assumed otherwise.
%
%   Name-Value Pair Arguments
%   -------------------------
%   LevelList - Contour levels, specified as a vector of Z-values. By
%       default, the geocontourxy function chooses approximately 8 values
%       within the range of Z. Data Types: single | double | int8 | int16 |
%       int32 | int64 | uint8 | uint16 | uint32 | uint64
%
%   XYRotation - Rotation angle of the local x-y system, measured
%       counterclockwise from the xEast-yNorth system, specified as a scalar
%       value in units of degrees. The default value is 0.
%       Data Types: single | double
%
%   Spheroid - Reference spheroid, specified as a referenceEllipsoid,
%       oblateSpheroid, or referenceSphere object. Use the constructor for
%       one of these three classes, or the wgs84Ellipsoid function, to
%       construct a Mapping Toolbox spheroid object. (You cannot directly
%       pass in a string or character vector that names your spheroid.
%       Instead, pass that value to referenceEllipsoid or referenceSphere
%       and use the resulting object.) The WGS 84 reference ellipsoid is
%       used by default.
%
%   Output Arguments
%   ----------------
%   contourLines -- Line geoshape with one element (contour line) per
%       contour level. Latitude and Longitude properties contain contour
%       line vertices in degrees. The contour level value of the k-th
%       element is stored in the ContourLevel feature property of
%       contourLines(k). A third vertex property, Height, contains the
%       ellipsoidal height of each vertex. In combination with Latitude and
%       Longitude, it completes the definition the 3D location of the
%       contour line in the plane that contains the local origin and is
%       parallel to the tangent plane at the origin latitude and longitude.
%
%   contourPolygons -- Polygon geoshape with one element (contour fill
%       polygon) per contour interval. Latitude and Longitude properties
%       contain contour fill contour vertices in degrees. The limits of the
%       k-th contour interval are stored in the LowerContourLevel and
%       UpperContourLevel properties of contourPolygons(k). As in the case
%       of lines, a third vertex property, Height, is included.
%
%   Example
%   -------
%   X = -150000:10000:150000;
%   Y =  0:10000:300000;
%   [xmesh, ymesh] = meshgrid(X/50000, (Y - 150000)/50000);
%   Z = 8 + peaks(xmesh, ymesh);
%   lat0 = dm2degrees([  21 18]);
%   lon0 = dm2degrees([-157 49]);
%   h0 = 300;
%   levels = 0:2:18;
%
%   [contourLines, contourPolygons] = geocontourxy(X,Y,Z,lat0,lon0,h0, ...
%       'LevelList',levels,'XYRotation',120)
%
%   figure
%   usamap([18.5 22.5],[-161 -154])
%   hawaii = shaperead('usastatehi', 'UseGeoCoords', true,...
%       'Selector',{@(name) strcmpi(name,'Hawaii'), 'Name'});
%   geoshow(hawaii)
%   geoshow(lat0,lon0,'DisplayType','point','Marker','o',...
%       'MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',10)
%
%    cmap = parula(1 + length(levels));
%    for k = 1:length(contourPolygons)
%        lat = contourPolygons(k).Latitude;
%        lon = contourPolygons(k).Longitude;
%        geoshow(lat,lon,'Display','polygon', ...
%            'FaceColor',cmap(k,:),'FaceAlpha',0.5,'EdgeColor','none')
%    end
%    geoshow(contourLines.Latitude,contourLines.Longitude,'Color','black')
%
%   See also CONTOURM, CONTOURFM

% Copyright 2015-2017 The MathWorks, Inc.

    validateattributes(Z, {'numeric'}, {'real', 'nonempty', '2d'}, '', 'Z')
    [X,Y] = validateMesh(X,Y,Z);
    validateattributes(lat0, {'double','single'}, {'real','scalar','>=',-90,'<=',90}, mfilename, 'LAT0')
    validateattributes(lon0, {'double','single'}, {'real','scalar','finite'}, mfilename, 'LON0')
    validateattributes(h0,   {'double','single'}, {'real','scalar','finite'}, mfilename, 'H0')

    [levelList, varargin] = map.internal.findNameValuePair('LevelList', [], varargin{:});
    if isempty(levelList)
        levelList = constructLevelList(Z);
    else
        validateattributes(levelList, {'numeric'}, {'real','finite','vector'}, mfilename, 'LevelList')
        levelList = double(unique(levelList));
    end
    
    [xyrot, varargin] = map.internal.findNameValuePair('XYRotation', 0, varargin{:});
    validateattributes(xyrot, {'double','single'}, {'real','scalar','finite'}, mfilename, 'XYRotation')
    
    spheroid = map.internal.findNameValuePair('Spheroid', wgs84Ellipsoid, varargin{:});
    validateattributes(spheroid, {'referenceEllipsoid','referenceSphere', ...
        'oblateSpheroid'}, {'scalar'}, mfilename, 'Spheroid')
    
    rasterInterpretation = 'postings';
    
    edgefix = struct( ...
        'AverageFirstRow', false, ...
        'AverageLastRow',  false, ...
        'AverageFirstAndLastColumns', false);
        
    [intrinsicLines, intrinsicPolygons] ...
        = contourIntrinsic(Z, levelList, rasterInterpretation, edgefix);
    
    reverseVertexOrder = ~meshPreservesOrientation(X,Y);
    
    L = geoshape([],[],'Geometry','line');
    for k = 1:numel(intrinsicLines)
        [lat, lon, h] = intrinsicToGeodetic(X, Y, intrinsicLines(k).X, ...
            intrinsicLines(k).Y, lat0, lon0, h0, xyrot, spheroid, reverseVertexOrder);
        L(k).Latitude  = lat;
        L(k).Longitude = lon;
        L(k).Height = h;
        L(k).ContourLevel = intrinsicLines(k).Level;
    end
    
    P = geoshape([],[],'Geometry','polygon');
    for k = 1:numel(intrinsicPolygons)
        [lat, lon, h] = intrinsicToGeodetic(X, Y, intrinsicPolygons(k).X, ...
            intrinsicPolygons(k).Y, lat0, lon0, h0, xyrot, spheroid, reverseVertexOrder);
        P(k).Latitude  = lat;
        P(k).Longitude = lon;
        P(k).Height = h;
        P(k).LowerContourLevel = intrinsicPolygons(k).MinLevel;
        P(k).UpperContourLevel = intrinsicPolygons(k).MaxLevel;
    end
end


function [X,Y] = validateMesh(X,Y,Z)

    validateattributes(X, {'double','single'}, {'2d','real','finite'}, mfilename, 'X')
    validateattributes(Y, {'double','single'}, {'2d','real','finite'}, mfilename, 'Y')
    
    m = size(Z,1);
    n = size(Z,2);
    
    if ~isequal(size(X), size(Z))
        if min(size(X)) == 1
            if length(X) == n
                % Ensure row vector, then replicate into n rows
                X = reshape(X,1,n);
                X = X(ones(m,1),:);
            else
                error(message('map:validate:inconsistentMeshColumns','X','Z'))
            end
        else
            error(message('map:validate:inconsistentSizes','X','Z'))
        end
    end
    
    if ~isequal(size(Y), size(Z))
        if min(size(Y)) == 1
            if length(Y) == m
                % Ensure column vector, then replicate into m columns
                Y = Y(:);
                Y = Y(:,ones(1,n));
            else
                error(message('map:validate:inconsistentMeshRows','Y','Z'))
            end
        else
            error(message('map:validate:inconsistentSizes','Y','Z'))
        end
    end
end


function tf = meshPreservesOrientation(X,Y)
    if all(size(X) > 1)
        % Form a closed quadrilateral by connecting the four corners of the
        % mesh, then see if it's clockwise or counterclockwise.
        tf = ispolycw( ...
            [X(1,1) X(end,1) X(end,end) X(1,end) X(1,1)], ...
            [Y(1,1) Y(end,1) Y(end,end) Y(1,end) Y(1,1)]);
    else
        % The mesh is degenerate: row vector, column vector, scalar, or
        % empty, so the mapping is 1-D (at most) and thus cannot affect
        % feature orientation.
        tf = true;
    end
end


function [lat, lon, h] = intrinsicToGeodetic(xMesh, yMesh, ...
    xIntrinsic, yIntrinsic, lat0, lon0, h0, xyrot, spheroid, reverseVertexOrder)

    [xLocal, yLocal] = intrinsicToLocal(xMesh, yMesh, ...
        xIntrinsic, yIntrinsic, reverseVertexOrder);
    
    % Rotate local system to east-north system.
    cosAz = cosd(xyrot);
    sinAz = sind(xyrot);
    xEast  = xLocal * cosAz - yLocal * sinAz;
    yNorth = xLocal * sinAz + yLocal * cosAz;
    
    % Transform east-north system to geodetic system via ECEF.
    [X,Y,Z] = enu2ecef(xEast, yNorth, 0, lat0, lon0, h0, spheroid);
    [lat,lon,h] = ecef2geodetic(spheroid,X,Y,Z);
end


function [x, y] = intrinsicToLocal(xMesh, yMesh, ...
    xIntrinsic, yIntrinsic, reverseVertexOrder)
% Convert intrinsic raster coordinates to the external system defined by
% (xMesh, yMesh).

    indx = isnan(xIntrinsic);
    xIntrinsic(indx) = 1;
    yIntrinsic(indx) = 1;

    x = interp2(xMesh, xIntrinsic, yIntrinsic, '*linear');
    y = interp2(yMesh, xIntrinsic, yIntrinsic, '*linear');

    x(indx) = NaN;
    y(indx) = NaN;
    
    if reverseVertexOrder
        [x, y] = reverseVerticesPartByPart(x, y);
    end
end


function levelList = constructLevelList(Z)
    k = find(isfinite(Z));
    zmax = double(max(Z(k)));
    zmin = double(min(Z(k)));
    levelStep = map.internal.selectContourLevelStep(zmin, zmax);
    levelList = map.internal.constructContourLevelList(zmin, zmax, levelStep);
end

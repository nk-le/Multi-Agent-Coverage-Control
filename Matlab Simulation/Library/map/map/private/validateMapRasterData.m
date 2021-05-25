function [Z, SpatialRef, displayType, HGpairs] = validateMapRasterData( ...
    mapfcnname, dataArgs, displayType, HGpairs)
%VALIDATEMAPRASTERDATA Validate mapraster data for display
%
%   [Z, SpatialRef, displayType, HGpairs] = validateMapRasterData(
%   mapfcnname, dataArgs, displayType HGpairs) validates the data in
%   dataArgs and returns Z, the matrix to be displayed, SpatialRef, the
%   spatial referencing information, the display type, and updated HGpairs.
%   MAPFCNNAME is the name of the calling function and is used to create
%   error messages. DATAARGS is a cell array containing input data
%   arguments. DATAARGS must conform to the output of PARSERASTERINPUTS.
%   DISPLAYTYPE is a string with value 'mesh', 'surface', 'contour',
%   'image'. HGpairs is a cell array containing parameter/value pairs for
%   the display function.
%
%   See also MAPRASTERSHOW, PARSERASTERINPUTS, READMAPDATA.

% Copyright 2010-2018 The MathWorks, Inc.

% Build the rules for parsing the data arguments.
[dataArgs, componentType, rules] = buildRules(dataArgs, displayType);

% Validate the component data.
switch componentType
    case 'Image'
        [Z, SpatialRef] =  validateImageComponent(mapfcnname, ...
            dataArgs, displayType, rules);
        
    case 'Grid'
        [Z, SpatialRef] = validateGridComponent(mapfcnname, ...
            dataArgs, displayType, rules);
        
    case 'Texture'
        [dataArgs, R, imageIndex, rules] = validateTextureComponent( ...
            mapfcnname, dataArgs, displayType, rules);
        
        [Z, SpatialRef, displayType] = buildMapTextureComponent( ...
            dataArgs,  rules, R, imageIndex);
        
        % Add the texture map HG pairs.
        HGpairs = addTextureMapPairs(HGpairs, dataArgs{imageIndex});
end

%--------------------------------------------------------------------------

function [dataArgs, componentType, rules] = ...
    buildRules(dataArgs, displayType)
% Build logical rules for parsing the data arguments.

% Get the type of component data: 'Grid', 'Texture', or 'Image'
validDisplayTypes = {'mesh','surface','contour','texturemap','image'};
componentTypes    = {'Grid','Grid',   'Grid',   'Texture',   'Image'};
componentType = componentTypes{strcmp(displayType, validDisplayTypes)};

% Rule for determining if the image syntax contains rotational R
isImageComponent = strcmp('Image',componentType);
[dataArgs, rules.numArgs] = ...
    checkImageRotationalR(isImageComponent, dataArgs, numel(dataArgs));

% Rule for determining if the image syntax contains C1, C2 input
isImageC1C2 = isImageComponent && rules.numArgs == 3 && ...
    numel(dataArgs{3}) > 6 && size(dataArgs{2},3) ~= 3;
rules.isImageC1C2 = rules.numArgs == 4 || isImageC1C2;

% Rules for C1, C2 name
rules.C1 = 'X';
rules.C2 = 'Y';
rules.posC1C2 = [1,2];

% Rule for requiring a texture mapped surface
rules.isTextureMap = rules.isImageC1C2;
if rules.isTextureMap
    componentType = 'Texture';
end

% Using map coordinates
rules.isGeoCoord = false;

%--------------------------------------------------------------------------

function [A, R] = validateImageComponent( ...
    mapfcnname, dataArgs, displayType, rules)
% Validate image component.

checkmapnargin(2,3,rules.numArgs,mapfcnname,displayType);
switch rules.numArgs
    case 2
        % (I,  R)
        % (BW, R)
        % (RGB,R)
        cmap = [];
        [A, R] = parseImageInputs(mapfcnname, dataArgs{:}, cmap, rules );
        
    case 3
        % (X, CMAP, R)
        [A, R] = parseImageInputs(mapfcnname, dataArgs{[1,3,2]}, rules);
end

%--------------------------------------------------------------------------

function [A, refmat] = parseImageInputs(mapfcnname, A, R, cmap, rules)
% Parse the image input and return A, the image, and refmat a referencing
% matrix. If A is an indexed image, it will be converted to a uint8 RGB
% image using the supplied color map, CMAP. If A is class logical, it will
% be converted to a uint8 RGB image.

R_position = rules.numArgs;
validateattributes(A, {'uint8', 'uint16', 'double', 'logical'}, ...
    {'real', 'nonsparse', 'nonempty'}, ...
    mapfcnname, 'I or X or RGB', 1);

refmat = checkRefObj(mapfcnname, R, size(A), R_position);

% If R is a raster referencing object and the RasterInterpretation is
% 'postings', then issue an error.
if isobject(R) && strcmp(R.RasterInterpretation, 'postings')
    error('map:rastershow:postingsWithTexture', ...
        ['The raster referencing object, %s, is defined with raster ', ...
        'interpretation set to ''%s'' which is not supported when the ''%s'' ' ...
        'parameter is set to ''%s''. To display this data, ', ...
        'set the ''%s'' parameter to ''%s'', ''%s'', or ''%s''.'], ...
        'R', 'postings', 'DisplayType', 'image', 'DisplayType', ...
        'surface', 'mesh', 'contour');
end

% Validate the image, A.
A = checkImage(mapfcnname, A, cmap, 1, 2, R);

%--------------------------------------------------------------------------

function [Z, SpatialRef, displayType] = buildMapTextureComponent( ...
    dataArgs,  rules, R, imageIndex)
% Create a zero-valued Z matrix with corresponding spatial referencing
% information.

displayType = 'surface';
if ~rules.isImageC1C2
    % Get the size of the image (which may be an RGB image).
    sz = size(dataArgs{imageIndex});
    
    % Create a mesh of the pixel edges.
    [SpatialRef.XMesh, SpatialRef.YMesh] = pixedges(R, sz);
    
    % The Z values for the texture map will be the same size as the edge
    % grid.
    sz = size(SpatialRef.XMesh);
else
    % Using C1, C2 syntax
    [SpatialRef.XMesh, SpatialRef.YMesh] = deal(dataArgs{1:2});
    if isequal(size(SpatialRef.XMesh), size(SpatialRef.YMesh))
        sz = size(SpatialRef.XMesh);
    else
        if isvector(SpatialRef.XMesh) && isvector(SpatialRef.YMesh)
            sz = [numel(SpatialRef.YMesh), numel(SpatialRef.XMesh)];
        else
            sz = size(dataArgs{imageIndex});
        end
    end
end

% Create a zero-valued matrix.
Z = zeros(sz);

%--------------------------------------------------------------------------

function HGpairs = addTextureMapPairs(HGpairs, A)
% Add texturemap to the HGpairs cell array.

HGpairs{end+1} = 'CData';
HGpairs{end+1} = A;
HGpairs{end+1} = 'FaceColor';
HGpairs{end+1} = 'texturemap';

%--------------------------------------------------------------------------

function [Z, SpatialRef] = ...
    validateGridComponent(mapfcnname, dataArgs, displayType, rules)
% Validate grid component data.

checkmapnargin(2,3,rules.numArgs,mapfcnname,displayType);

if rules.numArgs == 2
    [Z, SpatialRef] = checkRegularDataGrid(dataArgs{:}, mapfcnname);
else
    require2D = true;
    [SpatialRef.XMesh, SpatialRef.YMesh, Z] = ...
        checkGeolocatedDataGrid(dataArgs{:}, rules, mapfcnname, require2D);
end

% surface requires ZData to be double.
if isa(Z, 'single')
    Z = double(Z);
end

%--------------------------------------------------------------------------

function [x,y] = pixedges(R, sizeA)
% Compute pixel edges for georeferenced image or data grid
%
%   [X, Y] = PIXEDGES(R, SIZEA) computes the edge coordinates for each
%   pixel in a georeferenced image or regular gridded data set.  R is a
%   3-by-2 affine referencing matrix.  SIZEA is size of the image. Its
%   first two elements are HEIGHT and WIDTH.  X and Y are each a
%   (HEIGHT+1)-by-(WIDTH+1) matrix such that X(COL, ROW), Y(COL, ROW) are
%   the map coordinates of the edge of the pixel with subscripts (ROW,COL).

% Obtain the height and width.
height = sizeA(1);
width  = sizeA(2);

% Compute the row, column grid.
xGrid = .5 + (0:height);
yGrid = .5 + (0:width);
[r,c] = ndgrid(xGrid,yGrid);

% Convert the row and columns to x and y.
[x,y] = pix2map(R,r,c);

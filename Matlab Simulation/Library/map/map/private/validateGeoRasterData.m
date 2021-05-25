function [Z, SpatialRef, displayType] = validateGeoRasterData( ...
   geofcnname, dataArgs, displayType)
%VALIDATEGEORASTERDATA Validate georaster data for display
%
%   [Z, SpatialRef, displayType] = validateGeoRasterData(geofcnname,
%   dataArgs, displayType) validates the data in dataArgs and returns Z,
%   the matrix to be displayed, SpatialRef, the spatial referencing
%   information, and the display type. GEOFCNNAME is the name of the
%   calling function and is used to create error messages. DATAARGS is a
%   cell array containing input data arguments. DATAARGS must conform to
%   the output of PARSERASTERINPUTS. DISPLAYTYPE is a string with value
%   'mesh', 'surface', 'contour', 'image'.
%
%   See also GEORASTERSHOW, PARSERASTERINPUTS, READMAPDATA.

% Copyright 2010 The MathWorks, Inc.

% Build the rules for parsing the data arguments.
[dataArgs, rules] = buildRules(dataArgs, displayType);

% Validate the component data.
if rules.isTextureMapType
    [dataArgs, R, imageIndex, rules] = validateTextureComponent( ...
        geofcnname, dataArgs, displayType, rules);
    
    [Z, SpatialRef, displayType] = getTextureComponent( ...
        dataArgs, rules, R, imageIndex);   
else
    [Z, SpatialRef] = validateGridComponent(geofcnname, ...
        dataArgs, displayType, rules);  
end

%--------------------------------------------------------------------------

function [dataArgs, rules] = buildRules(dataArgs, displayType)
% Build the logical rules for parsing the data arguments.

% Rule for requiring a texture mapped surface
rules.isTextureMapType = any(strcmp(displayType, {'image', 'texturemap'}));

% Rule for determining if the image syntax contains rotational R
isImageType = strcmp('image', displayType);
[dataArgs, rules.numArgs] = ...
    checkImageRotationalR(isImageType, dataArgs, numel(dataArgs));

% Rule for determining if the image syntax contains C1, C2 input
isImageC1C2 = isImageType && rules.numArgs == 3 && ...
   numel(dataArgs{3}) > 6 && size(dataArgs{2},3) ~= 3;
rules.isImageC1C2 = rules.numArgs == 4 || isImageC1C2;

% Rules for C1, C2 name
rules.C1 = 'LAT';
rules.C2 = 'LON';
rules.posC1C2 = [1,2];

% Using geographic coordinates.
rules.isGeoCoord = true;

%--------------------------------------------------------------------------

function [Z, SpatialRef, displayType] = getTextureComponent( ...
         dataArgs, rules, R, imageIndex)
% Obtain the texture component data, (Z, SpatialRef) from dataArgs.
% displayType needs to be set to 'texturemap' since it may have been set to
% 'image'.

displayType = 'texturemap';
if ~rules.isImageC1C2
    % Using Z, R syntax
    Z = dataArgs{imageIndex};
    SpatialRef = R;
else
    % Using C1, C2, Z syntax
    [SpatialRef.LatMesh, SpatialRef.LonMesh, Z] = ...
        deal(dataArgs{1}, dataArgs{2}, dataArgs{imageIndex});
end

%--------------------------------------------------------------------------

function [Z, SpatialRef] = validateGridComponent( ...
   geofcnname, dataArgs, displayType, rules)
% Validate grid component data.

checkmapnargin(2,3,rules.numArgs,geofcnname,displayType);

if rules.numArgs == 2
    [Z, SpatialRef] = checkRegularDataGrid(dataArgs{:}, geofcnname);
else
    require2D = true;
    [SpatialRef.LatMesh, SpatialRef.LonMesh, Z] = ...
        checkGeolocatedDataGrid(dataArgs{:}, rules, geofcnname, require2D);
end

% surface requires ZData to be double.
if isa(Z, 'single')
    Z = double(Z);
end

function [dataArgs, numArgs] = ...
    checkImageRotationalR(isImage, dataArgs, numArgs)
%CHECKIMAGEROTATIONALR Update dataArgs if R is not rectilinear
%
%   [dataArgs, numArgs] = checkImageRotationalR(isImage, dataArgs, numArgs)
%   checks if dataArgs contains an image and a referencing matrix  or
%   object that is not rectilinear. dataArgs must have one of the following
%   forms:
%      {}, {I}, {I, R}, {I, CMAP, R}, {C1, C2, I}, or {C1, C2, I, CMAP}.
%   dataArgs is changed only under the following conditions: I is an image
%   and R is a non-rectilinear reference matrix or object. In this case, {I, R} is
%   replaced with {C1, C2, I} and {I, CMAP, R} is replaced with
%   {C1, C2, I, CMAP}. A referencing matrix R is non-rectilinear if it has
%   any non-zero diagonal elements. A raster reference object is
%   non-rectilinear if its TransformationType property value is 'affine'.

% Copyright 2010-2020 The MathWorks, Inc.

twoOrThreeArgs = numArgs == 2 || numArgs == 3;
isRefMat = isequal(size(dataArgs{numArgs}),[3 2]);
isRefObj = isa(dataArgs{numArgs},'map.rasterref.MapRasterReference');
if isImage && twoOrThreeArgs && ...
        ((isRefMat && any(diag(dataArgs{numArgs}))) ...
        || (isRefObj && strcmp(dataArgs{numArgs}.TransformationType, 'affine')))
    
    % Syntax: (I, R) or (I, CMAP, R)
    % R is rotational, create new dataArgs
    R = refmatToMapRasterReference(dataArgs{numArgs}, size(dataArgs{1}));
    [C1, C2] = worldGrid(R);
    
    % Remove R
    dataArgs(numArgs) = [];
    
    % New dataArgs: (C1, C2, I, ...)
    dataArgs = [{C1}, {C2}, dataArgs];
    numArgs = numArgs + 1;
end

function [c1, c2, Z] = ...
    checkGeolocatedDataGrid(c1, c2, Z, rules, fcnName, require2D)
%CHECKGEOLOCATEDDATAGRID Check geolocated data grid inputs
%
%   [C1, C2, Z] = checkGeoLocatedDataGrid(C1, C2, Z, RULES, fcnName,
%   require2D) validates the geolocated data grid, defined by the inputs,
%   C1, C2, and Z. RULES is a structure containing fields C1, C2, and
%   posC1C2 which define the names and positions of the C1 and C2 inputs,
%   and isGeoCoord which is a logical and true when C1 and C2 refer to
%   latitude and longitude coordinates. fcnName is used for constructing an
%   error message. require2D is a logical and true if Z is required to be 
%   two-dimensional.

% Copyright 2010-2011 The MathWorks, Inc.

% Validate coordinate arrays.
attributes = {'real', 'nonempty', '2d'};
validateattributes(c1,{'numeric'}, attributes, fcnName, rules.C1, rules.posC1C2(1))
validateattributes(c2,{'numeric'}, attributes, fcnName, rules.C2, rules.posC1C2(2))

% Validate Z.
if require2D
    validateattributes(Z, {'numeric'}, attributes, fcnName, 'Z', 3)
    checkMatrixSizes(c1, c2, size(Z), rules.isGeoCoord);
else
    validateattributes(Z, {'numeric'}, {'real', 'nonempty'}, fcnName, 'Z', 3)
    if isequal(size(c1),size(c2))
        sz = size(c1);
    else
        if isvector(c1) && isvector(c2)
            sz = [numel(c2), numel(c1)];
        else
            sz = size(Z);
        end
    end
    checkMatrixSizes(c1, c2, sz, rules.isGeoCoord);
end

%--------------------------------------------------------------------------

function checkMatrixSizes(x, y, sizeZ, isGeoCoord)
% Validate sizes of x and y
%
%   checkMatrixSizes(X, Y, SIZEZ, isGeoCoord) validates that the length of
%   X matches SIZEZ(2) and the length of Y matches SIZEZ(1). If not, then
%   the size of X and Y must match SIZEZ. isGeoCoord is a logical and if
%   true constructs the string 'LAT and LON' otherwise the string 'X and Y'
%   is constructed if an error message is issued.

if (numel(x) ~= sizeZ(2) || numel(y) ~= sizeZ(1)) ...
        && (~isequal(size(x),size(y)) || ~isequal(size(x),sizeZ))
    if isGeoCoord
        error('map:checkMatrixSizes:invalidCoordinateDimensions', ...
           '%s and %s dimensions do not agree with Z.','LAT','LON')
    else
        error('map:checkMatrixSizes:invalidCoordinateDimensions', ...
           '%s and %s dimensions do not agree with Z.','X','Y')
    end
end

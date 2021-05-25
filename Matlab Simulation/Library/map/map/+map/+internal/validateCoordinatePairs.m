function validateCoordinatePairs(u, v, funcname, varname1, varname2)
%validateCoordinatePairs Validate pairwise coordinate variables
%
% Validate a pair of coordinate arrays, ensuring that they contain real
% values, class double or single, and match in size. In addition ensure
% that for every NaN-valued element in the first array there is an
% identically-positioned NaN-valued element in the second array, and
% vice versa.

% Copyright 2010-2012 The MathWorks, Inc.

validateattributes(u, {'single','double'}, {'real'}, funcname, varname1)
validateattributes(v, {'single','double'}, {'real'}, funcname, varname2)

map.internal.assert(isequal(size(u),size(v)), ...
    'map:spatialref:sizeMismatchInCoordinatePairs',...
    funcname, varname1, varname2)

map.internal.assert(isequal(isnan(u),isnan(v)), ...
    'map:spatialref:mismatchedNaNsInCoordinatePairs', ...
    funcname, varname1, varname2)

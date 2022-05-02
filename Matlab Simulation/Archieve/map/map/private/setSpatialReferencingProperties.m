function R = setSpatialReferencingProperties(R, nvpairs, validnames, fcnname)
% Set specified properties of a spatial referencing object.
%
%   R -- A geographic raster reference object or map raster reference object
%
%   nvpairs -- A cell vector of property name-value pairs
%
%   validnames -- A list of valid property names
%
%   fcnname -- Name of calling function, for use in error messages

% Copyright 2010-2017 The MathWorks, Inc.

n = numel(nvpairs);
if n > 0
    % Number name-value must be even.
    assert(mod(n,2) == 0, ...
        'map:spatialref:expectedEvenNumberOfInputs', ...
        'Function %s expected an even number of input arguments.', ...
        fcnname)

    % Ensure that odd-numbered elements of nvpairs are strings.
    propertyNames = nvpairs(1:2:end);
    [propertyNames{:}] = convertStringsToChars(propertyNames{:});
    nonchar = find(~cellfun(@ischar,propertyNames));
    if ~isempty(nonchar)
        argnum = 2*nonchar(1) - 1;
        error('map:spatialref:expectedPropertyNameString', ...
            'Function %s expected argument %d to be a property name string instead of class %s.', ...
            fcnname, argnum, class(propertyNames{nonchar(1)}))
    end
    
    % Validate property name strings and set properties one by one.
    for k = 1:2:n
        name  = validatestring(nvpairs{k}, validnames, ...
            fcnname, '', k);
        value = nvpairs{k + 1};
        R.(name) = value;
    end
end

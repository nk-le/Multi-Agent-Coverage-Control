function mustBeCRS(crs)
% Validate that crs is a potential coordinate reference system input

% Copyright 2020 The MathWorks, Inc.

    if isnumeric(crs)
        mustBeInteger(crs)
        mustBePositive(crs)
        mustBeScalarOrEmpty(crs)
    elseif ischar(crs) || isstring(crs)
        mustBeTextScalar(crs)
        mustBeNonzeroLengthText(crs)
    else
        error(message("map:crs:MustBeCoordinateReferenceSystem"))
    end
end
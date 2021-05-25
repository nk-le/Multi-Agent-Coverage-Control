function R = checkRefObj(func_name, R, rasterSize, posR)
%CHECKREFOBJ Validate referencing vector, matrix, or object
%
%   R = checkRefObj(FUNC_NAME, R, rasterSize, POSR) returns a validated
%   referencing matrix in R. The input R may be a referencing vector,
%   matrix, or object. If R is a referencing vector or object, it is
%   converted to a referencing matrix. rasterSize is the size of the
%   corresponding raster for R. POSR is the argument position for R.

% Copyright 2010-2020 The MathWorks, Inc.

    try
        if numel(R) == 3
            R = map.internal.referencingVectorToMatrix(R, rasterSize);
        else
            % Validate R. It must be a 3-by-2 matrix of real-valued finite doubles,
            % a map raster reference object for use with mapshow, or a geographic
            % raster reference object for use with geoshow.
            if strcmp(func_name, 'mapshow')
                type = {'planar'};
            else
                type = {'geographic'};
            end
            var_name = 'R';
            map.rasterref.internal.validateRasterReference(R, type, ...
                func_name, var_name, posR)
            if isobject(R)
                R = map.internal.referencingMatrix(R.worldFileMatrix());
            end
        end
    catch e
        throw(e)
    end
end

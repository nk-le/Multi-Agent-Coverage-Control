function validateRasterReference(R, ...
    coordinateSystemTypes, func_name, var_name, arg_pos)
%validateRasterReference Validate referencing matrix or object
%
%   validateRasterReference(R, TYPES, FUNC_NAME, VAR_NAME, ARG_POS)
%   ensures that R is either a valid referencing matrix or a scalar object.
%   If R is a referencing object, its CoordinateSystemType must match the
%   types specified.
%
%   The coordinateSystemTypes input can be a string or cell array. As a
%   string, it can equal 'geographic' or 'planar'.  As a cell array, it can
%   contain either or both these values, or it can be empty.
%
%   Examples
%   --------
%   % Wrong size
%   clear R; R(4,5,6) = 0;
%   map.rasterref.internal.validateRasterReference(R, ...
%       {'geographic','planar'}, 'MY_FUNC', 'MY_VAR', 1)
%
%   % 3-by-2, but wrong type
%   R = zeros([3 2], 'uint8');
%   map.rasterref.internal.validateRasterReference(R, ...
%       'planar', 'MY_FUNC', 'MY_VAR', 1)
%
%   % Non-finite 3-by-2 double
%   R = [0 1; 1 0; -Inf 200];
%   map.rasterref.internal.validateRasterReference(R, ...
%       'planar', 'MY_FUNC', 'MY_VAR', 1)
%
%   % 3-by-2 complex double
%   R = [0 1; 1i 0; -100 200];
%   map.rasterref.internal.validateRasterReference(R, ...
%       'planar', 'MY_FUNC', 'MY_VAR', 1)
%
%   % Non-scalar object
%   R = georasterref(); R(2) = georasterref();
%   map.rasterref.internal.validateRasterReference(R, ...
%       'geographic', 'MY_FUNC', 'MY_VAR', 1)
%
%   % Unexpected type
%   R = georasterref();
%   map.rasterref.internal.validateRasterReference(R, ...
%       'planar', 'MY_FUNC', 'MY_VAR', 1)
%
%   % Both types accepted: no exception thrown
%   R = maprasterref();
%   map.rasterref.internal.validateRasterReference(R, ...
%       {'geographic','planar'}, 'MY_FUNC', 'MY_VAR', 1)
%
%   % No objects are accepted, but an object is input
%   % (Validate strictly as referencing matrix.)
%   R = georasterref();
%   map.rasterref.internal.validateRasterReference(R, {}, 'MY_FUNC', 'MY_VAR', 1)
%
%   % No objects are accepted, and input is a valid referencing matrix
%   R = [0 1; -1 0; 100 200];
%   map.rasterref.internal.validateRasterReference(R, {}, 'MY_FUNC', 'MY_VAR', 1)

% Copyright 2010-2013 The MathWorks, Inc.

if ~isobject(R) || isempty(coordinateSystemTypes)
    % Validate referencing matrix. It must be a 3-by-2 matrix of real-valued
    % finite doubles.
    if ~isequal(size(R),[3,2])
        sizestr = sprintf('%dx', size(R));
        sizestr(end) = [];
        msg2 = sprintf('Instead its size was %s.', sizestr);
        if isempty(coordinateSystemTypes)
            throwAsCaller(MException('map:validate:expectedReferencingMatrix', ...
                'Function %s expected input number %d, %s, to a 3-by-2 referencing matrix. %s', ...
                func_name, arg_pos, var_name, msg2))
        else
            throwAsCaller(expectedReferencingMatrixOrObject( ...
                coordinateSystemTypes, func_name, var_name, arg_pos, msg2))
        end
    end
    
    % If we reach this line, we know for certain that R is 3-by-2. We'll
    % assume that a referencing matrix was intended (rather than an
    % object) and phrase the error messages accordingly.
    try
        validateattributes(R, {'double'} ,{'real','finite'}, ...
            func_name, var_name, arg_pos)
    catch exception
        mnemonic = extract_mnemonic(exception.identifier, func_name);
        switch mnemonic
            
            case 'invalidType'
                throwAsCaller(MException('map:validate:expectedClassDoubleRefmat', ...
                    'Function %s expected input number %d, %s, a 3-by-2 referencing matrix, to be class %s.', ...
                    func_name, arg_pos, var_name, 'double'))
                
            case 'expectedFinite'
                throwAsCaller(MException('map:validate:expectedFiniteRefmat', ...
                    'Function %s expected input number %d, %s, a 3-by-2 referencing matrix, to contain finite values.', ...
                    func_name, arg_pos, var_name))
                
            case 'expectedReal'
                throwAsCaller(MException('map:validate:expectedRealRefmat', ...
                    'Function %s expected input number %d, %s, a 3-by-2 referencing matrix, to contain real values.', ...
                    func_name, arg_pos, var_name))
                
            otherwise
                % We don't expect to reach this line.
                rethrow(exception)
        end
    end
else
    % Validate scalar object. Its type must match one of the classes
    % listed in CLASSES.
    try
        classes = rasterReferencingClasses(coordinateSystemTypes);
        validateattributes(R, classes, {'scalar'}, func_name, var_name, arg_pos)
    catch exception
        mnemonic = extract_mnemonic(exception.identifier, func_name);
        switch mnemonic
            
            case 'expectedScalar'
                sizestr = sprintf('%dx', size(R));
                sizestr(end) = [];
                msg2 = sprintf('Instead its size was %s.', sizestr);
                throwAsCaller(expectedReferencingMatrixOrObject( ...
                    coordinateSystemTypes, func_name, var_name, arg_pos, msg2))
                
            case 'invalidType'
                msg2 = sprintf('Instead its type was: %s.', class(R));
                throwAsCaller(expectedReferencingMatrixOrObject( ...
                    coordinateSystemTypes, func_name, var_name, arg_pos, msg2))
                
            otherwise
                % We don't expect to reach this line.
                rethrow(exception)
        end
    end
end

%-----------------------------------------------------------------------------

function classes = rasterReferencingClasses(types)
% Return a list of raster reference class names given list of coordinate
% system types

classes = {};
if any(strncmpi(types,'planar',numel(types)))
    classes{1,end+1} = 'map.rasterref.MapCellsReference';
    classes{1,end+1} = 'map.rasterref.MapPostingsReference';
end

if any(strncmpi(types,'geographic',numel(types)))
    classes{1,end+1} = 'map.rasterref.GeographicCellsReference';
    classes{1,end+1} = 'map.rasterref.GeographicPostingsReference';
end

%-----------------------------------------------------------------------------

function exception = expectedReferencingMatrixOrObject( ...
    types, func_name, var_name, arg_pos, msg2)
% Construct MException describing expected input.

planar = any(strncmpi(types,'planar',numel(types)));
geographic = any(strncmpi(types,'geographic',numel(types)));
if planar && geographic
    classes = 'map raster reference or geographic raster reference';
elseif planar
    classes = 'map raster reference';
else
    classes = 'geographic raster reference';
end

exception = MException('map:validate:expectedReferencingMatrixOrObject', ...
    'Function %s expected input number %d, %s, to be either a 3-by-2 referencing matrix or a scalar %s object. %s', ...
    func_name, arg_pos, var_name, classes, msg2);

%-----------------------------------------------------------------------------

function mnemonic = extract_mnemonic(identifier, func_name)
n = numel(['MATLAB:' func_name ':']);
mnemonic = identifier(n+1:end);

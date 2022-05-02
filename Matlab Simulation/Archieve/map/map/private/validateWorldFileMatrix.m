function W = validateWorldFileMatrix(W, func_name, var_name, arg_pos)
% Validate a world file matrix, W. It must be a 2-by-3 matrix of
% real-valued finite doubles. The 2-by-2 Jacobian sub-matrix,
% J = W(:,1:2), must have a nonzero determinant.

% Copyright 2010 The MathWorks, Inc.

% If W has 6 elements, it could be a 6-by-1 vector. That's OK, but
% reshape it before validating its size.
if numel(W) == 6
    W = reshape(W, [2 3]);
end

% Check the size. This could be done below using validateattributes, but
% we can give more helpful messages if we first check for size only.
if ~isequal(size(W),[2,3])
    sizestr = sprintf('%dx', size(W));
    sizestr(end) = [];
    throwAsCaller(MException('map:validate:expectedWorldFileMatrix', ...
        'Function %s expected input number %d, %s, to a 6-element world file matrix. Instead its size was %s.', ...
        func_name, arg_pos, var_name, sizestr))
end

% If we reach this line, we know for certain that W is 2-by-3. We'll
% assume that a world file matrix was intended and phrase the error
% messages accordingly.
try
    validateattributes(W, {'double'} ,{'real','finite'}, ...
        func_name, var_name, arg_pos)
catch exception
    mnemonic = extract_mnemonic(exception.identifier, func_name);
    switch mnemonic
        
        case 'invalidType'
            throwAsCaller(MException('map:validate:expectedClassDoubleWorldFileMatrix', ...
                'Function %s expected input number %d, %s, a 2-by-3 world file matrix, to be class %s.', ...
                func_name, arg_pos, var_name, 'double'))
            
        case 'expectedFinite'
            throwAsCaller(MException('map:validate:expectedFiniteWorldFileMatrix', ...
                'Function %s expected input number %d, %s, a 2-by-3 world file matrix, to contain finite values.', ...
                func_name, arg_pos, var_name))
            
        case 'expectedReal'
            throwAsCaller(MException('map:validate:expectedRealWorldFileMatrix', ...
                'Function %s expected input number %d, %s, a 2-by-3 world file matrix, to contain real values.', ...
                func_name, arg_pos, var_name))
            
        otherwise
            % We don't expect to reach this line.
            rethrow(exception)
    end
end

% Validate Jacobian sub-matrix (the first 2 columns of W).
J = W(:,1:2);
if det(J) == 0
    throwAsCaller(MException('map:validate:expectedNonSingularWorldFileMatrix', ...
        'Function %s expected input number %d, %s, a 2-by-3 world file matrix, to be non-singular.', ...
        func_name, arg_pos, var_name))
end

%-----------------------------------------------------------------------------

function mnemonic = extract_mnemonic(identifier, func_name)
n = numel(['MATLAB:' func_name ':']);
mnemonic = identifier(n+1:end);

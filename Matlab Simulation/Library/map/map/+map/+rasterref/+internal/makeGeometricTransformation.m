function T = makeGeometricTransformation(tiePointIntrinsic, ...
    tiePointWorld, jacobianNumerator, jacobianDenominator)
%makeGeometricTransformation Construct geometric transformation object
%
%   T = makeGeometricTransformation(tiePointIntrinsic, ...
%   tiePointWorld, jacobianNumerator, jacobianDenominator) constructs a
%   geometric transformation object from the following inputs:
%
%   tiePointIntrinsic - A vector of the form [xTieIntrinsic yTieIntrinsic]
%   tiePointWorld - A vector of the form [xTieWorld yTieWorld]
%   jacobianNumerator - Numerator of 2-by-2 Jacobian matrix
%   jacobianDenominator - Denominator of 2-by-2 Jacobian matrix
%
%   If the Jacobian matrix J = jacobianNumerator ./ jacobianDenominator is
%   diagonal, then T is a map.rasterref.internal.RectilinearTransformation
%   object. Otherwise, T is a map.rasterref.internal.AffineTransformation
%   object.

% Copyright 2010-2013 The MathWorks, Inc.

% Assume valid tie point vectors, but validate Jacobian matrix properties.
validateattributes(jacobianNumerator, {'double'}, ...
    {'real', 'finite', 'size', [2 2]}, ...
   'makeGeometricTransformation', 'jacobianNumerator')

validateattributes(jacobianDenominator, {'double'}, ...
    {'real', 'finite', 'positive', 'size', [2 2]}, ...
    'makeGeometricTransformation', 'jacobianDenominator')

map.internal.assert(det(jacobianNumerator./jacobianDenominator) ~= 0, ...
    'map:spatialref:singularJacobian', ...
    'jacobianNumerator ./ jacobianDenominator')

% Check to see if the Jacobian matrix is diagonal. We already know that its
% determinant is nonzero, so it's sufficient to check that the off-diagonal
% elements are zero.
isDiagonal = isequal(jacobianNumerator([2 3]),[0 0]);

% Initialize transformation object.
if isDiagonal
    T = map.rasterref.internal.RectilinearTransformation();
else
    T = map.rasterref.internal.AffineTransformation();
end

% Assign property values.
T.TiePointIntrinsic = tiePointIntrinsic;
T.TiePointWorld     = tiePointWorld;
T.Jacobian = struct( ...
    'Numerator', jacobianNumerator, 'Denominator', jacobianDenominator);

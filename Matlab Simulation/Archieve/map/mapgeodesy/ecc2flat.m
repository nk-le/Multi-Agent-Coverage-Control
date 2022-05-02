function f = ecc2flat(ecc)
%ECC2FLAT Flattening of ellipse from eccentricity
%
%   Support for nonscalar input, including the syntax
%   f = ECC2FLAT(ellipsoid), will be removed in a future release.
%
%   f = ECC2FLAT(ecc) computes the flattening of an ellipse (or ellipsoid
%   of revolution) given its eccentricity ecc.  Except when the input has 2
%   columns (or is a row vector), each element is assumed to be an
%   eccentricity and the output f has the same size as ecc.
%
%   f = ECC2FLAT(ellipsoid), where ellipsoid has two columns (or is a row
%   vector), assumes that the eccentricity is in the second column, and a
%   column vector is returned.
%
%   See also FLAT2ECC, ECC2N, MAJAXIS, MINAXIS, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.

if min(size(ecc)) == 1 && ndims(ecc) <= 2
    % First col if scalar or column vector input
    % Second col if two column input or row vector
    col = min(size(ecc,2), 2);
    ecc = ecc(:,col);
end

%  Ensure real inputs
ecc = ignoreComplex(ecc, mfilename, 'eccentricity');

% Compute the flattening. The formula used below is the algebraic
% equivalent of the more obvious formula, f = 1 - sqrt(1 - e2), but
% affords better numerical precision because it avoids taking the
% difference of two O(1) quantities.
e2 = ecc.^2;
f = e2 ./ (1 + sqrt(1 - e2));

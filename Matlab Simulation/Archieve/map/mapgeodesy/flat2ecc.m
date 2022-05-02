function ecc = flat2ecc(f)
%FLAT2ECC Eccentricity of ellipse from flattening
%
%   Support for nonscalar input, including the special two-column syntax
%   described below, will be removed in a future release.
%
%   ecc = FLAT2ECC(f) computes the eccentricity of an ellipse (or ellipsoid
%   of revolution) given its flattening f.  Except when the input has 2
%   columns (or is a row vector), each element is assumed to be a
%   flattening and the output ecc has the same size as f.
%
%   ecc = FLAT2ECC(f), where f has two columns (or is a row vector),
%   assumes that the second column is a flattening, and a column vector is
%   returned.
%
%   See also AXES2ECC, ECC2FLAT, N2ECC, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.

if min(size(f)) == 1 && ndims(f) <= 2
    % First col if scalar or column vector input
    % Second col if two column input or row vector
    col = min(size(f,2), 2);
    f = f(:,col);
end

%  Ensure real inputs
f = ignoreComplex(f, mfilename, 'flattening');

%  Compute the eccentricity
ecc = sqrt(f .* (2 - f));

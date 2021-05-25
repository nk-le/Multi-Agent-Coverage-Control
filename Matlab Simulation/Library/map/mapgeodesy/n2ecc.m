function ecc = n2ecc(n)
%N2ECC  Eccentricity of ellipse from third flattening
%
%   Support for nonscalar input, including the special two-column syntax
%   described below, will be removed in a future release.
%
%   ecc = N2ECC(n) computes the eccentricity of an ellipse (or ellipsoid
%   of revolution) given the parameter n (the "third flattening").  n is
%   defined as (a-b)/(a+b), where a is the semimajor axis and b is the
%   semiminor axis.  Except when the input has 2 columns (or is a row
%   vector), each element is assumed to be a third flattening and the
%   output ecc has the same size as n.
%
%   ecc = N2ECC(n), where n has two columns (or is a row vector), assumes
%   that the second column is a third flattening, and a column vector is
%   returned.
%
%   See also AXES2ECC, ECC2N, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.

if min(size(n)) == 1 && ndims(n) <= 2
    % First col if scalar or column vector input
    % Second col if two column input or row vector
    col = min(size(n,2), 2);
    n = n(:,col);
end

%  Ensure real inputs
n = ignoreComplex(n, mfilename, 'n');

%  Compute the eccentricity
ecc = sqrt( 4*n ./ (1+n).^2 );

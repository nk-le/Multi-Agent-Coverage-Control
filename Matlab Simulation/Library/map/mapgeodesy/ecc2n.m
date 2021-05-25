function n = ecc2n(ecc)
%ECC2N  Third flattening of ellipse from eccentricity
%
%   Support for nonscalar input, including the syntax
%   n = ECC2N(ellipsoid), will be removed in a future release.
%
%   n = ECC2N(ecc) computes the parameter n (the "third flattening") of an
%   ellipse (or ellipsoid of revolution) given its eccentricity ecc.  n is
%   defined as (a-b)/(a+b), where a is the semimajor axis and b is the
%   semiminor axis.  Except when the input has 2 columns (or is a row
%   vector), each element is assumed to be an eccentricity and the output n
%   has the same size as ecc.
%
%   n = ECC2N(ellipsoid), where ellipsoid has two columns (or is a row
%   vector), assumes that the eccentricity is in the second column, and a
%   column vector is returned.
%
%   See also ECC2FLAT, MAJAXIS, MINAXIS, N2ECC, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.

if min(size(ecc)) == 1 && ndims(ecc) <= 2
    % First col if scalar or column vector input
    % Second col if two column input or row vector
    col = min(size(ecc,2), 2);
    ecc = ecc(:,col);
end

%  Ensure real inputs
ecc = ignoreComplex(ecc, mfilename, 'eccentricity');

%  Compute n. The formula used below is the algebraic equivalent of the
%  more obvious formula, n = (1 - sqrt(1 - e2)) ./ (1 + sqrt(1 - e2)), but
%  affords better numerical precision because it avoids taking the
%  difference of two O(1) quantities.
e2 = ecc.^2;
n = e2 ./ (1 + sqrt(1 - e2)).^2;

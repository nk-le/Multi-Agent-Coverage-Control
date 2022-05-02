function semiminor = minaxis(in1,in2)
%MINAXIS  Semiminor axis of ellipse
%
%  Support for nonscalar input, including the syntax b = MINAXIS(vec), will
%  be removed in a future release.
%
%  b = MINAXIS(semimajor,e) computes the semiminor axis of an ellipse
%  (or ellipsoid of revolution) given the semimajor axis and eccentricity.
%
%  b = MINAXIS(vec) assumes a 2 element vector (vec) is supplied,
%  where vec = [semimajor, e].
%
%  See also AXES2ECC, FLAT2ECC, MAJAXIS, N2ECC, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1,2)
if nargin == 1
    if ~isequal(sort(size(in1)),[1 2])
        error(['map:' mfilename ':mapError'], ...
            'Input must be a 2 element vector')
    else
        in1 = ignoreComplex(in1, mfilename, 'vec');
        semimajor = in1(1);
        eccent    = in1(2);
    end
elseif nargin == 2
    if ~isequal(size(in1),size(in2))
        error(['map:' mfilename ':mapError'], ...
            'Inconsistent input dimensions')
    else
        semimajor = ignoreComplex(in1, mfilename, 'semimajor');
        eccent    = ignoreComplex(in2, mfilename, 'eccentricity');
    end
end

%  Compute the semiminor axis
semiminor = semimajor .* sqrt(1 - eccent.^2);

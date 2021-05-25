function semimajor = majaxis(in1,in2)
%MAJAXIS  Semimajor axis of ellipse
%
%  Support for nonscalar input, including the syntax a = MAJAXIS(vec), will
%  be removed in a future release.
%
%  a = MAJAXIS(semiminor,e) computes the semimajor axis of an ellipse
%  (or ellipsoid of revolution) given the semiminor axis and eccentricity.
%
%  a = MAJAXIS(vec) assumes a 2 element vector (vec) is supplied,
%  where vec = [semiminor, e].
%
%  See also AXES2ECC, FLAT2ECC, MINAXIS, N2ECC, oblateSpheroid

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1,2)
if nargin == 1
    if ~isequal(sort(size(in1)),[1 2])
        error(['map:' mfilename ':mapError'], ...
            'Input must be a 2 element vector')
    else
        in1 = ignoreComplex(in1, mfilename, 'vec');
        semiminor = in1(1);
        eccent    = in1(2);
    end
elseif nargin == 2
    if ~isequal(size(in1),size(in2))
        error(['map:' mfilename ':mapError'], ...
            'Inconsistent input dimensions')
    else
        semiminor = ignoreComplex(in1, mfilename, 'semiminor');
        eccent    = ignoreComplex(in2, mfilename, 'eccentricity');
    end
end

%  Compute the semimajor axis
semimajor = semiminor ./ sqrt(1 - eccent.^2);

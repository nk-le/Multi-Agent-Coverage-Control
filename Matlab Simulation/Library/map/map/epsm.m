function epsilon = epsm(angleUnits)
%EPSM  Accuracy in angle units for certain map computations
%
%   EPSM is not recommended and will be removed in a future release. If
%   necessary, you can replace the expressions below with the constants to
%   the right:
%
%           epsm()             1.0E-6     
%           epsm('deg')        1.0E-6  
%           epsm('rad')        deg2rad(1.0E-6)
%
%   e = EPSM returns the accuracy, in degrees, of certain computations
%   performed in the Mapping Toolbox.
%
%   e = EPSM(angleUnits) returns the accuracy in the specified angle
%   units, which can be 'degrees' or 'radians'.
%

% Copyright 1996-2012 The MathWorks, Inc.

epsilon = 1.0E-6;
if nargin > 0
    epsilon = fromDegrees(angleUnits, epsilon);
end

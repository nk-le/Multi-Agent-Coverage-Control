function M = ecef2lvRotationMatrix(phi0, lambda0)
% Construct the matrix that rotates Cartesian vectors from geocentric to
% local vertical.

% Copyright 2005 The MathWorks, Inc.

sinphi0 = sin(phi0);
cosphi0 = cos(phi0);
sinlambda0 = sin(lambda0);
coslambda0 = cos(lambda0);

M = [    1      0        0   ; ...
         0   sinphi0  cosphi0; ...
         0  -cosphi0  sinphi0] ...
  * [-sinlambda0   coslambda0  0; ...
     -coslambda0  -sinlambda0  0; ...
           0          0        1];

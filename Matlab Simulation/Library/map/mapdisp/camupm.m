function varargout = camupm(lat,long)
%CAMUPM Set camera up vector using geographic coordinates
%
%   CAMUPM(lat,long) sets the axes CameraUpVector property of the
%   current map axes to the position specified in geographic coordinates. 
%   The inputs lat and long are assumed to be in the angle units of the 
%   current map axes. 
%
%   [x,y,z] = CAMUPM(lat,long) returns the camera position in the
%   projected Cartesian coordinate system.
%
%   See also CAMTARGM, CAMPOSM, CAMUP, CAMVA

% Copyright 1996-2020 The MathWorks, Inc.
% Written by: W. Stumpf, A. Kim, T. Debole

narginchk(2,2)

[x,y,z] = map.crs.internal.mfwdtran(lat,long,1);
set(gca,'CameraUpVector',[x,y,z])

if nargout >= 1; varargout{1} = x; end
if nargout >= 2; varargout{2} = y; end
if nargout == 3; varargout{3} = z; end

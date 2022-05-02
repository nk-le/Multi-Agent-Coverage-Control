function varargout = camposm(lat,long,alt)
%CAMPOSM Set camera position using geographic coordinates
%
%   CAMPOSM(lat,long,alt) sets the axes CameraPosition property of the
%   current map axes to the position specified in geographic coordinates. 
%   The inputs lat and long are assumed to be in the angle units of the 
%   current map axes. 
%
%   [x,y,z] = CAMPOSM(lat,long,alt) returns the camera position in the
%   projected Cartesian coordinate system.
%
%   See also CAMTARGM, CAMUPM, CAMPOS, CAMVA

% Copyright 1996-2020 The MathWorks, Inc.
% Written by: W. Stumpf, A. Kim, T. Debole

narginchk(3,3)

[x,y,z] = map.crs.internal.mfwdtran(lat,long,alt);
set(gca,'CameraPosition',[x,y,z])

if nargout >= 1; varargout{1} = x; end
if nargout >= 2; varargout{2} = y; end
if nargout == 3; varargout{3} = z; end

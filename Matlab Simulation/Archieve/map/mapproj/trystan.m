function varargout = trystan(varargin)
%TRYSTAN  Trystan Edwards Cylindrical Projection
%
%  This is an orthographic projection onto a cylinder secant at
%  the 37 deg, 24 min parallels.  It is equal area, but distortion
%  of shape increases with distance from the standard parallels.
%  Scale is true along the standard parallels and constant between
%  two parallels equidistant from the Equator.  This projection is
%  not equidistant.
%
%  This projection is named for Trystan Edwards, who presented it
%  in 1953 and is a special form of the Equal Area Cylindrical
%  projection secant at 37 deg, 24 min N and S.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
        = fromDegrees(mstruct.angleunits,...
        [-90  90], [-180 180], dm2degrees([37 24]));
    mstruct.nparallels = 0;
    mstruct.fixedorient  = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = eqacylin(varargin{:});
end

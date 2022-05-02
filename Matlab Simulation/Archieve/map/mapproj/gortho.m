function varargout = gortho(varargin)
%GORTHO  Gall Orthographic Cylindrical Projection
%
%  This is an orthographic projection onto a cylinder secant at the
%  45 degree parallels.  It is equal area, but distortion of shape
%  increases with distance from the standard parallels.  Scale is true
%  along the standard parallels and constant between two parallels
%  equidistant from the Equator.  This projection is not equidistant.
%
%  This projection was named for James Gall, who originated it in 1855
%  and is a special form of the Equal Area Cylindrical projection
%  secant at 45 deg N and S. It is also known as the Peters projection.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 45);
    mstruct.nparallels   = 0;
    mstruct.fixedorient  = [];
	varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = eqacylin(varargin{:});
end


function varargout = lambcyln(varargin)
%LAMBCYLN  Lambert Equal Area Cylindrical Projection
%
%  This is an orthographic projection onto a cylinder tangent at the
%  Equator.  It is equal area, but distortion of shape increases with
%  distance from the Equator.  Scale is true along the Equator and
%  constant between two parallels equidistant from the Equator.  This
%  projection is not equidistant.
%
%  This projection is named for Johann Heinrich Lambert, and is a
%  special form of the Equal Area Cylindrical projection tangent
%  at the Equator.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
        = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 0);
    mstruct.nparallels = 0;
    mstruct.fixedorient  = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = eqacylin(varargin{:});
end

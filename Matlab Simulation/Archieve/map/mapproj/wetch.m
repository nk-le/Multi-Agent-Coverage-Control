function varargout = wetch(varargin)
%WETCH  Wetch Cylindrical Projection
%
%  This is a perspective projection from the center of the Earth onto
%  a cylinder tangent at the central meridian.  It is not equal area,
%  equidistant, or conformal.  Scale is true along the central meridian
%  and constant between two points equidistant in x and y from the
%  central meridian.  There is no distortion along the central meridian,
%  but it increases rapidly away from it in the y-direction.
%
%  This is the transverse aspect of the Central Cylindrical projection
%  discussed by J. Wetch in the early 19th century.
%
%  This projection is available only on the sphere.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.fixedorient] ...
        = fromDegrees(mstruct.angleunits, [-75 75], [-180 180], -90);
    mstruct.mapparallels = 0;
    mstruct.nparallels   = 0;
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = ccylin(varargin{:});
end

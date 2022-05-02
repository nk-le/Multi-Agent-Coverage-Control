function varargout = bsam(varargin)
%BSAM  Bolshoi Sovietskii Atlas Mira Cylindrical Projection
%
%  This is a perspective projection from a point on the Equator
%  opposite a given meridian onto a cylinder secant at the 30 degree
%  parallels.  It is not equal area, equidistant, or conformal.
%  Scale is true along the standard parallels and constant between
%  two parallels equidistant from the Equator.  There is no distortion
%  along the standard parallels, but it increases moderately away from
%  these parallels, becoming severe at the poles.
%
%  This projection was first described in 1937, when it was used for
%  maps in the Bolshoi Sovietskii Atlas Mira (Great Soviet World Atlas).
%  It is commonly abbreviated as the BSAM projection.  It is a special
%  form of the Braun Perspective Cylindrical projection, secant at
%  30 degrees N and S.
%
%  This projection is available only on the sphere.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
        = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 30);
    mstruct.nparallels   = 0;
    mstruct.fixedorient  = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = braun(varargin{:});
end

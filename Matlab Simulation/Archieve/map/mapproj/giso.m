function varargout = giso(varargin)
%GISO  Gall Isographic Cylindrical Projection
%
%  This is a projection onto a cylinder secant at 45 degree parallels.
%  Distortion of both shape and area increase with distance from the
%  standard parallels.  Scale is true along all meridians (i.e. it is
%  equidistant) and the standard parallels, and is constant along
%  any parallel and along the parallel of opposite sign.
%
%  This projection is a specific case of the Equidistant Cylindrical
%  projection, with standard parallels at 45 deg N and S.
%
%  On the sphere, this projection can have an arbitrary, oblique
%  aspect, as controlled by the Origin property of the map axes. 
%  On the ellipsoid, only the equatorial aspect is supported.
%
%  See also EQDCYLIN

% Copyright 1996-2013 The MathWorks, Inc.

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
    [varargout{:}] = eqdcylin(varargin{:});
end

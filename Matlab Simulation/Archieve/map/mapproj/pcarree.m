function varargout = pcarree(varargin)
%PCARREE  Plate Carree Cylindrical Projection
%
%  This is a projection onto a cylinder tangent at the Equator. Distortion
%  of both shape and area increase with distance from the Equator.  Scale
%  is true along all meridians and along the Equator.
%
%  This projection, like the more general equidistant cylindrical, is
%  credited to Marinus of Tyre, thought to have invented it about
%  A.D. 100.  It may, in fact, have been originated by Eratosthenes,
%  who lived approximately 275-195 B.C.  The Plate Carree has the
%  most simply constructed graticule of any projection.  It was
%  used frequently in the 15th and 16th centuries, and is quite common
%  today in very simple computer mapping programs.  It is the simplest
%  and limiting form of the equidistant cylindrical projection.  Another
%  name for this projection is the Simple Cylindrical.  Its transverse
%  aspect is the Cassini projection.
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
    [mstruct.trimlat, mstruct.trimlon] ...
        = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
    mstruct.mapparallels = 0;
    mstruct.nparallels   = 0;
    mstruct.fixedorient  = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = eqdcylin(varargin{:});
end

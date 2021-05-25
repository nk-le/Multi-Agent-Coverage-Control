function varargout = werner(varargin)
%WERNER  Werner Pseudoconic Projection
%
%  This is an equal area projection.  It is a Bonne projection with
%  of the poles as its standard parallel.  The central meridian
%  is free of distortion.  This projection is not conformal.
%  Its heart shape gives it the additional descriptor "cordiform".
%
%  This projection was developed by Johannes Stabius (Stab) about
%  1500 and was promoted by Johannes Werner in 1514.  It is also
%  called the Stab-Werner projection.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
        = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 90);
    mstruct.nparallels  = 0;
    mstruct.fixedorient = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = bonne(varargin{:});
end

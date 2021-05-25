function varargout = eckert5(varargin)
%ECKERT5  Eckert V Pseudocylindrical Projection
%
%  This projection is an arithmetical average of the x and y coordinates
%  of the Sinusoidal and Plate Carree projections.  Scale is true along
%  latitudes 37 deg, 55 min N and S, and is constant along any parallel
%  and between any pair of parallels equidistant from the Equator.  There
%  is no point free of all distortion, but the Equator is free of
%  angular distortion.  This projection is not equal area, conformal
%  or equidistant.
%
%  This projection was presented by Max Eckert in 1906.
%
%  This projection is available only on the sphere.

% Copyright 1996-2008 The MathWorks, Inc.

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
    [varargout{:}] = winkel(varargin{:});
end

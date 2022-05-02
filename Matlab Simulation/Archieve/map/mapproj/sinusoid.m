function varargout = sinusoid(varargin)
%SINUSOID  Sinusoidal Pseudocylindrical Projection
%
%  This projection is equal area.  Scale is true along every parallel
%  and along the central meridian.  There is no distortion along the
%  Equator or along the central meridian, but it becomes severe near
%  the outer meridians at high latitudes.
%
%  This projection was developed in the 16th century.  It was used
%  by Jean Cossin in 1570 and by Jodocus Hondius in Mercator atlases
%  of the early 17th century.  It is the oldest pseudocylindrical
%  projection currently in use, and is sometimes called the
%  Sanson-Flamsteed or the Mercator Equal Area projections.

% Copyright 1996-2019 The MathWorks, Inc.

if nargin == 1
    % Set defaults.
    mstruct = varargin{1};
    [mstruct.trimlat, mstruct.trimlon] ...
        = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
    mstruct.nparallels   = 0;
    mstruct.fixedorient  = [];
    varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    if nargin > 0
        % The sinusoidal projection can be implemented via the Bonne
        % Pseudoconic projection with a standard parallel at the equator.
        % Add standard parallel to the mstruct before calling bonne.
        mstruct = varargin{1};
        mstruct.mapparallels = 0;
        mstruct.nparallels = 1;
        varargin{1} = mstruct;
    end
    [varargout{:}] = bonne(varargin{:});
end

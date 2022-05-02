function [h,msg] = meshm(varargin)
%MESHM Project regular data grid on map axes
%
%   MESHM(Z, R) will display the regular data grid Z warped to the
%   default projection graticule.  R can be a referencing vector, a
%   referencing matrix, or a geographic raster reference object.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. The current
%   axes must have a valid map projection definition.
%
%   MESHM(Z, R, GRATSIZE) displays a regular data grid warped to a
%   graticule mesh defined by the 1-by-2 vector GRATSIZE. GRATSIZE(1)
%   indicates the number of lines of constant latitude (parallels) in
%   the graticule, and GRATSIZE(2) indicates the number of lines of
%   constant longitude (meridians).
%
%   MESHM(Z, R, GRATSIZE, ALT) displays the regular surface map at
%   the altitude specified by ALT.  If ALT is a scalar, then the grid is
%   drawn in the z = ALT plane.  If ALT is a matrix, then size(ALT) must
%   equal GRATSIZE, and the graticule mesh is drawn at the altitudes specified
%   by ALT.  If the default graticule is desired, set GRATSIZE = [].
%
%   MESHM(..., PARAM1, VAL1, PARAM2, VAL2, ...) uses optional parameter
%   name-value pairs to control the properties of the surface object
%   constructed by MESHM. (If data is placed in the UserData property of
%   the surface, then the projection of this object can not be altered
%   once displayed.)
%
%   H = MESHM(...) returns the handle to the surface drawn.
%
%   Example
%   -------
%   load korea5c
%   worldmap(korea5c,korea5cR)
%   meshm(korea5c,korea5cR)
%   demcmap(korea5c)
%
%   See also PCOLORM, SURFACEM, SURFM

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

% Obsolete syntax
% ---------------
% [h,msg] = MESHM(...) returns a string indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

narginchk(2, inf)

[varargin{:}] = convertStringsToChars(varargin{:});
Z = varargin{1};
R = varargin{2};
varargin(1:2) = [];

R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', mfilename, 'R', 2);

gratsize = [];
if ~isempty(varargin) && ~ischar(varargin{1})
    gratsize = varargin{1};
    varargin(1) = [];
end

alt = [];
if ~isempty(varargin) && ~ischar(varargin{1})
    alt = varargin{1};
    varargin(1) = [];
end

% Note: code below to be added for proper alignment of Z with graticule equal to
% size of Z. If shading interp is the final display mode, may need to shift the
% matrix over by half a cell, i.e. add
%
%    refvec(2) = refvec(2) + (0.5/refvec(1));
%    refvec(3) = refvec(3) + (0.5/refvec(1));
%
% (There is a visual shift because the matlab convention for displaying
%  surfaces - displaying color for corner of cell, and dropping 2 edges -
%  is not followed with shading interp

%  Compute the graticule.

% If size(graticule) = size(Z), pad the map to avoid misalignment
% between texture-mapped and normal surfaces

if isequal(gratsize,size(Z))
    sz = size(Z);
    [lat,lon] = map.internal.graticuleFromRasterReference(R, gratsize + [1 1]);
    Z = [ [Z Z(:,sz(2))] ; [Z(sz(1),:) Z(sz(1),sz(2)) ]];
    if ~isempty(alt)
        alt = [ [alt alt(:,sz(2))] ; [alt(sz(1),:) alt(sz(1),sz(2)) ]];
    end
else
    [lat,lon] = map.internal.graticuleFromRasterReference(R, gratsize);
end

%  Test for empty altitude
if isempty(alt)
    alt = zeros(size(lat));
end

%  Display the map
nextmap(varargin);
if ~isempty(varargin)
    h0 = surfacem(lat,lon,Z,alt,varargin{:});
else
    h0 = surfacem(lat,lon,Z,alt);
end

%  Save the map legend
mapdata = get(h0,'UserData');
mapdata.maplegend = R;
set(h0,'UserData',mapdata);

% Assign output arguments if specified
if nargout > 0
    h = h0;
end

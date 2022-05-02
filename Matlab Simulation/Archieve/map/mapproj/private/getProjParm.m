function [origin, parallels, scalefactor, ...
          easting, northing] = getProjParm( projnum, ...
                                            in_origin, in_parallels, ...
                                            in_scalefactor, ...
                                            in_easting, in_northing)
%GETPROJPARM Get the projection parameters based on proj number
%
%   [ORIGIN, PARALLELS, SCALEFACTOR, ...
%    EASTING, NORTHING] = GETPROJPARM( PROJNUM, ...
%                                     IN_ORIGIN, IN_PARALLELS, ...
%                                     IN_SCALEFACTOR, ...
%                                     IN_EASTING, IN_NORTHING)
%   converts GeoTIFF to MSTRUCT or MSTRUCT to GeoTIFF projection
%   parameters. Returns the projection parameters given an input projection
%   code and the input projection parameters. PROJNUM is the projection
%   code number as defined by the function PROJCODE.
%
%   See also GEOTIFF2MSTRUCT, MSTRUCT2GTIF, PROJCODE

% Copyright 1996-2012 The MathWorks, Inc.

% Set the input origin vector to 2 elements.
if isempty(in_origin)
    in_origin = [0 0];
elseif isscalar(in_origin)
    % Case where defaultm may not have been called after constructing
    % the mstruct.
    in_origin(2) = 0;
else
    in_origin = in_origin(1:2);
end

% Set the input parallels vector to 2 elements.
if isempty(in_parallels)
    in_parallels = [0 0];
elseif isscalar(in_parallels)
    in_parallels(2) = 0;
else
    in_parallels = in_parallels(1:2);
end

% Copy the input to the output.
origin      = in_origin;
parallels   = in_parallels;
scalefactor = in_scalefactor;
easting     = in_easting;
northing    = in_northing;

% Make sure scalefactor is 1 if empty.
if isempty(scalefactor)
  scalefactor = 1;
end

% Make sure the easting and northing are 0 if empty.
if isempty(easting)
  easting = 0;
end
if isempty(northing)
  northing = 0;
end

% Cases that do not fit standard model.
% projnum == 11: Albers
% projnum == 13: Equidistant conic
if projnum == 11 || projnum == 13
    origin = in_parallels;
    parallels = in_origin;
end

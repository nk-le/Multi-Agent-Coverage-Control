function [latlim, lonlim] = bufgeoquad(latlim, lonlim, buflat, buflon)
%BUFGEOQUAD Expand limits of geographic quadrangle
%
%   [LATLIM, LONLIM] = BUFGEOQUAD(LATLIM, LONLIM, BUFLAT, BUFLON) expands
%   the geographic quadrangle defined by the inputs LATLIM and LONLIM.
%   LATLIM is a latitude limit vector of the form [southern_limit
%   northern_limit].  LONLIM is a longitude limit vector of the form
%   [western_limit eastern_limit].  BUFLAT and BUFLON are scalar,
%   nonnegative buffer widths for latitude and longitude, respectively.
%   All angles are in degrees.
%
%   The southern limit of the quadrangle, LATLIM(1), is decreased by the
%   amount BUFLAT (and is constrained to a minimum value of -90).  The
%   northern limit, LATLIM(2), is increased by BUFLAT (and is constrained
%   to a maximum value of 90).  The western and eastern limits, LONLIM(1)
%   and LONLIM(2), respectively, are moved west and east by the amount
%   BUFLON, unless this would cause them to cross over one another.  In the
%   case of a crossover, LONLIM is set to a value that spans 360 degrees,
%   and that preserves the central meridian of the quadrangle.  In any
%   case, the elements of LONLIM are wrapped to the interval [-180 180] and
%   are not necessarily in ascending order.
%
%   See also GEOQUADPT, GEOQUADLINE, OUTLINEGEOQUAD

% Copyright 2012 The MathWorks, Inc.

validateattributes(buflat, {'double'}, ...
    {'scalar','nonnegative','finite','real'}, mfilename, 'BUFLAT', 3)

validateattributes(buflon, {'double'}, ...
    {'scalar','nonnegative','finite','real'}, mfilename, 'BUFLON', 4)

if ~isempty(latlim)
    latlim = latlim(:)' + [-buflat buflat];
    latlim(latlim < -90) = -90;
    latlim(latlim >  90) =  90;
end

if ~isempty(lonlim)
    dlon = diff(lonlim);
    if abs(dlon) ~= 360
        % There's no need to change LONLIM if it already spans 360 degrees
        % exactly.
        halfwidth = mod(dlon, 360)/2;
        center = wrapTo180(lonlim(1) + halfwidth);
        halfwidthnew = halfwidth + buflon;
        if halfwidthnew < 180
            lonlim = wrapTo180(center + [-halfwidthnew halfwidthnew]);
        else
            lonlim = center + [-180 180];
        end
    end
end

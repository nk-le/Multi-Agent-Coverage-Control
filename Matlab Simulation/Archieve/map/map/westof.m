function lon = westof(lon, meridian, units)
%WESTOF Wrap longitudes to values west of specified meridian
% 
%   WESTOF will be removed in a future release.  Replace it with the
%   following calls, which are also more efficient:
%
%      westof(lon, meridian, 'degrees') ==>
%                     meridian - mod(meridian - lon, 360)
% 
%      westof(lon, meridian, 'radians') ==>
%                      meridian - mod(meridian - lon, 2*pi)
%
%   NEWLON = WESTOF(LON, MERIDIAN) wraps angles in LON to values in
%   the interval (MERIDIAN-360 MERIDIAN].  LON is a scalar longitude or
%   vector of longitude values.  All inputs and outputs are in degrees.
%
%   NEWLON = WESTOF(LON, MERIDIAN, ANGLEUNITS) specifies the input and
%   output units with ANGLEUNITS.  ANGLEUNITS can be either 'degrees' or
%   'radians'.  It may be abbreviated and is case-insensitive.  If
%   ANGLEUNITS is 'radians', then the input is wrapped to the interval
%   (MERIDIAN-2*pi MERIDIAN].

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:westof','WESTOF','MOD'))

if nargin < 3
    lon = meridian - mod(meridian - lon, 360);
else
    units = checkangleunits(units);
    if strcmp(units,'radians')
        lon = meridian - mod(meridian - lon, 2*pi);
    else
        lon = meridian - mod(meridian - lon, 360);
    end
end

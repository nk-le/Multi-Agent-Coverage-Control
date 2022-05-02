function lon = eastof(lon,meridian,units)
%EASTOF Wrap longitudes to values east of specified meridian
%
%   EASTOF is will be removed in a future release.  Replace it with the
%   following calls, which are also more efficient:
%
%      eastof(lon, meridian, 'degrees') ==>
%                      meridian + mod(lon - meridian, 360)
% 
%      eastof(lon, meridian, 'radians') ==>
%                      meridian + mod(lon - meridian, 2*pi)
%
%   NEWLON = EASTOF(LON, MERIDIAN) wraps angles in LON to values in
%   the interval [MERIDIAN MERIDIAN+360).  LON is a scalar longitude or
%   vector of longitude values.  All inputs and outputs are in degrees.
%
%   NEWLON = EASTOF(LON, MERIDIAN, ANGLEUNITS) specifies the input and
%   output units with ANGLEUNITS.  ANGLEUNITS can be either 'degrees' or
%   'radians'.  It may be abbreviated and is case-insensitive.  If
%   ANGLEUNITS is 'radians', then the input is wrapped to the interval
%   [MERIDIAN MERIDIAN+2*pi).

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:eastof','EASTOF','MOD'))

if nargin < 3
    lon = meridian + mod(lon - meridian, 360);
else
    units = checkangleunits(units);
    if strcmp(units,'radians')
        lon = meridian + mod(lon - meridian, 2*pi);
    else
        lon = meridian + mod(lon - meridian, 360);
    end
end

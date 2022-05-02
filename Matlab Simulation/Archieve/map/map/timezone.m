function [zd, zoneletter, zone]=timezone(lon,units)
%TIMEZONE  Time zone based on longitude
%
%  [zd, zltr, zone] = TIMEZONE(lon) calculates the navigational
%  time zone (based on longitude, ignoring local statutory deviations).
%  It returns a numerical zone description (add as hours to zone time
%  to get Greenwich Mean Time,(GMT=+0Z), a alphabetical zone indicator,
%  and a zone description plus alphabetical zone indicator.
%  For example, GMT is equivalent to '+0Z'.
%
%  [zd, zltr, zone] = timezone(lon,'units') uses the input 'units' to
%  define the input angle units.  If omitted, 'degrees' are assumed.
%
%  See also NAVFIX, GCWAYPTS, DRECKON.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

narginchk(1,2)
if nargin == 1
   units = 'degrees';
end

%  Ensure that longitude is a column vector, then convert to degrees.

lon = toDegrees(units, lon(:));

% Ensure that longitudes lie between +/-180

lon = wrapTo180(lon);

% Ordered time zone indicators, +180 down to -180 degrees

zones = 'MLKIHGFEDCBAZNOPQRSTUVWXY';
zones = zones';

% Each zone is 15 degrees wide.  "Zero" zone centered
% on 0 degrees longitude

zd = -round(lon/15);

% Make a "sign" string.  ASCII '+' is 43, '-' is 45
% Note that Western (negative) longitudes return
% positive zone descriptions, and vice versa.  This
% flipping of the sign is accomplished above at the round step.

spacechar = char(32);
sgn = spacechar(ones(size(zd)));
sgn(zd < 0) = '-';
sgn(zd > 0) = '+';

% Format actual numerical ZD's as strings

zdstr = num2str(abs(zd),'%2g');

% ZD's can act as indices into the indicator string

zoneletter    = zones(zd+13);
zonesvec(:,2) = zoneletter;
zonesvec(:,1) = '*';        %  Enforce a space

% Pack up the string

zone = [sgn, zdstr, zonesvec];

zone = shiftspc(zone);
zone = leadblnk(zone,' ');

%  Replace the hold characters with a space

zone(zone == '*') = ' ';

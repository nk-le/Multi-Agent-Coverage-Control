function units = checkangleunits(units)
%CHECKANGLEUNITS Check and standardize angle units string
%
%     This function is intentionally undocumented and is intended for
%     use only by other Mapping Toolbox functions.  Its behavior may
%     change, or the function itself may be removed, in a future
%     release.
%
%   UNITS = CHECKANGLEUNITS(UNITS) returns 'degrees' if the
%   case-insensitive UNITS equals 'degrees', or 'radians' if
%   UNITS equals 'radians'.  Given a truncated version of either
%   'degrees' or 'radians', CHECKANGLEUNITS returns the full word.
%   Otherwise, an error is issued. 

% Copyright 2007-2017 The MathWorks, Inc.

units = convertStringsToChars(units);
supportedUnits = {'degrees','radians'};
k = find(strncmpi(units, supportedUnits, numel(units)));
if numel(k) == 1
    units = supportedUnits{k};
else
    badAngleUnits(units)
end

%-------------------------------------------------------------
function badAngleUnits(units)
% Given an input UNITS which is known to be neither 'degrees' nor
% 'radians', and that is not a truncated version of either 'degrees' or
% 'radians', issue an appropriate error.  Note that UNITS might not even
% be a string.

%---------------------------------------
% The following block throws an error if
% 'DM' or 'DMS' encoding is encountered.
% Once 'DM' and 'DMS' are fully obsolete,
% it should be removed.

if strcmpi(units,'dm')
    error('map:badAngleUnits:obsoleteDM',...
      ['''DM'' angle encoding is obsolete.  See degrees2dm and\n',...
       'dm2degrees for alternatives.'])   
elseif strcmpi(units,'dms')
    error('map:badAngleUnits:obsoleteDMS',...
      ['''DMS'' angle encoding is obsolete.  See degrees2dms and\n',...
       'dms2degrees for alternatives.'])
end

%---------------------------------------

if ischar(units)
    error('map:badAngleUnits:invalidAngleUnits',...
        ['Invalid or unknown angle units string: ''%s''.\n', ...
        'Use ''degrees'' or '' radians'' instead.'], ...
        units)
else
    error('map:badAngleUnits:nonCharAngleUnits',...
        ['Angle units must be a string: ''degrees'', ''radians'',\n',...
         'or a truncated version of ''degrees'' or ''radians''.'])
end

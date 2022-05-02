function str = unitstr(~,~) %#ok<STOUT>
%UNITSTR  Check unit strings or abbreviations
%
%   UNITSTR has been removed. Use validateLengthUnit instead.
%
%   UNITSTR, with no arguments, displays a list of strings and
%   abbreviations, recognized by certain Mapping Toolbox functions,
%   for units of angle and length/distance.
%   
%   STR = UNITSTR(STR,'angles') checks for valid angle unit strings or
%   abbreviations.  If a valid string or abbreviation is found, it
%   is converted to a standardized, preset string.
%
%   STR = UNITSTR(STR,'distances') checks for valid length unit strings
%   or abbreviations.  If a valid string or abbreviation is found, it is
%   converted to a standardized, preset string.  Note that 'miles' and
%   'mi' are converted to 'statutemiles';  there is no way to specify
%   international miles in the UNITSTR function.
%
%   See also UNITSRATIO, validateLengthUnit

% Copyright 1996-2013 The MathWorks, Inc.

error(message('map:removed:unitstr','UNITSTR','validateLengthUnit'))

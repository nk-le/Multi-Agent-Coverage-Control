function str = unitstrd(str)
%UNITSTRD  Check distance unit strings or abbreviations
%
%   UNITSTRD, with no arguments, displays a list of recognized strings
%   and abbreviations.
%   
%   STR = UNITSTRD(STR) checks for valid distance unit strings or
%   abbreviations. If a valid string or abbreviation is found, it
%   returns a standardized, preset string.  Note that 'miles' and 'mi'
%   are converted to 'statutemiles';  there is no support for
%   international miles.
%
%   Additional notes:  This function was created to support DIST2STR and
%   the deprecated function DISTDIM.  It is derived from the UNITSTRD
%   subfunction that was part of function UNITSTR, which is now obsolete.
%
%   The use of 'miles' to mean statute miles, not international miles,
%   dates to Version 1.x of Mapping Toolbox, where it was embodied in
%   UNITSTR and DISTDIM.  In contrast, the new UNITSRATIO function makes
%   a clear distinction between international miles and statute miles,
%   and uses interprets 'miles' as international miles.

% Copyright 2007-2016 The MathWorks, Inc.

validunits = {...
    'degrees', ...
    'feet', ...
    'kilometers', ...
    'kilometres', ...
	'meters', ...
    'metres', ...
    'nauticalmiles', ...
	'radians', ...
    'statutemiles'};

if nargin == 0
    displayValidStrings(validunits)
elseif ischar(str)
    str = standardizeString(str, validunits);
else
    error('map:unitstrd:nonCharDistanceUnits', ...
        'Input argument must be a distance units string.')
end

%-----------------------------------------------------------------------

function displayValidStrings(validunits)

abbreviations = {...
    'deg          for degrees       ', ...
    'ft           for feet          ', ...
    'km           for kilometers    ', ...
    'm            for meters        ', ...
    'mi or miles  for statute miles ', ...
    'nm           for nautical miles', ...
    'rad          for radians       ', ...
    'sm           for statute miles '};

disp(' ');    disp('Recognized Distance Unit Strings')
disp(' ');    cellfun(@disp,validunits)
disp(' ');    disp('Recognized Distance Abbreviations')
disp(' ');    cellfun(@disp,abbreviations)

%-----------------------------------------------------------------------

function str = standardizeString(str, validunits)

str = deblank(str);

switch lower(str)
    case 'deg',                str = 'degrees';
    case 'km',                 str = 'kilometers';
    case 'm',                  str = 'meters';
    case 'mi',                 str = 'statutemiles';
    case 'miles',              str = 'statutemiles';
    case 'nm',                 str = 'nauticalmiles';
    case 'sm',                 str = 'statutemiles';
    case 'ft',                 str = 'feet';
    case 'degrees',            str = 'degrees';
    case 'kilometers',         str = 'kilometers';
    case 'kilometres',         str = 'kilometers';
    case 'meters',             str = 'meters';
    case 'metres',             str = 'meters';
    case 'feet',               str = 'feet';
    case 'foot',               str = 'feet';
    case 'nauticalmiles',      str = 'nauticalmiles';
    case 'radians',            str = 'radians';
    case 'statutemiles',       str = 'statutemiles';
    otherwise
        k = find(strncmpi(str,validunits,numel(str)));
        if length(k) == 1
            str = validunits{k};
        else
            error('map:unitstrd:invalidAngleUnits',...
                'Invalid or unknown distance units string: ''%s''.\n', str)
        end
end

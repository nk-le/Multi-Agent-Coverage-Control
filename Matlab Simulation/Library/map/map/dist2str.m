function strout = dist2str(distin,format,units,digits)
%DIST2STR  Format distance strings
%
%  str = DIST2STR(dist) converts a numerical vector of distances in
%  kilometers to a character matrix.  The output character matrix is useful
%  for the display of distances.
%
%  str = DIST2STR(dist,'format') uses the specified format input
%  to construct the character matrix.  Allowable format types are
%  'pm' for plus/minus notation; and 'none' for blank/minus notation.
%  If omitted or blank, 'none' is assumed.
%
%  str = DIST2STR(dist,'format','units') defines the units in which the
%  input distances are supplied, and which are encoded in the character
%  matrix.  Units must be one of the following: 'feet', 'kilometers',
%  'meters', 'nauticalmiles', 'statutemiles', 'degrees', or 'radians'.
%  Note that statute miles are encoded as 'mi' in the character matrix,
%  whereas in most Mapping Toolbox functions, 'mi' indicates international
%  miles. If omitted or blank, 'kilometers' is assumed.
%
%  str = DIST2STR(dist,'format',N) uses the input N to specify the number
%  of decimal digits to be included in the output. With N = -2, the
%  default, digits up to the hundredth place are included. With N = 0, the
%  output is rounded to the nearest whole number.  Note that the sign
%  convention for N is opposite to the one used by the MATLAB ROUND
%  function.
%
%  str = DIST2STR(dist,'format','units',N) uses all the inputs
%  to construct the output character matrix.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1,4)

if nargin > 1
    format = convertStringsToChars(format);
end

if nargin > 2
    units = convertStringsToChars(units);
end

if nargin == 1
    format = 'none';
    units  = 'kilometers';
    digits = -2;
elseif nargin == 2
    units  = 'kilometers';
    digits = -2;
elseif nargin == 3
    % The third argument could be either format or digits.
    if ischar(units)
        units  = unitstrd(units);
        digits = -2;
    else
        digits = units;
        units = 'kilometers';
    end
elseif nargin == 4
    units = unitstrd(units);
end

assert(ischar(format), ...
    ['map:' mfilename ':nonCharFormatString'], ...
    'Input FORMAT must be a string.')

%  Prevent complex distances
distin = ignoreComplex(distin,mfilename,'dist');

%  Ensure that inputs are a column vector

distin = distin(:);

%  Compute the prefix and suffix matrices.
%  Note that the * character forces a space in the output

switch lower(format)
   case 'pm'
      prefix = ' ';     prefix = prefix(ones(size(distin)),:);
      indx = find(distin>0);  if ~isempty(indx);   prefix(indx) = '+';   end
      indx = find(distin<0);  if ~isempty(indx);   prefix(indx) = '-';   end

   case 'none'
      prefix = ' ';     prefix = prefix(ones(size(distin)),:);
      indx = find(distin<0);  if ~isempty(indx);   prefix(indx) = '-';   end

   otherwise
      error(['map:' mfilename ':mapError'], 'Unrecognized format string')

end


%  Compute the units suffix

switch units
	case 'degrees',         suffix = degchar;
    case 'kilometers',      suffix = '*km';
    case 'nauticalmiles',   suffix = '*nm';
	case 'statutemiles',    suffix = '*mi';
	case 'radians',         suffix = '*R';
	case 'meters',          suffix = '*m';
	case 'feet',            suffix = '*ft';
end

%  Expand the suffix matrix to the same length as the input vector

suffix = suffix(ones(size(distin)),:);

%  Convert the distance vector to a string format

formatstr = ['%20.',num2str(abs(min(digits,0)) ),'f'];
str = num2str(abs(distin),formatstr);      %  Convert to a padded string
strout = [prefix str suffix];              %  Construct output string

%  Right justify each row of the output matrix.  This places
%  all extra spaces in the leading position.  Then strip these
%  lead zeros.  Left justifying and then a DEBLANK call will
%  not ensure that all strings line up.  LEADBLNK only strips
%  leading blanks which appear in all rows of a character matrix,
%  thereby not messing up any right justification of the character matrix.

strout = shiftspc(strout);
strout = leadblnk(strout,' ');

%  Replace the hold characters with a space

indx = find(strout == '*');
if ~isempty(indx)
    strout(indx) = ' ';
end

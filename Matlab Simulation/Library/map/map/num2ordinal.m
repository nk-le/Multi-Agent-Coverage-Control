function string = num2ordinal(number)
%NUM2ORDINAL Convert positive integer to ordinal character vector.
%   STRING = NUM2ORDINAL(NUMBER) converts a positive integer to an ordinal
%   character vector.  For example, NUM2ORDINAL(4) returns the character
%   vector 'fourth' and NUM2ORDINAL(23) returns '23rd'.

%   Copyright 1996-2017 The MathWorks, Inc.

%   I/O Spec
%   ========
%   NUMBER     Scalar positive integer
%              Numeric
%
%   NUMBER is not checked for validity.

if number <= 20
  table1 = {'first' 'second' 'third' 'fourth' 'fifth' 'sixth' 'seventh' ...
            'eighth' 'ninth' 'tenth' 'eleventh' 'twelfth' 'thirteenth' ...
            'fourteenth' 'fifteenth' 'sixteenth' 'seventeenth' ...
            'eighteenth' 'nineteenth' 'twentieth'};
  
  string = table1{number};
  
else
  table2 = {'th' 'st' 'nd' 'rd' 'th' 'th' 'th' 'th' 'th' 'th'};
  ones_digit = rem(number, 10);
  string = sprintf('%d%s',number,table2{ones_digit + 1});
end

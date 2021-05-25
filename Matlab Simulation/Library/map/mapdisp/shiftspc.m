function str = shiftspc(str,sidestr,char)
%SHIFTSPC  Left or right justify a string matrix
%
%  SHIFTSPC is intentionally undocumented and will be removed in a future
%  release. Use STRJUST instead.
%
%  See also STRJUST

%  s = SHIFTSPC(s0) will right justify each row in a
%  string matrix.  This is accomplished by relocating
%  all spaces to the beginning of each row.
%
%  s = SHIFTSPC(s0,'side') uses 'side' to specify the
%  type of justification for the string matrix.  If
%  'right' is supplied, the string matrix is right justified.
%  If 'left' is used, then left justification is used.
%
%  s = SHIFTSPC(s0,'side','char') moves all entries matching
%  the scalar 'char' to the start (right justify) or the
%  end (left justify) of each row of the string matrix.
%  Default is char = ' ' (a space).

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1, 3)

if nargin == 1
    sidestr = [];
    char = [];
elseif nargin == 2
    char = [];
end

%  Empty argument tests
if isempty(char)
    char = ' ';
end
if isempty(sidestr)
    sidestr = 'right';
else
    validstr = strvcat('right','left');
    indx = strmatch(sidestr,validstr);
    if length(indx) ~= 1
        error(['map:' mfilename ':mapdispError'], ...
            'Unrecognized shiftspc string')
    end
    sidestr = validstr(indx,:);
end

%  Ensure that char is a scalar
if max(size(char)) ~= 1
    error(['map:' mfilename ':mapdispError'], ...
        'Scalar character required')
end

%  Justify each row of the string matrix.
for i = 1:size(str,1)
    indx = find(str(i,:) == char);       %  Find the characters to move
	if ~isempty(indx)
	      cols = 1:size(str,2);  cols(indx) = [];
 		  switch sidestr
		      case 'right'
                  str(i,:) = [str(i,indx) str(i,cols)] ;   %  Put all char first
              otherwise
                  str(i,:) = [str(i,cols) str(i,indx)] ;   %  Put all char last
		  end
	end
end

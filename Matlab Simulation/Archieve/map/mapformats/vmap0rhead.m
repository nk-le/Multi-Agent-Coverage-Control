function varargout = vmap0rhead(filepath,filename,fid)
%VMAP0RHEAD Read Vector Map Level 0 file headers
%
% VMAP0RHEAD allows the user to select the file interactively.
%
% VMAP0RHEAD(filepath,filename) reads from the specified file.  The
% combination [filepath filename] must form a valid complete filename.
%
% VMAP0RHEAD(filepath,filename,fid) reads from the already open file
% associated with fid.
%
% VMAP0RHEAD(...),  with no output arguments, displays the formatted header
% information on the screen.
%
% str = VMAP0RHEAD...  returns a character vector containing the VMAP0
% header

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  W. Stumpf

if nargin == 0   % allow user to select file interactively

   [filename, filepath] = uigetfile('*', 'select a VMAP0 file');
	if filename == 0 ; return; end
	fid = fopen([filepath,filename],'rb', 'ieee-le');

elseif nargin == 2   % user specified filename, file not open
    
    filepath = convertStringsToChars(filepath);
    filename = convertStringsToChars(filename);
	fid = fopen(fullfile(filepath,filename),'rb', 'ieee-le');

	if fid == -1
		[filename,pathname] = uigetfile(filename,['Where is ',filename,'?']);
		if filename == 0 ; return; end
		fid = fopen([pathname,filename],'rb', 'ieee-le');
	end

elseif nargin==3    % file already open
	if fid == -1; error(['map:' mfilename ':mapformatsError'], 'File not open?');end
else
	error(['map:' mfilename ':mapformatsError'], 'Incorrect number of input arguments');

end

%
% read the header, check for validity in calling function
%

headerlength = fread(fid, 1, 'long');
headerstring = fread(fid, headerlength, 'char');
headerstring = setstr(headerstring');

if nargout == 0
	linebreakchar = sprintf('\n');
	printstring = strrep( strrep(headerstring,'\:','  ') ,':',linebreakchar);
	disp(strrep(printstring,';',linebreakchar))
elseif nargout ==1
	varargout(1) = {headerstring};
end

if nargin ~=3;fclose(fid);end

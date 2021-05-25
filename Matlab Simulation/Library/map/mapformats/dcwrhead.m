function str = dcwrhead(filepath,filename,fid)
%DCWRHEAD Read DCW worldwide basemap file headers
%
%  DCWRHEAD will be removed in a future release. The VMAP0 dataset has
%  replaced DCW, the header data for which can be read using VMAP0RHEAD.
%
%  DCWRHEAD(FILEPATH,FILENAME) reads from the specified file.  The
%  combination [FILEPATH FILENAME] must form a valid complete filename.
%  DCWRHEAD allows the user to select the file interactively.
%
%  DCWRHEAD(FILEPATH,FILENAME,FID) reads from the already open file
%  associated with fid.
%
%  DCWRHEAD(...),  with no output arguments, displays the formatted header
%  information on the screen.
%
%  STR = DCWRHEAD...  returns a string containing the DCW header

% Copyright 1996-2016 The MathWorks, Inc.
% Written by:  W. Stumpf

% Warn that this function is being removed.
warning(message('map:removing:dcwrhead','DCWRHEAD'))

narginchk(0,3)
if nargin == 0   % allow user to select file interactively

   [filename, filepath] = uigetfile('*', 'select a DCW file');
	if filename == 0 ; return; end
	fid = fopen([filepath,filename],'rb', 'ieee-le');

elseif nargin == 2   % user specified filename, file not open

    ind = strfind(filename,'.');
    if isempty(ind) && isunix ; filename = [filename '.']; end


	fid = fopen([filepath,filename],'rb', 'ieee-le');

	if fid == -1
		[filename,pathname] = uigetfile(filename,['Where is ',filename,'?']);
		if filename == 0 ; return; end
		fid = fopen([pathname,filename],'rb', 'ieee-le');
	end

elseif nargin==3    % file already open
    if fid == -1
        error('map:dcwrhead:fileNotOpen','File not open?');
    end

    
end

%
% read the header, check for validity in calling function
%

headerlength = fread(fid, 1, 'long');
headerstring = fread(fid, headerlength, 'char');
headerstring = char(headerstring');

if nargout == 0
	linebreakchar = sprintf('\n');
	printstring = strrep( strrep(headerstring,'\:','  ') ,':',linebreakchar);
	disp(strrep(printstring,';',linebreakchar))
else
	str = headerstring;
end

if nargin ~=3
    fclose(fid);
end

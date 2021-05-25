function S = fipsname(filename)
% FIPSNAME Read FIPS name file used with TIGER thinned boundary files
%
%   FIPSNAME will be removed in a future release. More recent TIGER/Line
%   data sets are available in shapefile format and can be imported using
%   SHAPEREAD.
%
%   S = FIPSNAME opens a file selection window to pick a file, reads the
%   Federal Information Processing Standard codes, and returns them in a
%   structure.
%
%   S = FIPSNAME(FILENAME) reads the specified file.

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  W. Stumpf

warning(message('map:removing:fipsname','FIPSNAME'))

S = [];
if nargin == 0
    [filename, path] = uigetfile('*', 'Please find the FIPS name file');
    if filename == 0
        return
    end
    fid = fopen([path filename],'r');
elseif nargin == 1
    fid = fopen(filename,'r');
    if fid == -1
        [filename, path] = uigetfile('*', 'Please find the FIPS name file');
        if filename == 0
            return
        end
        fid = fopen([path filename],'r');
    end
end

% Read a line at a time, and parse into number and string.
i=0;
S = struct('name', '', 'id', []);
while 1
    line = fgetl(fid);
    if ~ischar(line)
        break
    end
    if length(line) >1
        i = i+1;
        [id,~,~,nextindx] = sscanf(line,'%d',1);
        strname = line(nextindx:length(line));
        strname = leadblnk(deblank(strname));
        S(i).name = strname;
        S(i).id = id;
    end
end

fclose(fid);

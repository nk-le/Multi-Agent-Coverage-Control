function mat = spcread(fname,cols)
%SPCREAD Read columns of data from ASCII text file
%
%  SPCREAD will be removed in a future release.
%
%  MAT = SPCREAD reads two columns of data from an ASCII text file into the
%  workspace.  The file name is supplied by a dialog box.
%
%  MAT = SPCREAD(FILENAME) reads the data from the file name specified.
%
%  MAT = SPCREAD(COLS) and mat = SPCREAD(FILENAME, COLS) assumes that the
%  ASCII text file contains the number of columns specified by cols.
%
%  See also DLMREAD

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Argument checks and default settings.

switch nargin
    case 0
        cols = 2;
        fname = [];
    case  1
        if ischar(fname)
            cols = 2;
            path = [];
        else
            cols = fname;
            fname = [];
        end
    case  2
        path = [];
end

%  Use file dialog box if no fname is supplied

if isempty(fname)
    [fname,path] = uigetfile('','Data File');
    if fname == 0
        mat = [];
        return
    end %  UIGETFILE was canceled
end

%  Open data file for read purposes.

filename = [path, fname];
fid = fopen(filename,'r');
if fid == -1
    error(message('map:fileio:unableToOpenFile', filename))
end

%  Construct the format string so that the number of %g equals
%  the number of columns in the data file.

formatstr = [' '; '%'; 'g'];
formatstr = formatstr(:,ones(1,cols));
formatstr = formatstr(:);
formatstr = formatstr';

%  Read the data file

mat = fscanf(fid, formatstr, [cols inf])';
fclose(fid);

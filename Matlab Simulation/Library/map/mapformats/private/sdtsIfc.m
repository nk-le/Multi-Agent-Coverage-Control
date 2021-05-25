function [info, Z] = sdtsIfc(filename)
% SDTSIfc Interface to the SDTS++ library
%
%   INFO = SDTSIFC(FILENAME) returns a structure whose fields contain
%   information about the contents of an SDTS data set.
%
%   [INFO, Z] = SDTSIFC(FILENAME) returns the INFO structure and reads the
%   Z data from a SDTS raster or DEM data set.  Z is a matrix containing
%   the elevation/data values.
%
%   FILENAME is a string that specifies the name of the SDTS catalog
%   directory file, such as 7783CATD.DDF.  The FILENAME may also include
%   the directory name.  If FILENAME does not include the directory, then
%   it must be in the current directory or in a directory on the MATLAB
%   path.
%
%   SDTSIFC is a wrapper function with no argument checking around the
%   SDTSMEX MEX-function. On Windows, the function must CD to the data
%   directory.
%    
%   Example
%   -------
%   info = sdtsIfc('9129CATD.DDF');
%
%   See also SDTSDEMREAD, SDTSINFO.

% Copyright 2005-2015 The MathWorks, Inc.

% Check for Unicode characters in path. If found, copy files to a temporary
% folder. cleanobj deletes the files at exit.
if any(uint16(fileparts(filename)) > 255)
    [filename, cleanobj] = copyfiles(filename); %#ok<ASGLU>
end

if ispc
    % The SDTS library requires forward slashes.
    filename = strrep(filename,'\','/');
end

% Only read the Z data if requested.
switch nargout
    case {0,1}
        info = sdtsmex(filename);
    case 2
        [info, Z] = sdtsmex(filename);
end

%--------------------------------------------------------------------------

function [tempfilename, cleanobj] = copyfiles(filename)
% Copy SDTS files to a temporary folder. FILENAME is an SDTS filename and
% is expected to exist prior to calling this function. All SDTS files
% associated with FILENAME are copied to the temporary folder. Return the
% temporary file name in TEMPFILENAME and a clean object in CLEANOBJ.
% CLEANOBJ deletes the temporary files and folder.

% Create the temporary folder and clean object.
tmpsdtsdir = tempname;
mkdir(tmpsdtsdir);
cleanobj = onCleanup(@()rmdir(tmpsdtsdir,'s'));

% SDTS filenames consist of a PREFIX followed by four letters known by the
% SDTS format and the extension. Replace the 4 known letters with a '*'.
[path, name, ext] = fileparts(filename);
starname = [name(1:end-4) '*'];
copyname = fullfile(path, [starname ext]);

% Copy the SDTS files to the temporary folder.
copyfile(copyname, tmpsdtsdir)

% Assign the temporary filename.
tempfilename = fullfile(tmpsdtsdir, [name ext]);

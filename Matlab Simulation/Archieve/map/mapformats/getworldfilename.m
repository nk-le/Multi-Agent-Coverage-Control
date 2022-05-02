function worldfilename = getworldfilename(imagefilename)
%GETWORLDFILENAME Derive worldfile name from image file name
%
%   WORLDFILENAME = GETWORLDFILENAME(IMAGEFILENAME) returns the
%   name of the corresponding worldfile derived from the name of an 
%   image file.  
%
%   The worldfile and the image file have the same basename.
%   If IMAGEFILENAME follows the ".3" convention then
%   the worldfile extension is created by removing the middle
%   letter and appending the letter 'w'.  
%
%   If IMAGEFILENAME has an extension that does not follow the ".3"
%   convention, then a 'w' is appended to the full image name to 
%   construct the worldfile name. 
%
%   If IMAGEFILENAME has no extension then '.wld' is appended
%   to construct a worldfile name. 
%
%   Examples:
%   
%      Image File Name          Worldfile Name
%      ---------------          --------------
%      myimage.tif              myimage.tfw
%      myimage.jpeg             myimage.jpegw
%      myimage                  myimage.wld
%
%   See also WORLDFILEREAD, WORLDFILEWRITE.

% Copyright 1996-2017 The MathWorks, Inc.

% Verify 1 input argument
narginchk(1,1);

imagefilename = convertStringsToChars(imagefilename);

% Verify that imagefilename is indeed valid text
validateattributes(imagefilename, {'char','string'}, {'scalartext'}, mfilename, 'IMAGEFILENAME', 1);

% Parse the imagefilename
[pathstr name ext] = fileparts(imagefilename);

% Construct the worldfile extension.
if ~isempty(ext)
   if any(islower(ext))
       W = 'w';
   else
       W = 'W';
   end
   if length(ext) == 4
      % Assume .3 convention
      worldext = [ext([1 2 4]) W];
   else
      worldext = [ext W];
   end
else
    worldext = '.wld';
end

% Construct the worldfilename 
if ~isempty(pathstr)
    worldfilename = fullfile(pathstr, filesep, [name worldext]);
else
    worldfilename = [name worldext];
end

% --------------------------------------------------------------

function answer = islower(s)
% Return TRUE iff lower case character
answer = ('a' <= s) & (s <= 'z');


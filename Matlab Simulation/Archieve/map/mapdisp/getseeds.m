function [row,col,value] = getseeds(map,R,nseeds,seedval)
%GETSEEDS Interactively assign seeds for data grid encoding
%
%  GETSEEDS will be removed in a future release.
%
%  [row,col,val] = GETSEEDS(map,R,nseeds) allows user to identify
%  geographical objects while customizing a raster map. It prompts the
%  user for mouse click positions of objects and assigns them a code
%  value.  The user is prompted for the value to seed at each location.
%  The outputs are the row and column of the seed location and the value
%  assigned at that location. R is either a 1-by-3 vector containing
%  elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%  or a 3-by-2 referencing matrix that transforms raster row and column
%  indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%  If R is a referencing matrix, it must define a (non-rotational,
%  non-skewed) relationship in which each column of the data grid falls
%  along a meridian and each row falls along a parallel.
%
%  [row,col,val] = GETSEEDS(map,R,nseeds,seedval) assigns the value
%  seedval to each location supplied.  If seedval is a scalar then the
%  same value is assigned at each location.  Otherwise, if seedval is a
%  vector it must be length(nseeds) and each entry is assigned to the
%  corresponding location.  GETSEEDS operates on the current axes (gca).
%
%  mat = GETSEEDS(...) returns a single output matrix
%  where mat = [row col val].

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(3, 4)
if nargin == 3
   seedval = [];
end

%  Argument input tests
if length(size(map)) > 2
    error(['map:' mfilename ':mapdispError'], ...
        'Input map cannot have pages.')
elseif max(size(nseeds)) > 1
    error(['map:' mfilename ':mapdispError'], ...
        'NSEEDS input must be empty or scalar.')
end

nseeds = ignoreComplex(nseeds, mfilename, 'nseeds');

%  Ensure integer nseeds
nseeds = round(nseeds);

%  Test the seedval input
if ~isempty(seedval)
    if length(seedval) == 1
	      seedval = seedval(ones([nseeds 1]));
	elseif ~isequal(sort(size(seedval)), [1 nseeds])
	      error(['map:' mfilename ':mapdispError'], ...
              'Seed vector must be scalar or length nseeds.')
	else
	      seedval = seedval(:);   %  Ensure a column vector
    end
end

%  Get seeds from a map.

if ismap
    [lat,long] = inputm(nseeds);
else
    [long,lat] = ginput(nseeds);     %  For displays of images
end

%  Set value for each location
if isempty(seedval)
    needseeds = 1;   answer{1} = '';
    prompt={'Enter the seed values for each location'};
 	title = ['Input for ',num2str(nseeds),' Seed Locations'];

    while needseeds
 	       answer=inputdlg(prompt,title,1,answer(1));
           if isempty(answer)
               row = [];  col = [];   value = [];  return
           end

		   value = str2num(answer{1})'; %#ok<ST2NM>

		   if length(value) == nseeds
		          needseeds = 0;
		   else
		          uiwait(errordlg('Incorrect number of seeds',...
				            'Seed Value Error','modal'));
		   end
    end

else
    value = seedval;
end

%  Convert lat, long degree data to cell positions.
[row,col,badpts] = geographicToDiscreteOmitOutside(R,lat,long);
if ~isempty(badpts);   value(badpts) = [];   end

%  Set the output matrix if necessary
if nargout <= 1
    row = [row col value];
end

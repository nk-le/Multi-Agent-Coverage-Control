function [lat,lon,indx] = extractm(mstruct,objects,method)
%EXTRACTM Coordinate data from line or patch display structure
%
%   EXTRACTM will be removed in a future release. The use of display
%   structures is not recommended. Use geoshape vectors instead.
%
%   [LAT, LON] = EXTRACTM(DISPLAY_STRUCT, OBJECT_STR) extracts latitude
%   and longitude coordinates from those elements of DISPLAY_STRUCT
%   having 'tag' fields that begin with the value specified by
%   OBJECT_STR.  DISPLAY_STRUCT is a Mapping Toolbox display structure
%   in which the 'type' field has a value of either 'line' or 'patch'.
%   The output LAT and LON vectors include NaNs to separate the
%   individual map features.  The comparison of 'tag' values is not
%   case-sensitive.
%
%   [LAT, LON] = EXTRACTM(DISPLAY_STRUCT, OBJECT_STRINGS), where
%   OBJECT_STRINGS is a character vector, string array, or a cell array of
%   character vectors, selects features with 'tag' fields matching any of
%   several different strings.  Character array objects will have trailing
%   spaces stripped before matching.
%
%   [LAT, LON] = EXTRACTM(DISPLAY_STRUCT, OBJECT_STRINGS, SEARCHMETHOD)
%   controls the method used to match the values of the 'tag' field in
%   DISPLAY_STRUCT, as follows:
%
%     'strmatch'   Search for matches at the beginning of the tag
%
%     'findstr'    Search within the tag
%
%     'exact'      Search for exact matches
%
%   Note that when SEARCHMETHOD is specified the search is case-sensitive.
%
%   [LAT,LON] = EXTRACTM(DISPLAY_STRUCT) extracts all vector data from the
%   input map structure.
%
%   [LAT,LON,INDX] = EXTRACTM(...) also returns the vector INDX identifying
%   which elements of DISPLAY_STRUCT met the selection criteria.
%
%   mat = EXTRACTM(...) returns the vector data in a single
%   matrix, where mat = [LAT LON].
%
%   See also GEOSHAPE

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown, W. Stumpf

narginchk(1,3)
if nargin == 1
  objects = [];
else
    objects = convertStringsToChars(objects);
end

%  Determine the objects to extract

if isempty(objects)
  indx = 1:length(mstruct);
else
  indx = [];
  if iscell(objects)
    for i=1:length(objects)
      if nargin ==3
        thisindx = findstrmat(str2mat(mstruct(:).tag),objects{i},method);
      else
        thisindx = strmatch(lower(objects{i}), lower(strvcat(mstruct(:).tag)));
      end
      indx = [indx(:); thisindx(:)]; 
    end % for
  else
    for i=1:size(objects,1)
      if nargin ==3
        thisindx = findstrmat(str2mat(mstruct(:).tag),...
            deblank(objects(i,:)),method);
      else
        thisindx = strmatch( lower(deblank(objects(i,:))),...
            lower(strvcat(mstruct(:).tag)));
      end      
      indx = [indx(:); thisindx(:)]; 
    end % for i
  end % if iscell(objects)
  if isempty(indx)
      error(['map:' mfilename ':mapError'], 'Object string not found')
  end
end

indx = unique(indx);

%  Extract the map vector data

lat0 = [];
lon0 = [];

warned = false;
for i = 1:length(indx)
  switch mstruct(indx(i)).type
    case {'line','patch'}
      lat0 = [lat0; mstruct(indx(i)).lat(:);  NaN];
      lon0 = [lon0; mstruct(indx(i)).long(:); NaN];
    otherwise
      if ~warned
          warning('map:extractm:ignoringNonvectorData',...
                  'Non-vector map data ignored.')
          warned = true;
      end
  end
end

if ~isempty(indx) && ~isempty(lat0)
  lat0(end)=[];
  lon0(end)=[];
end

%  Remove multiple sequential NaNs 

[lat0,lon0] = singleNaN(lat0,lon0);

%  Set output arguments

if nargout < 2   
  lat = [lat0 lon0];
else       
  lat = lat0;   
  lon = lon0;
end

%-----------------------------------------------------------------------

function [lat,lon] = singleNaN(lat,lon)
% SINGLENAN removes duplicate nans in lat-long vectors

if ~isempty(lat)
  nanloc = isnan(lat);
  r = size(nanloc,1);
  nanloc = find(nanloc(1:r-1,:) & nanloc(2:r,:));
  lat(nanloc) = [];  lon(nanloc) = [];
end

%-----------------------------------------------------------------------

function indx = findstrmat(strmat,searchstr,method)

% find matches in vector

switch method
  case 'findstr'
    strmat(:,end+1) = 13; % add a line-ending character to prevent matches across rows
    % make string matrix a vector
    sz = size(strmat);
    strmat = strmat';
    strvec = strmat(:)';
    vecindx = findstr(searchstr,strvec);
    % vector indices to row indices
    indx = unique(ceil(vecindx/sz(2)));
  case 'strmatch'
    indx = strmatch(searchstr,strmat);
  case 'exact'
    indx = strmatch(searchstr,strmat,'exact');
  otherwise
    error(['map:' mfilename ':mapError'], ...
        'Recognized methods are ''exact'', ''strmatch'' and ''findstr''')
end

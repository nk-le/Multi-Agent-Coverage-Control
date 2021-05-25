function varargout = vmap0data(varargin)
%VMAP0DATA Read selected data from Vector Map Level 0
%
% struc = VMAP0DATA(library,latlim,lonlim,theme,topolevel) reads the data
% for the specified theme and topology level directly from the named VMAP0
% CD-ROM. There are four CD's, one each for the library: 'NOAMER' (North
% America), 'SASAUS' (Southern Asia and Australia), 'EURNASIA' (Europe and
% Northern Asia) and 'SOAMAFR' (South America and Africa). The desired
% theme is specified by a two letter code.  A list of valid codes
% will be displayed when an invalid code, such as '?', is entered.  The
% region of interest can be given as a point latitude and longitude or as a
% region with two-element vectors of latitude and longitude limits.  The
% units of latitude and longitude are degrees. The data covering the
% requested region is returned, but will include data extending to the
% edges of the tiles.  The result is returned as a Mapping Toolbox display
% structure.  It can be displayed with function DISPLAYM or converted to a
% geostruct with function UPDATEGEOSTRUCT.
%
% VMAP0DATA(devicename,library,latlim,...) specifies the logical device
% name of the CD-ROM for computers which do not automatically name the
% mounted disk.
%
% [struc1, struc2, ...]  = ...
% VMAP0DATA(library,latlim,lonlim,theme,{topolevel1,topolevel2,...}) reads
% several topology levels.  The levels must be specified as a cell array
% with the entries 'patch', 'line', 'point' or 'text'.  Entering {'all'}
% for the topology level argument is equivalent to {'patch', 'line',
% 'point','text'}. Upon output, the data are returned in the output
% arguments by topology level in the same order as they were requested.
%
% struc = VMAP0DATA(...,layer) returns selected layers within a theme.  A
% list of valid layers will be displayed when an invalid code, such as '?',
% is entered. Layers are specified as strings, character vectors or a cell
% array of character vectors.
%
% struc = VMAP0DATA(...,layer,{'prop1',val1,'prop2',val2,...}) returns only
% those elements that match the specified properties and values within a
% layer. The list of requested properties and values is provided as a cell
% array. A list of valid properties will be displayed when an invalid code,
% such as '?', is entered. Likewise, valid values are displayed when
% invalid properties are entered. All properties are specified as string
% scalars or character vectors. Values may be integers, string scalars, or
% character vectors, or to match multiple values, string vectors or cell
% arrays of integers or character vectors.
%
% See also DCWDATA, UPDATEGEOSTRUCT, VMAP0UI, VMAP0READ, VMAP0RHEAD

% Copyright 1996-2021 The MathWorks, Inc.
% Written by:  W. Stumpf

% warnings with [PPpatch,PPline,PPpoint,PPtext] = vmap0data('SOAMAFR',[0 8],[0 6],'pop','all')


% check for valid inputs
if nargin > 0
    [varargin{:}] = convertContainedStringsToChars(varargin{:});
end
featuretable = [];
property = [];
if nargin == 5
   library = varargin{1};
   latlim = varargin{2};
   lonlim = varargin{3};
   theme = varargin{4};
   topolevel = varargin{5};
   devicename = 'VMAP';
elseif nargin == 6
   devicename = varargin{1};
   library = varargin{2};
   latlim = varargin{3};
   lonlim = varargin{4};
   theme = varargin{5};
   topolevel = varargin{6};
elseif nargin == 7
   devicename = varargin{1};
   library = varargin{2};
   latlim = varargin{3};
   lonlim = varargin{4};
   theme = varargin{5};
   topolevel = varargin{6};
   featuretable = varargin{7};
elseif nargin == 8
   devicename = varargin{1};
   library = varargin{2};
   latlim = varargin{3};
   lonlim = varargin{4};
   theme = varargin{5};
   topolevel = varargin{6};
   featuretable = varargin{7};
   property = varargin{8};
else
   error(message('map:validate:invalidArgCount'))
end

%  Test the inputs

if isscalar(latlim)
   latlim = latlim([1 1]);
end

validateattributes(latlim, {'single','double'}, ...
    {'vector', 'numel', 2, 'real', 'finite'}, 'vmap0data', 'latlim')

if isscalar(lonlim)
   lonlim = lonlim([1 1]);
end

validateattributes(lonlim, {'single','double'}, ...
    {'vector', 'numel', 2, 'real', 'finite'}, 'vmap0data', 'lonlim')

%  Check for valid topology level inputs
validlevels = {'patch','line','point','text'};

% If the user specifies all, replace all with the complete list of levels.
if strcmp(topolevel,'all')
    % True for 'all' and {'all'}.
    topolevel = validlevels;
elseif ischar(topolevel)
     if ~ismember(topolevel, validlevels)
        error(['map:' mfilename ':mapformatsError'], ...
          'Topology level must be one of the following: %s, %s, %s, %s.', ... 
          validlevels{:})
     end
    topolevel = {topolevel};  
else
    % At this point the input is either a cell array or a non-char.  Char
    % is listed as a data type below only so that the error message lists
    % the complete set of valid input types.
    validateattributes(topolevel, {'char', 'string', 'cell'}, {'nonempty'}, ...
        'vmap0data', 'topolevel')
    
    % If we reach this line, we know we have a cell array.  
    % Check for valid strings
    if ~iscellstr(topolevel) || ~all(ismember(topolevel, validlevels))
        error(['map:' mfilename ':mapformatsError'], ...
          'Topology level list may include only the following: %s, %s, %s, %s.', ... 
          validlevels{:})
    end
    
    % Check the array for duplicates.
    if  numel(topolevel) ~= numel(unique(topolevel))
        error(['map:' mfilename ':mapformatsError'], ...
            'Redundant requests in topology levels.')
    end
end
   
if nargout ~= length(topolevel)
  error(['map:' mfilename ':mapformatsError'], ...
      'Number of outputs doesn''t match requested topology levels.')
end
varargout = cell(size(topolevel));

% Check that the top of the database file hierarchy is visible,
% and note the case of the directory and filenames.

filepath = fullfile(devicename,filesep);
dirstruc = dir(filepath);
if ~any(strcmpi('VMAPLV0',{dirstruc.name}))
   error(['map:' mfilename ':mapformatsError'], ...
       'VMAP Level 0 disk not mounted or incorrect devicename '); 
end

% Check feature table inputs - Feature Table corresponds to the layer input
if ~isempty(featuretable) && ~ischar(featuretable) && ~iscellstr(featuretable)
    error(message('map:validate:expectedCellArrayOfStrings', 'layer'))
end

%check property/value inputs
if ~isempty(property)
   if (mod(length(property), 2) ~= 0)
      error(['map:' mfilename ':mapformatsError'], ...
          'Properties must be in pairs: { property1 {value[s]} property2 {value[s]} ... }')
   end
   f = 1:2:length(property);
   if ~iscellstr(property(f))
      error(['map:' mfilename ':mapformatsError'], ...
          'Property Names must be Strings')
   end
   g = 2:2:length(property);
   if ~isa(property(g), 'double') && ~ischar(property(g)) && ~iscellstr(property(g)) && ~iscell(property(g))
      error(['map:' mfilename ':mapformatsError'], ...
          'Property Values must be doubles, strings or cell arrays of double/strings')
   end
end

% build the pathname so that [pathname filename] is the full filename

% Find the right cases by doing a case insensitive search within the
% directory.  
index1 = strcmpi({dirstruc.name}, 'vmaplv0');
filepath = fullfile(devicename, dirstruc(index1).name);
libraryfiles = dir(filepath);
index2 = strcmpi({libraryfiles.name}, library);
librarypath = fullfile(filepath, libraryfiles(index2).name, filesep);
filepath = librarypath;

dirstruc = dir(filepath);
if ~any(index1) || ~any(index2) || isempty(dirstruc)
   error(['map:' mfilename ':mapformatsError'], ...
       ['VMAP Level 0 disk ' upper(library) ' not mounted or incorrect devicename ']); 
end

% check for valid theme request

CAT = vmap0read(filepath,'CAT');

if ~any(strcmpi(theme,{CAT.coverage_name}))
   
   linebreak = double(sprintf('\n'));
   goodthemes = [char(CAT.coverage_name) ...
         char(58*ones(length(CAT),1)) ...
         char(32*ones(length(CAT),1)) ...
         char(CAT.description) ...
         char(linebreak*ones(length(CAT),1)) ];
   goodthemes = goodthemes';
   goodthemes = goodthemes(:);
   goodthemes = goodthemes';
   
   error(['map:' mfilename ':mapformatsError'], ...
       'Theme not present in library %s\n\nValid theme identifiers are:\n%s', ... 
       library, goodthemes);       
end

% BROWSE layer is untiled
  
% Get the essential libref information (tile name/number, bounding boxes)
tilereffiles = dir(librarypath);
index1 = strcmpi({tilereffiles.name}, 'tileref');
tilerefpath = fullfile(librarypath, tilereffiles(index1).name, filesep);
filepath = tilerefpath;

tFT = vmap0read(filepath,'TILEREF.AFT');
FBR = vmap0read(filepath,'FBR');

% find which tiles are fully or partially covered by the desired region   
dotiles = vmap0do(FBR,latlim,lonlim)	;
   

% Here is where the value description and feature tables reside

themefiles = dir(librarypath);
index1 = strcmpi({themefiles.name}, theme);
themepath = fullfile(librarypath, themefiles(index1).name, filesep);

% get a list of files in the requested directory

dirstruc = dir(themepath);
names = {dirstruc.name};

% read the Integer Value Description Table. This contains the integer
% values used to distinguish between types of features using integer keys

VDT = [];
if any(strcmpi(names,'INT.VDT'))==1
   VDT = vmap0read(themepath,'INT.VDT');
end


% read the Character Value Description Table if present.
% This contains the character values used to distinguish
% between types of features using character keys

cVDT = [];
if any(strcmpi(names,'CHAR.VDT'))==1
   cVDT = vmap0read(themepath,'CHAR.VDT');
end


% loop over points, lines, text
% handle faces separately

FACstruct = [];
EDGstruct = [];
TXTstruct = [];

%hwt = waitbar(0,'Working');
%starttime = now;
%hfig = figure;


for i=1:length(dotiles)
   
   %   waitbar(i/length(dotiles),hwt)
   %   starttime(end+1)=now;
   %   timeperstep = diff(starttime);
   %   if i <= 10;
   %      avetimeperstep = mean(timeperstep);
   %   else
   %      avetimeperstep = mean(timeperstep(end-10:end));
   %   end
   %   
   %   endtime = now + avetimeperstep*(length(dotiles)-i);
   %   set(get(get(hwt,'children'),'title'),'string',['Expected completion time: ' datestr(endtime,14)])
   %   
   %   figure(hfig);
   %   plot(starttime(1:end-1),timeperstep)
   %   datetick('x',14)
   %   
   %   
   %   drawnow
   
   EDG = [];
   END = [];
   TXT = [];
   SYM = [];
   
   
   % extract pathname
   % replace directory separator with the one for current platform
   
   tileid = dotiles(i)==[tFT.fac_id];
   
   % The tile path is of the form 'j\G' and might have a '\' at the end
   tilepath = tFT(tileid).tile_name;
   [str1,r] = strtok(tilepath, '\');
   str2 = strtok(r, '\');
   
   tilefiles1 = dir(themepath);
   index1 = strcmpi({tilefiles1.name}, str1);
   filepath = fullfile(themepath, tilefiles1(index1).name);
   tilefiles2 = dir(filepath);
   index2 = strcmpi({tilefiles2.name}, str2);
   tilepath = fullfile(filepath, tilefiles2(index2).name, filesep);
         
   dirstruc = dir(tilepath);
   tilenames = {dirstruc.name};
   
   %
   % loop over feature topology level
   %
   
   %
   % construct the feature table name. We know it will be of form
   % '**'POINT.PFT', etc.
   %
   
   %--- Patch ---%
   patchIndex = strcmp(topolevel, 'patch');
   if any(patchIndex)
       
       EntityName =  'FAC';
       
       wildcard = '*.AFT';
       filenames = dir(themepath);
       index = findSubstring(({filenames.name}), wildcard(2:end));
       FTfilenames = filenames(index);
       if ~isempty(FTfilenames)
           wildcard(2:end) = FTfilenames(1).name(end-3:end);
       end
       
       if (~isempty(featuretable))
           FTfilenames = vmappatchft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme);
       end
       
       if ~isempty(FTfilenames) &&  any(strcmpi(EntityName,tilenames))
           % Get the file extension with the proper case
           
           for k=1:length(FTfilenames)
               
               FTfilename = FTfilenames(k).name;
               
               if isempty(EDG)
                   EDGname =  'EDG';
                   EDG = vmap0read(tilepath,EDGname);
               end
               
               FACstruct = vmap0factl(themepath,tilepath,FTfilename,FACstruct,VDT,cVDT,EDG, property);
               if ~isempty(FACstruct)
                   varargout(patchIndex) = {FACstruct};
               end
               
           end % for k
           
       end % if
   end % if patch
   
   %--- Line ---%
   lineIndex = strcmp(topolevel, 'line');
   if any(lineIndex)
       
       EntityName =  'EDG';
       
       wildcard = '*.LFT';
       filenames = dir(themepath);       
       index = findSubstring(({filenames.name}), wildcard(2:end));
       FTfilenames = filenames(index);
       if ~isempty(FTfilenames)
           wildcard(2:end) = FTfilenames(1).name(end-3:end);
       end
       
       if (~isempty(featuretable))
           FTfilenames = vmaplineft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme);
       end
       
       if ~isempty(FTfilenames) &&  any(strcmpi(EntityName,tilenames))
           for k=1:length(FTfilenames)
               FTfilename = FTfilenames(k).name;
               
               if isempty(EDG)
                   EDG = vmap0read(tilepath,EntityName);
               end
               
               EDGstruct = vmap0edgtl(themepath,tilepath,FTfilename,EDGstruct,VDT,cVDT,EntityName,EDG, property);
               
               if ~isempty(EDGstruct)
                   varargout(lineIndex) = {EDGstruct}; 
               end
               
           end % do k
           
       end % if
       
   end % if line
   
   %--- Point ---% 
   pointIndex = strcmp(topolevel, 'point');
   if any(pointIndex)
       
       EntityName =  'END'; %new CND contains unique information?
       
       wildcard = '*.PFT';
       filenames = dir(themepath);
       index = findSubstring(({filenames.name}), wildcard(2:end));
       FTfilenames = filenames(index);
       if ~isempty(FTfilenames)
           wildcard(2:end) = FTfilenames(1).name(end-3:end);
       end
       
       
       if (~isempty(featuretable))
           FTfilenames = vmappointft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme);
       end
       
       if ~isempty(FTfilenames) &&  any(strcmpi(EntityName,tilenames))
           
           for k=1:length(FTfilenames)
               
               FTfilename = FTfilenames(k).name;
               
               if isempty(END) 
                   END = vmap0read(tilepath,EntityName); 
               end
               
               EDGstruct = vmap0endtl(themepath,tilepath,FTfilename,EDGstruct,VDT,cVDT,EntityName,END,property);
               if ~isempty(EDGstruct)
                   varargout(pointIndex) = {EDGstruct}; 
               end
           end % do k
           
       end % if
       
   end % if point
   
   %--- Text ---%
   
   textIndex = strcmp(topolevel, 'text');
   if any(textIndex)
       EntityName =  'TXT';
       
       % check for and read SYMBOL.RAT file, which contains font sizes and colors
       
       SymbolName =  'SYMBOL.RAT';
       filenames = dir(themepath);
       index = strcmpi({filenames.name}, SymbolName);
       SymbolName = filenames(index).name;
       SymbolDirListing = dir([themepath SymbolName]);
       
       if ~isempty(SymbolDirListing)
           SYM = vmap0read(themepath,SymbolName);
       end
       
       wildcard = '*.TFT';
       filenames = dir(themepath);
       index = findSubstring(({filenames.name}), wildcard(2:end));
       FTfilenames = filenames(index);
       if ~isempty(FTfilenames)
           wildcard(2:end) = FTfilenames(1).name(end-3:end);
       end
       
       if (~isempty(featuretable))
           FTfilenames = vmaptextft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme);
       end
       
       if ~isempty(FTfilenames) &&  any(strcmpi(EntityName,tilenames))
           
           for k=1:length(FTfilenames)
               
               FTfilename = FTfilenames(k).name;
               
               if isempty(TXT) 
                   TXT = vmap0read(tilepath,EntityName); 
               end
               
               TXTstruct = vmap0txttl(themepath,tilepath,TXTstruct,VDT,cVDT,FTfilename,TXT,SYM, property);
               if ~isempty(TXTstruct)
                   varargout(textIndex) = {TXTstruct};
               end
           end % do k
           
       end % if textdata
       
   end % if text
   
end % for i
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [savelat,savelong] = vmap0gbfac(facenum,EDG,~,RNG)
%VMAP0GFAC builds a Digital Chart of the World Browse layer face from its edges

savelat = [];
savelong = [];

if facenum ==1   
   % outer ring of the universe face cannot be displayed
   return
end

ringptrs = find([RNG.face_id]==facenum);

for i=1:length(ringptrs)
   
   checkface = RNG(ringptrs(i)).face_id;
   if checkface ~= facenum
       warning('map:vmap0data:inconsistentFaceAndRing', ...
           'Face and Ring tables inconsistent');
       return
   end
   
   startedge = RNG(ringptrs(i)).start_edge;
   
   [lat,long] = vmap0gbrng(EDG,startedge,facenum);
   
   if isempty(savelat)
      savelat = lat;
      savelong = long;
   else
      savelat = [savelat;NaN;lat];    %#ok<AGROW>
      savelong = [savelong;NaN;long]; %#ok<AGROW>
   end
   
end

% [savelat,savelong] = polycut(savelat,savelong);

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [savelat,savelong] = vmap0gbrng(EDG,startedge,facenum)

if nargin ~= 3
   error(['map:' mfilename ':mapformatsError'], 'Incorrect number of arguments')
end


% Follow face until we end up where we started. If left and right face
% are identical, use left/right edges to break the tie; if that's not
% unambiguous, use start/end nodes

llchunk = EDG(startedge).coordinates;

if  EDG(startedge).right_face(1) == facenum
   nextedge = EDG(startedge).right_edge(1);  % stay on this tile
   savelat = llchunk(:,2);
   savelong = llchunk(:,1);
elseif EDG(startedge).left_face(1) == facenum
   nextedge = EDG(startedge).left_edge(1);
   savelat  = flipud(llchunk(:,2));
   savelong = flipud(llchunk(:,1));
else
   warning('map:vmap0data:cannotFollowFace','Error following face.')
   return
end % if

lastnodes = [EDG(startedge).start_node(1)  ...
      EDG(startedge).end_node(1)  ];

while ~(nextedge == startedge)
   
   curnodes = [EDG(nextedge).start_node EDG(nextedge).end_node];
   
   llchunk = EDG(nextedge).coordinates;
   lat=llchunk(:,2);
   long=llchunk(:,1);
   
   rface = EDG(nextedge).right_face(1);
   lface = EDG(nextedge).left_face(1);
   
   if lface == rface
      
      % Breaking tie with nextedge
      
      if EDG(nextedge).right_edge(1) == nextedge
         
         savelat = [savelat;lat;flipud(lat)]; %#ok<AGROW>
         savelong = [savelong;long;flipud(long)]; %#ok<AGROW>
         nextedge = EDG(nextedge).left_edge(1);
         
      elseif EDG(nextedge).left_edge(1) == nextedge
         
         savelat = [savelat;flipud(lat);lat]; %#ok<AGROW>
         savelong = [savelong;flipud(long);long]; %#ok<AGROW>
         nextedge = EDG(nextedge).right_edge(1);  %stay on this tile
         
      else
         
         % Breaking tie with nodes
         
         starttest = find(curnodes(1) == lastnodes);
         endtest = find(curnodes(2) == lastnodes);
         
         if isempty(starttest) && ~isempty(endtest)
            
            savelat = [savelat;flipud(lat)]; %#ok<AGROW>
            savelong = [savelong;flipud(long)]; %#ok<AGROW>
            nextedge = EDG(nextedge).left_edge(1);
            
         elseif ~isempty(starttest) && isempty(endtest)
            
            savelat = [savelat;lat]; %#ok<AGROW>
            savelong = [savelong;long]; %#ok<AGROW>
            nextedge = EDG(nextedge).right_edge(1);  % stay on this tile
            
         else
            warning('map:vmap0data:cannotFollowFace','Error following face.')
            return
            
         end % if
      end % if
      
   elseif rface == facenum
      savelat = [savelat;lat]; %#ok<AGROW>
      savelong = [savelong;long]; %#ok<AGROW>
      nextedge = EDG(nextedge).right_edge(1);  % stay on this tile
   elseif lface == facenum
      savelat = [savelat;flipud(lat)]; %#ok<AGROW>
      savelong = [savelong;flipud(long)]; %#ok<AGROW>
      nextedge = EDG(nextedge).left_edge(1);
   else
      warning('map:vmap0data:cannotFollowFace','Error following face.')
      return
   end % if
   
   nextedge = nextedge(1);
   lastnodes = curnodes;
   
end % while

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function struc = vmap0edgtl(themepath,~,FTfilename,struc,VDT,cVDT,~,ET, property)

% Read the feature table and the entity table. The feature table contains
% the integer feature type. The entity file contains the coordinates.

if isempty(ET) 
    return; 
end

etfields = fieldnames(ET); % match fieldnames to current entity table

% which lft_id field goes with the current feature table filename
endofword = find(~isletter(FTfilename))-1;
matchthis = lower(FTfilename(1:endofword));
ftfieldindx = findSubstring(etfields, matchthis); 

% verify that there are some references to a feature table ID. Some data (Germany, point trans)
% is missing the pft_id field in the Entity Table.
extension = lower(FTfilename(min(endofword+2,end):end));
ftids = findSubstring(etfields,extension);

if ~any(ftfieldindx) % field name doesn't match what was expected for key
    if ~any(ftids)
        % must be in browse layer, so there are no tiles, and we want all
        % elements
        indx = 1:length(ET);
    else
        % missing feature table id field in entity table when others are
        % present. Interpret this as an error in file format
        return
    end
else
    % These are the keys into the various feature tables. Positive ones go
    % with the current feature table
    indx = [ET.(etfields{ftfieldindx})]; % retrieve only elements in this tile
    ET = ET( indx > 0 );
    indx = indx(indx > 0); 
    if isempty(indx)
        % all of the LFT indices are keys into other LFT tables, so nothing to extract
        return;
    end
end

[FT, FTfield]  = vmap0read(themepath,FTfilename, indx );

if (~isempty(property))
   [FT, ET] = PropertyMatch(property, FT, ET, themepath, FTfilename, VDT, cVDT);
end

%
% find which fields of the feature table contain integer keys, text or values, for
% extraction as a tag. Later try to expand the text fields using the character value 
% description table (char.vdt). 
%

ftfields = fieldnames(FT);

% fields that are indices into the integer value description table
FTindx = find(strcmpi({FTfield.VDTname}, 'int.vdt'));

% Assume that 'crv' field is only occurrence of a value. All other descriptive fields are 
% keys into integer or character description tables.
valfieldIDs = find(strcmpi(ftfields, 'crv'));
textfieldIDs = find(strcmp({FTfield.type}, 'T')); % into fields of FT

%
% Find out how many feature types we have by getting the indices
% into the feature table relating to the current topological entity
% (edge). Look for integer description keys, values, and text
valmat = [];
vdtfieldIDs = [];

% Loop through any integer features and gather a matrix of the value
% combos.  If there are no features, the loop will exit immediately.
for i=1:length(FTindx)    
  valvec = vertcat(FT.(ftfields{FTindx(i)}));  
  valmat(:,end+1) = valvec; %#ok<AGROW>  
end 
   
% don't include VAL fields if they are keys into VDT?

valfieldIDs = valfieldIDs(~ismember( valfieldIDs, vdtfieldIDs));

if  ~isempty(valfieldIDs) % have value fields, so gather them
   
   cells = struct2cell(FT);
   
   featvalvec = [cells{valfieldIDs,:}] ;
   featvalmat = reshape(featvalvec, length(valfieldIDs), length(featvalvec)/length(valfieldIDs));
   VALfeatvalmat = featvalmat';
   
   valmat = [valmat VALfeatvalmat];
end

% no integer feature, so depend on text strings in feature table. Only expect one.
for i=1:length(textfieldIDs)
  strs = char(FT.(ftfields{textfieldIDs(i)}));
  valmat = [valmat double(strs)]; %#ok<AGROW>
end % for   

[~,cindx1,cindx2] = unique(valmat,'rows');
ncombos = size(cindx1,1);

%
% Extract the data
%

i=length(struc);
for j=1:ncombos
   
   indx = find(cindx2==j);
   
   description = descript(valfieldIDs,textfieldIDs,ftfields,indx,FT,FTfield,FTindx,FTfilename,cVDT,VDT);
   
   struc(i+1).type= 'line';
   struc(i+1).otherproperty= {};
   struc(i+1).altitude= [];
   
   ll = [];
   for k=1:length(indx)
      llchunk = ET(indx(k)).coordinates;
      llchunk = llchunk(:,1:2); % for some reason we now have a trailing column of NaNs
      ll = [ll; NaN NaN; llchunk]; %#ok<AGROW>
   end % for k
      
   struc(i+1).lat=ll(:,2);
   struc(i+1).long=ll(:,1);
   struc(i+1).tag=deblank(leadblnk(description));
   
   i=i+1;   
   
end; %for j


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [struc,EDG] = vmap0factl(themepath,tilepath,FTfilename,struc,VDT,cVDT,EDG,property)

% read the feature table and the entity table. The feature table has in
% it the integer feature type and (optionally?) the name of the feature.
% The entity file contains the coordinates.

FAC = vmap0read(tilepath,'FAC');
RNG = vmap0read(tilepath,'RNG');

etfields = fieldnames(FAC); % assume name of key into feature table is second field

% which lft_id field goes with the current feature table filename
endofword = find(~isletter(FTfilename))-1;
matchthis = lower(FTfilename(1:endofword));
ftfieldindx = findSubstring(etfields, matchthis);

% verify that there are some references to a feature table ID. Some data
% (Germany, point trans) is missing the pft_id field in the Entity Table.
extension = lower(FTfilename(min(endofword+2,end):end));
ftids = findSubstring(etfields,extension); 

if isempty(ftfieldindx) % field name doesn't match what was expected for key
   if isempty(ftids)
      indx = 1:length(FAC); % must be in browse layer, so there are no tiles, and we want all elements
   else
      return % missing feature table id field in entity table when others are present. Interpret this as an error in file format
   end
else
   indx = [FAC.(etfields{ftfieldindx})]; % retrieve only elements in this tile
   FAC = FAC( indx > 0 );
   indx = indx(indx > 0); % These are the keys into the various feature tables. Positive ones go with the current feature table
   if isempty(indx)
       % all of the FT indices are keys into other FT tables, so nothing to
       % extract
       return; 
   end 
end

[FT, FTfield]  = vmap0read(themepath,FTfilename,indx );

% check to see if property/value given
if (~isempty(property))
   ET = FAC;
   [FT, ET] = PropertyMatch(property, FT, ET, themepath, FTfilename, VDT, cVDT);
   FAC = ET;
end

%
% find which fields of the feature table contain integer keys, text or
% values, for extraction as a tag. Later try to expand the text fields
% using the character value description table (char.vdt).
%

ftfields = fieldnames(FT);

% fields that are indices into the integer value description table
FTindx = find(strcmpi({FTfield.VDTname}, 'int.vdt'));

% Assume that 'crv' field is only occurrence of a value. All other
% descriptive fields are keys into integer or character description tables.
valfieldIDs = find(strcmpi(ftfields, 'crv'));
textfieldIDs = find(strcmp({FTfield.type}, 'T')); % into fields of FT

%
% Find out how many feature types we have by getting the indices
% into the feature table relating to the current topological entity
% (edge). Look for integer description keys, values, and text

valmat = [];
vdtfieldIDs = [];

% Loop through any integer features and gather a matrix of the value
% combos.  If there are no features, the loop will exit immediately.
for i=1:length(FTindx)    
  valvec = vertcat(FT.(ftfields{FTindx(i)}));  
  valmat(:,end+1) = valvec; %#ok<AGROW>  
end 

% don't include VAL fields if they are keys into VDT

valfieldIDs = valfieldIDs(~ismember( valfieldIDs, vdtfieldIDs));

if  ~isempty(valfieldIDs) % have value fields, so gather them
   
   cells = struct2cell(FT);
   
   featvalvec = [cells{valfieldIDs,:}] ;
   featvalmat = reshape(featvalvec, length(valfieldIDs), length(featvalvec)/length(valfieldIDs));
   VALfeatvalmat = featvalmat';
   
   valmat = [valmat VALfeatvalmat];
end

% no integer feature, so depend on text strings in feature table. Only expect one.
for i=1:length(textfieldIDs)
  strs = char(FT.(ftfields{textfieldIDs(i)}));
  valmat = [valmat double(strs)]; %#ok<AGROW>
end % for   

[~,cindx1,cindx2] = unique(valmat,'rows');
ncombos = size(cindx1,1);

%
% Extract the data
%

i=length(struc);
for j=1:ncombos
   
   indx = find(cindx2==j);
   description = descript(valfieldIDs,textfieldIDs,ftfields,indx,FT,FTfield,FTindx,FTfilename,cVDT,VDT);
   
   for k=1:length(indx)
      
      [lat,long] = vmap0gbfac(FT(indx(k)).fac_id,EDG,FAC,RNG)   ;        % different
      
      if ~isempty(lat)
         
         struc(i+1).type= 'patch';                 % different
         struc(i+1).otherproperty= {};             % different
         
         struc(i+1).altitude= [];
         
         struc(i+1).lat=lat;
         struc(i+1).long=long;
         
         struc(i+1).tag=description;
         
         i=i+1;
         
      end %if
   end % for k
   
end; %for j

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function struc = vmap0endtl(themepath,~,FTfilename,struc,VDT,cVDT,~,ET,property)

% Read the feature table and the entity table. The feature table contains
% the integer feature type. The entity file contains the coordinates.

etfields = fieldnames(ET); % match fieldnames to current entity table

endofword = find(~isletter(FTfilename))-1;
matchthis = lower(FTfilename(1:endofword));
ftfieldindx = findSubstring(etfields, matchthis);

% verify that there are some references to a feature table ID. Some data
% (Germany, point trans) is missing the pft_id field in the Entity Table.
extension = lower(FTfilename(min(endofword+2,end):end));
ftids = findSubstring(etfields,extension); 

if isempty(ftfieldindx) % field name doesn't match what was expected for key
   if isempty(ftids)
      indx = 1:length(ET); % must be in browse layer, so there are no tiles, and we want all elements
   else
      return % missing feature table id field in entity table when others are present. Interpret this as an error in file format
   end
else
   indx = [ET.(etfields{ftfieldindx})]; % retrieve only elements in this tile
   ET = ET( indx > 0 );
   indx = indx(indx > 0); % These are the keys into the various feature tables. Positive ones go with the current feature table
   if isempty(indx)
       % all of the LFT indices are keys into other LFT tables, so nothing to extract
       return; 
   end 
end

[FT, FTfield]  = vmap0read(themepath,FTfilename, indx  );


if (~isempty(property))
   [FT, ET] = PropertyMatch(property, FT, ET, themepath, FTfilename, VDT, cVDT);
end

%
% find which fields of the feature table contain integer keys, text or values, for
% extraction as a tag. Later try to expand the text fields using the character value 
% description table (char.vdt). 
%

ftfields = fieldnames(FT);

% fields that are indices into the integer value description table
FTindx = find(strcmpi({FTfield.VDTname}, 'int.vdt'));

% Assume that 'crv' field is only occurrence of a value. All other
% descriptive fields are keys into integer or character description tables.
valfieldIDs = find(strcmpi(ftfields, 'crv'));
textfieldIDs = find(strcmp({FTfield.type}, 'T')); % into fields of FT

%
% Find out how many feature types we have by getting the indices
% into the feature table relating to the current topological entity
% (edge). Look for integer description keys, values, and text

valmat = [];
vdtfieldIDs = [];

% Loop through any integer features and gather a matrix of the value
% combos.  If there are no features, the loop will exit immediately.
for i=1:length(FTindx)    
  valvec = vertcat(FT.(ftfields{FTindx(i)}));  
  valmat(:,end+1) = valvec; %#ok<AGROW>  
end 

% don't include VAL fields if they are keys into VDT?

valfieldIDs = valfieldIDs(~ismember( valfieldIDs, vdtfieldIDs));

if  ~isempty(valfieldIDs) % have value fields, so gather them
   
   cells = struct2cell(FT);
   
   featvalvec = [cells{valfieldIDs,:}] ;
   featvalmat = reshape(featvalvec, length(valfieldIDs), length(featvalvec)/length(valfieldIDs));
   VALfeatvalmat = featvalmat';
   
   valmat = [valmat VALfeatvalmat];
end

% no integer feature, so depend on text strings in feature table. Only expect one.
   
for i=1:length(textfieldIDs)
    
    % Find any empty strings and replace them
    indx = find(strcmp({FT.(ftfields{textfieldIDs(i)})}, ''''));    
    for j=indx
        FT(j).(ftfields{textfieldIDs(i)}) = 'no string provided';
    end
    
    strs = char(FT.(ftfields{textfieldIDs(i)}));
    valmat = [valmat double(strs)]; %#ok<AGROW>
    
end % for i
   
[~,cindx1,cindx2] = unique(valmat,'rows');
ncombos = size(cindx1,1);

%
% Extract the data
%

i=length(struc);
for j=1:ncombos
   
   indx = find(cindx2==j);
   
   description = descript(valfieldIDs,textfieldIDs,ftfields,indx,FT,FTfield,FTindx,FTfilename,cVDT,VDT);
   
   struc(i+1).type= 'line';
   struc(i+1).otherproperty= {};
   struc(i+1).altitude= [];
   
   ll = [];
   for k=1:length(indx)
      llchunk = ET(indx(k)).coordinate;
      llchunk = llchunk(:,1:2); % for some reason we now have a trailing column of NaNs
      ll = [ll; NaN NaN; llchunk]; %#ok<AGROW>
   end % for k
   
   
   struc(i+1).lat=ll(:,2);
   struc(i+1).long=ll(:,1);
   struc(i+1).tag=deblank(leadblnk(description));
   
   i=i+1;
   
   
end; %for j


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function struc = vmap0txttl(themepath,~,struc,VDT,cVDT,FTfilename,ET,SYM,property)


% read the feature table and the entity table. The feature table has in
% it the integer feature type and (optionally?) the name of the feature.
% The entity file contains the coordinates.

etfields = fieldnames(ET); % assume name of key into feature table is second field

endofword = find(~isletter(FTfilename))-1;
matchthis = lower(FTfilename(1:endofword));
ftfieldindx = findSubstring(etfields, matchthis); % which lft_id field goes with the current feature table filename

if ftfieldindx % field name doesn't match what was expected for key
   indx = 1:length(ET); % must be in browse layer, so there are no tiles, and we want all elements
else
   indx = [ET.(etfields{ftfieldindx})]; % retrieve only elements in this tile
end

FT  = vmap0read(themepath,FTfilename,indx);

if (~isempty(property))
   [FT, ET] = PropertyMatch(property, FT, ET, themepath, FTfilename, VDT, cVDT);
end


%
% find out how many feature types we have by getting the indices
% into the feature table relating to the current topological entity
% (point, edge, face)
%

% Find the indices of the entries in the VDT pertinent to the current
% topology level.
FTindx = find(strcmpi({cVDT.table},FTfilename)); 	

if isempty(FTindx)
   return % No appropriate Feature Table entry in Value Description Table
end

cVDT = cVDT(FTindx);
values = char(cVDT.value);

symcodes = [SYM.symbol_id];


i=length(struc);
for j=1:length(FT)
   
   struc(i+1).type= 'text';
   
   indx = strcmp(cellstr(values), FT(j).f_code);
   
   struc(i+1).tag=deblank(cVDT(indx).description);
   struc(i+1).string=deblank(ET(j).string);
   struc(i+1).altitude= [];
   
   ll = ET(j).shape_line;
    
   struc(i+1).lat=ll(1,2);
   struc(i+1).long=ll(1,1);
   
   symindx = find(symcodes == FT(j).symbol_id);
   properties = {'fontsize',SYM(symindx(1)).size}; % FT(j).symbol_id not unique?
   
   switch SYM(symindx(1)).col % FT(j).symbol_id not unique?
   case 1
      color = 'k';
   case 4
      color = 'b';
   case 9	
      color = 'r';
   case 12
      color = 'm';
   end	
   properties(end+1:end+2) = {'color',color}; 
   
   if length(ll(:,1)) > 1
      
      dx = ll(2,1) - ll(1,1);
      dy = ll(2,2) - ll(1,2);
      ang = 180/pi*(atan2(dy,dx));
      properties(end+1:end+2) = {'rotation',ang};
      
   end %if
   
   struc(i+1).otherproperty= properties;
   
   i=i+1;
   
end; %for j

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function description = descript(valfieldIDs,textfieldIDs,ftfields,indx,FT,FTfield,FTindx,FTfilename,cVDT,VDT)

% build up description codes

description = '';

% extract integer based descriptions	

for k = 1:length(FTindx)
      
   fieldname = ftfields{FTindx(k)};
   val = FT(indx(1)).(fieldname);   
   
   tableindx = find(strcmpi({VDT.table}, FTfilename));
   fieldindx = find(strcmpi({VDT.attribute}, fieldname));
   valueindx = find(val == [VDT.value]);
   VDTindx = intersect(tableindx, intersect(fieldindx,valueindx));
   
   strng = num2str(val);   
   if ~isempty(VDTindx)
      strng = VDT(VDTindx(1)).description;
      if strcmpi(strng,'Unknown')  % expand labels of things with value unknown, 
         strng = [FTfield(FTindx(k)).description, ': ', strng]; %#ok<AGROW>
      end
   end
   
   description = [description, '; ', deblank(strng)]; %#ok<AGROW>
   
end 

%  Extract text-based descriptions. In the VMAP0, it seems that all text is used 
%  as keys into the character description table. Look the text strings up in that
%  table, being careful to extract the correct occurrence of duplicate codes. 

for k = length(textfieldIDs):-1:1
    
    fieldname = ftfields{textfieldIDs(k)};
    strng = FT(indx(1)).(fieldname);
    
    if ~isempty(cVDT)
        tableindx = find(strcmpi({cVDT.table}, FTfilename));
        fieldindx = find(strcmpi({cVDT.attribute}, fieldname));
        valueindx = find(strcmpi({cVDT.value}, strng));
        cVDTindx = intersect(tableindx, intersect(fieldindx,valueindx));
        
        if ~isempty(cVDTindx)
            strng = cVDT(cVDTindx(1)).description;
        end
    end
    
    description = [description, '; ', deblank(strng)]; %#ok<AGROW>
    
end % for k
   

% extract value fields
  
for k = 1:length(valfieldIDs)

  val = FT(indx(1)).(ftfields{valfieldIDs(k)});
  description = [description, '; ', num2str(val)]; %#ok<AGROW>

end 
   
description = description(3:length(description));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function index = findSubstring(strList, searchStr)
% Case insensitive search for a substring inside a cell array of strings.
% The output is a binary vector with value true for each cell that contains
% the given substring.

% Convert strings to lower case.  STRFIND returns a cell array containing
% the first position of each occurrence of the substring for cell in the
% input.  Empty cells indicate that the input string in the corresponding
% cell does not contain the search string.
firstPos = strfind(lower(strList), lower(searchStr));
index = ~cellfun(@isempty, firstPos);

%*********************************************************************
%*********************************************************************
%*********************************************************************

function ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch)

% Check if non-matching values are in Value or Character Description Table
if isempty(cVDTmatch)
   
   % Find values for appropriate feature table
   tabmatch = find(strcmpi({VDT.table}, FTfilename));
   VDTmatch = intersect(VDTmatch, tabmatch);
   val = {VDT(VDTmatch).value};
   val = ([val{:}]);
   
   if (~isa(val, 'double'))
      val = char(val);
   else
      val = num2str(val(:));
   end
   
   if (isempty(VDTmatch))
      error(['map:' mfilename ':mapformatsError'], 'No Valid Values for property');
   end
   
   valdescript = char({VDT(VDTmatch).description});
   valsize = length(val);
else
   if (isempty(cVDTmatch))
      error(['map:' mfilename ':mapformatsError'], 'No Valid Values for property')
   end
   
   % Find values for appropriate feature table
   tabmatch = find(strcmpi({cVDT.table}, FTfilename));
   cVDTmatch = intersect(cVDTmatch, tabmatch);
   
   if iscellstr({cVDT(cVDTmatch).value})
      if (length({cVDT(cVDTmatch).value}) == 1)
         temp = {cVDT(cVDTmatch).value};
         val = char(temp(:));
      else
         val = char({cVDT(cVDTmatch).value});
      end                          
   else
      val = char({cVDT(cVDTmatch).value});
   end
   
   if (length(unique({cVDT(cVDTmatch).value})) == 1)
      valdescript = char(unique({cVDT(cVDTmatch).description}));
   else
      valdescript = char({cVDT(cVDTmatch).description});
   end
     
   valsize = size(valdescript, 1);
end

%Print error msg
linebreak = double(sprintf('\n'));
goodvalues = [val ...
      char(58*ones(valsize,1)) ...
      char(32*ones(valsize,1)) ...
      valdescript ...
   char(linebreak*ones(valsize,1)) ];
goodvalues = goodvalues';
goodvalues = goodvalues(:);
goodvalues = goodvalues';

error(['map:' mfilename ':mapformatsError'], ['Invalid Value for property ' prop.name{s} char(linebreak) char(linebreak) ...
      'Valid values are: ' char(linebreak) ...
      goodvalues ...
]);      

%*********************************************************************
%*********************************************************************
%*********************************************************************

function [FT, ET] = PropertyMatch(property, FT, ET, themepath, FTfilename, VDT, cVDT)

% Extract property names and values from original format and place elements into 
% corresponding struct fields
for t = 1:2:(length(property) - 1)
   prop.name{(t+1)/2} = property{t};
   prop.value{(t+1)/2} = property{t + 1};
end


% Check for valid property names
if ~all(ismember(prop.name, fieldnames(FT)))
   headerstr = vmap0rhead(themepath,FTfilename);
   field =  vmap0phead(headerstr);
   
   linebreak = double(sprintf('\n'));
   goodprop = [char(fieldnames(FT)) ...
         char(58*ones(length({field.description}),1)) ...
         char(32*ones(length({field.description}),1)) ...
         char({field.description}) ...
         char(linebreak*ones(length({field.description}),1)) ];
   goodprop = goodprop';
   goodprop = goodprop(:);
   goodprop = goodprop';
   
   error(['map:' mfilename ':mapformatsError'], ...
       ['Property not present in theme ' FTfilename char(linebreak) char(linebreak) ...
         'Valid property identifiers are: ' char(linebreak) ...
         goodprop ...
   ])
end

F = cell(1,length(prop.name));
match = cell(1,length(prop.name));

% loop over multiple properties
for s = 1:length(prop.name)
   
   % Get matching values from Value and Character Description Tables
   VDTpropmatch = find(strcmpi(prop.name(s), {VDT.attribute}));
   cVDTpropmatch = find(strcmpi(prop.name(s), {cVDT.attribute}));
   
   % Get the indices of entries associated with the current feature table
   VDTftmatch = find(strcmpi(FTfilename, {VDT.table}));
   cVDTftmatch = find(strcmpi(FTfilename, {cVDT.table}));
   
   % Which entries is the value description tables match 
   % both the property name and the feature table name
   VDTmatch = intersect(VDTpropmatch, VDTftmatch);
   cVDTmatch = intersect(cVDTpropmatch , cVDTftmatch);
   
   % Index out match Value and Character Description Table entries
   newVDT = VDT(VDTmatch);
   newcVDT = cVDT(cVDTmatch);
   
   % get values from feature table
   if (~iscellstr(prop.value) && ~ischar(prop.value{s}) && ~iscellstr(prop.value{s}))
      propvalue = [FT.(prop.name{s})];
   else
      propvalue = {FT.(prop.name{s})};
   end
   
   % check value type of cell array double and extract index values for feature table
   if((length(prop.value{s}) > 1 && length(prop.value(s)) > 1) || iscell(prop.value{s})) && (~iscellstr(prop.value) && ~iscellstr(prop.value{s}))      
      for i = 1:length(prop.value{s})
         match{s}{i} = find(prop.value{s}{i} == [newVDT.value]); 
         
         % Check for valid property values
         if isempty(match{s}{i})
            ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch);
         end
         
         %Get matching feature table index values
         F{s}{i} = find(prop.value{s}{i} == propvalue(:)); 
      end
      
      T = [];
      
      % Get union(s) of property values if more than one is entered
      for j = 1:(length(prop.value{s}))
         T = union(F{s}{j}, T);
      end
      
      %Get matching feature table index values
      F{s} = T;
   else
       if(iscellstr(prop.value)) || (iscellstr(prop.value{s}))
         if ~iscellstr(propvalue)
            propvalue = {'****'};
         end
         
         % perform string/cell string operations to retrieve matching feature table index values
         if(iscellstr(prop.value))
            
            % Check for valid property values
            if ~all(ismember(lower(prop.value(s)), lower({newcVDT.value})))
               ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch);
            end
            
            %Get matching feature table index values
            F{s} = find(ismember(lower(propvalue),lower(prop.value)));
         else
            if(iscellstr(prop.value(s)))
               match{s} = find(strcmpi(prop.value(s), {newcVDT.value}));
               
               % Check for valid property values
               if isempty(match{s})
                  ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch);
               end
               
               %Get matching feature table index values
               F{s} = find(strcmpi(prop.value(s), propvalue));
            else
               
               ismem = ismember(lower(prop.value{s}), lower({newcVDT.value}));
               
               % Check for valid property values               
               if ~all(ismem)
                  ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch);
               end
               
               %Get matching feature table index values
               F{s} = find(ismember(lower(propvalue),lower(prop.value{s})));
               
            end
         end
      else
         match{s} = find(prop.value{s} == [newVDT.value]);
         
         % Check for valid property values
         if isempty(match{s})
            ErrorValues(prop, VDT, cVDT, FTfilename,s, VDTmatch, cVDTmatch);
         end
         
         % Get matching feature table index values
         F{s} = find(prop.value{s} == propvalue);
      end
   end
end

if(s > 1)   
   MutualUnion = F{1};
   
   for n = 2:(length(prop.name))
      MutualUnion = union(MutualUnion, F{n});
   end
   
   a = MutualUnion;
else
   a = F{1};
end

% Index out matching values from feature and entity tables
FT = FT(a);
ET = ET(a);

%*********************************************************************
%*********************************************************************
%*********************************************************************

function FTfilenames = vmappatchft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme)

feature = {strcat(featuretable, wildcard(2:length(wildcard)))};
names = strrep({FTfilenames.name}, '.AFT', '');
errorCHK = 0;
descript = cell(1, length(FTfilenames));

% Get file header information for feature table descriptions
for j=1:length(FTfilenames)
   headerstr = vmap0rhead(themepath,FTfilenames(j).name);
   [~,~,description,~] =  vmap0phead(headerstr);
   descript{j} = strrep(description,' Area Feature Table','');
end

% Match input feature table with feature tables from appropriate layer
if (ischar(feature{1}))
   [~,~,match] = intersect(lower(feature), lower({FTfilenames.name}));
   if (isempty(match))
      errorCHK = 1;
   end
else
   [~,~,match] = intersect(lower(feature{1}), lower({FTfilenames.name}));
   if (length(match) ~= length(feature{1}) && ischar(topolevel)) || isempty(match)
      errorCHK = 1;
   end
end

% Printing error
if (errorCHK == 1)
   linebreak = double(sprintf('\n'));
   goodFTs = [char(lower(names)) ...
         char(58*ones(length(names),1)) ...
         char(32*ones(length(names),1)) ...
         char(descript) ...
         char(linebreak*ones(length(names),1)) ];
   goodFTs = goodFTs';
   goodFTs = goodFTs(:);
   goodFTs = goodFTs';
   
   error(['map:' mfilename ':mapformatsError'], ['Patch Feature Table not present in theme ' theme char(linebreak) char(linebreak) ...
         'Valid layer identifiers are: ' char(linebreak) ...
         goodFTs ...
   ])   
else
   tempFTfilenames = FTfilenames(match);
end

% Index out matching feature tables
FTfilenames = tempFTfilenames;

%*********************************************************************
%*********************************************************************
%*********************************************************************

function FTfilenames = vmaplineft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme)

feature = {strcat(featuretable, wildcard(2:length(wildcard)))};
names = strrep({FTfilenames.name}, '.LFT', '');
errorCHK = 0;
descript = cell(1, length(FTfilenames));

% Get file header information for feature table descriptions
for j=1:length(FTfilenames)
   headerstr = vmap0rhead(themepath,FTfilenames(j).name);
   [~,~,description,~] =  vmap0phead(headerstr);
   descript{j} = strrep(description,' Line Feature Table','');
end

% Match input feature table with feature tables from appropriate layer
if (ischar(feature{1}))
   [~,~,match] = intersect(lower(feature), lower({FTfilenames.name}));
   if (isempty(match))
      errorCHK = 1;
   end
else
   [~,~,match] = intersect(lower(feature{1}), lower({FTfilenames.name}));
   if (length(match) ~= length(feature{1}) && ischar(topolevel)) || isempty(match)
      errorCHK = 1;
   end
end

% Printing error
if (errorCHK == 1)
   linebreak = double(sprintf('\n'));
   goodFTs = [char(lower(names)) ...
         char(58*ones(length(names),1)) ...
         char(32*ones(length(names),1)) ...
         char(descript) ...
         char(linebreak*ones(length(names),1)) ];
   goodFTs = goodFTs';
   goodFTs = goodFTs(:);
   goodFTs = goodFTs';
   
   error(['map:' mfilename ':mapformatsError'], ['Line Feature Table not present in theme ' theme char(linebreak) char(linebreak) ...
         'Valid layer identifiers are: ' char(linebreak) ...
         goodFTs ...
   ])
else
   tempFTfilenames = FTfilenames(match);
end

% Index out matching feature tables
FTfilenames = tempFTfilenames;

%*********************************************************************
%*********************************************************************
%*********************************************************************

function FTfilenames = vmappointft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme)

feature = {strcat(featuretable, wildcard(2:length(wildcard)))};
names = strrep({FTfilenames.name}, '.PFT', '');
errorCHK = 0;
descript = cell(1, length(FTfilenames));

% Get file header information for feature table descriptions
for j=1:length(FTfilenames)
   headerstr = vmap0rhead(themepath,FTfilenames(j).name);
   [~,~,description,~] =  vmap0phead(headerstr);
   descript{j} = strrep(description,' Point Feature Table','');
end

% Match input feature table with feature tables from appropriate layer
if (ischar(feature{1}))
   [~,~,match] = intersect(lower(feature), lower({FTfilenames.name}));
   if (isempty(match))
      errorCHK = 1;
   end
else
   [~,~,match] = intersect(lower(feature{1}), lower({FTfilenames.name}));
   if (length(match) ~= length(feature{1}) && ischar(topolevel)) || isempty(match)
      errorCHK = 1;
   end
end

% Printing error
if (errorCHK == 1)
   linebreak = double(sprintf('\n'));
   goodFTs = [char(lower(names)) ...
         char(58*ones(length(names),1)) ...
         char(32*ones(length(names),1)) ...
         char(descript) ...
         char(linebreak*ones(length(names),1)) ];
   goodFTs = goodFTs';
   goodFTs = goodFTs(:);
   goodFTs = goodFTs';
   
   error(['map:' mfilename ':mapformatsError'], ['Point Feature Table not present in theme ' theme char(linebreak) char(linebreak) ...
         'Valid layer identifiers are: ' char(linebreak) ...
         goodFTs ...
   ])
else
   tempFTfilenames = FTfilenames(match);
end

% Index out matching feature tables
FTfilenames = tempFTfilenames;

%*********************************************************************
%*********************************************************************
%*********************************************************************

function FTfilenames = vmaptextft(featuretable, FTfilenames, topolevel, wildcard, themepath, theme)

feature = {strcat(featuretable, wildcard(2:length(wildcard)))};
names = strrep({FTfilenames.name}, '.TFT', '');
errorCHK = 0;
descript = cell(1, length(FTfilenames));

% Get file header information for feature table descriptions
for j=1:length(FTfilenames)
   headerstr = vmap0rhead(themepath,FTfilenames(j).name);
   [~,~,description,~] =  vmap0phead(headerstr);
   descript{j} = strrep(description,' Text Feature Table','');
end

% Match input feature table with feature tables from appropriate layer
if (ischar(feature{1}))
   [~,~,match] = intersect(lower(feature), lower({FTfilenames.name}));
   if (isempty(match))
      errorCHK = 1;
   end
else
   [~,~,match] = intersect(lower(feature{1}), lower({FTfilenames.name}));
   if (length(match) ~= length(feature{1}) && ischar(topolevel)) || isempty(match)
      errorCHK = 1;
   end
end

% Printing error
if (errorCHK == 1)
   linebreak = double(sprintf('\n'));
   goodFTs = [char(lower(names)) ...
         char(58*ones(length(names),1)) ...
         char(32*ones(length(names),1)) ...
         char(descript) ...
         char(linebreak*ones(length(names),1)) ];
   goodFTs = goodFTs';
   goodFTs = goodFTs(:);
   goodFTs = goodFTs';
   
   error(['map:' mfilename ':mapformatsError'], ['Text Feature Table not present in theme ' theme char(linebreak) char(linebreak) ...
         'Valid layer identifiers are: ' char(linebreak) ...
         goodFTs ...
   ])
else
   tempFTfilenames = FTfilenames(match);
end

% Index out matching feature tables
FTfilenames = tempFTfilenames;

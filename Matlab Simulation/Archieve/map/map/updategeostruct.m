function varargout = updategeostruct(varargin)
%UPDATEGEOSTRUCT Convert line or patch display structure to geostruct
%
%   In order to represent sets of geographic line features or area
%   features (polygons or "patches") with vertex coordinates specified
%   in a latitude-longitude system, Mapping Toolbox functions use one of
%   two general types of structure arrays:
%
%   * geostruct arrays -- geographic data structure arrays with
%     latitude and longitude coordinate fields (introduced in Version
%     2.0 of the Mapping Toolbox product)
%
%   * Mapping Toolbox display structure arrays (introduced in Version 1.x
%     and used by a handful of older functions -- they are most likely to
%     be introduced when using the VMAP0DATA file reader)
%
%   In both cases there is one array element per feature.
%
%   GEOSTRUCT = UPDATEGEOSTRUCT(DISPLAY_STRUCT) accepts a display
%   structure array, DISPLAY_STRUCT, which has a 'type' field that
%   either has a value of 'line' for all elements or has a value of
%   'patch' for all elements.  UPDATEGEOSTRUCT converts DISPLAY_STRUCT
%   to a geostruct array of equal size.  Depending on the 'type' field
%   of the input, the value of 'Geometry' field of GEOSTRUCT, for all
%   elements, will be either 'Line' or 'Polygon'.  UPDATEGEOSTRUCT
%   should not be used for display structure arrays of type 'text',
%   'light', 'regular', or 'surface', and the types 'line' and 'patch'
%   cannot be mixed within a single array.
%
%   GEOSTRUCT = UPDATEGEOSTRUCT(DISPLAY_STRUCT, STR) selects only elements
%   whose 'tag' field begins with STR (and whose type field is either
%   'line' or 'patch'). The selection is case-insensitive.
%
%   [GEOSTRUCT, SYMBOLSPEC] = UPDATEGEOSTRUCT(...) constructs a
%   symbolization specification, SYMBOLSPEC, that can be used in
%   combination with GEOSHOW to control the symbolization of the various
%   elements of GEOSTRUCT, based on the graphic properties specified in
%   the 'otherproperty' field for each element of DISPLAY_STRUCT.  If it
%   turns out that SYMBOLSPEC requires use of a colormap, then JET is
%   used.
%
%   [GEOSTRUCT, SYMBOLSPEC] = UPDATEGEOSTRUCT(...,CMAP) uses the
%   specified colormap, CMAP, to define the colors used in SYMBOLSPEC.
%
%   Background
%   ----------
%   line/patch display structures and Line/Polygon geostructs have the
%   following things in common:
%
%   * A field that specifies the type of feature geometry:
%
%       A 'type' field a display structure (value: 'line' or 'patch')
%       A 'Geometry' field for a geostruct (value: 'Line' or 'Polygon')
%
%   * A latitude field:
%       'lat' for a display structure
%       'Lat' for a geostruct
%
%   * A longitude field:
%       'long' for a display structure
%       'Lon' for a geostruct
%
%   In terms of differences:
%
%   * A geostruct has a 'BoundingBox' field; there is no display
%     structure counterpart for this
%
%   * A geostruct typically has one or more "attribute" fields, whose
%     values must be either scalar doubles or strings.  The presence or
%     absence of a given attribute field, and its value, is dependent on
%     the specific data set that the geostruct represents.
%
%   * A (line or patch) display structure has the following fields:
%
%      -- A 'tag' field names an individual feature or object
%      -- An 'altitude' coordinate array extends coordinates to 3-D
%      -- An 'otherproperty' field in which MATLAB graphics can be
%         specified explicitly, on a per-feature basis
%
%   The newer, geostruct, representation has significant advantages:
%   (1) It can represent a much wider range of attributes (display
%   structures essentially can represent only a feature name) and
%   (2) The geostruct representation (in combination with GEOSHOW and
%   MAKESYMBOLSPEC) keeps graphics display properties separate from the
%   intrinsic properties of the geographic features themselves.  For
%   example, a road-class attribute can be used to display major
%   highways with a distinctive color and greater line width than
%   secondary roads.  The same geographic data structure can be
%   displayed in many different ways, without altering any of its
%   contents, and shapefile data imported from external sources need not
%   be altered to control its graphic display.
%
%   For more information on display structures, see the reference page
%   for DISPLAYM.  For more information on geostructs, see the function
%   help for SHAPEREAD and the Mapping Toolbox User's Guide.
%
%   Example
%   --------
%   % Update and display the Great Lakes display structure.
%   load greatlakes
%   cmap = cool(3*numel(greatlakes));
%   [gtlakes, spec] = updategeostruct(greatlakes, cmap);
%   lat = extractfield(gtlakes,'Lat');
%   lon = extractfield(gtlakes,'Lon');
%   lonlim = [min(lon) max(lon)];
%   latlim = [min(lat) max(lat)];
%   figure
%   usamap(latlim, lonlim);
%   geoshow(gtlakes, 'SymbolSpec', spec)
%
%   See also DISPLAYM, GEOSHOW, MAKESYMBOLSPEC, SHAPEREAD

% Copyright 1996-2017 The MathWorks, Inc.

% Note:
%   UPDATEGEOSTRUCT is designed so as not to error given an input
%   structure array that already is a valid geostruct; in such cases it
%   simply copies the input to the output.

% Verify argument count
narginchk(1,3)
nargoutchk(0,2)

% Parse the inputs, check for current version
[varargin{:}] = convertStringsToChars(varargin{:});
[S, v1, cmap] = parseInputs(varargin{:});

% Update the structure
if v1
   [S, symbolSpec] = convertgstruct(S, nargout == 2, cmap);
else
   symbolSpec = getSymbolSpec(nargout ==2, S, cmap);
end

varargout{1} = checkgeostruct(calcBBox(S));
if nargout == 2
   varargout{2} = symbolSpec;
end

%---------------------------------------------------------------------------
function [S, v1, cmap] = parseInputs(varargin)

% Verify geostruct
S = varargin{1};
cmap = [];
checkstruct(S,mfilename,'S',1);

% Temporary for ShapeType 
S = fixShapeStruct(S);

if isfield(S,'Geometry') && ...
      ((isfield(S,'X')  &&  isfield(S,'Y') ) || ...
      ( isfield(S,'Lat') && isfield(S,'Lon') ) )
   v1 = false;
   return;
end
if ~isfield(S,'lat') || ~isfield(S,'long')
   error('map:updategeostruct:invalidGEOSTRUCT', ...
       'Function %s expected a structure with ''Geometry'' and coordinate fieldnames, or a structure with ''lat'' and ''long'' fieldnames.', ...
       upper(mfilename))
end

switch nargin
   case 2
      % S = UPDATEGEOSTRUCT(GEOSTRUCT, FINDSTR)
      % S = UPDATEGEOSTRUCT(GEOSTRUCT, CMAP)
      if ischar(varargin{2})
         [~,~,indx] = extractm(S,varargin{2});
         S = S(indx);
      else
         cmap = varargin{2};
         internal.map.checkcmap(cmap, mfilename, 'CMAP', 2);
      end

   case 3
      if ischar(varargin{2})
         [~,~,indx] = extractm(S,varargin{2});
         S = S(indx);
      else
         error('map:updategeostruct:invalidString', ...
             'Function %s expected its second input argument to be a string.', ....
             upper(mfilename))
      end 
      cmap = varargin{3};
      internal.map.checkcmap(cmap, mfilename, 'CMAP', 3);
end
v1 = true;

%---------------------------------------------------------------------------
function [S, symbolSpec] = convertgstruct(gstruct, reqSymbolSpec, cmap)

%  Update the members
S = updateStruct(gstruct);
symbolSpec = getSymbolSpec(reqSymbolSpec, S, cmap);

%---------------------------------------------------------------------------
function shape = updateStruct(gstruct)

% Default the Geometry to Line type
%  and set the Lat and Lon fields
[shape(1:length(gstruct)).Geometry] = deal('Line');
[shape.Lat] = deal(gstruct.lat);
[shape.Lon] = deal(gstruct.long);

% Set Height if altitude field is present
if isfield(gstruct,'altitude')
   fieldArray = extractfield(gstruct, 'altitude');
   if ~isempty(fieldArray)
      [shape.Height] = deal(gstruct.altitude);
   end
end

% Set the tag field if present
if isfield(gstruct,'tag')
   [shape.tag] = deal(gstruct.tag);
end

% Reset the Geometry based on 'type' field
type = getStructType(gstruct(1));
if strcmp(type,'text')
   [shape.Geometry] = deal('Text');
   if isfield(gstruct,'string')
      [shape.string] = deal(gstruct.string);
   end
   if isfield(gstruct,'text')
      [shape.text] = deal(gstruct.text);
   end
elseif strcmp(type,'patch')
   [shape.Geometry] = deal('Polygon');
elseif strcmp(type,'point')
   [shape.Geometry] = deal('Point');
end

% Add all fields except special field names
fields = fieldnames(gstruct);
for k = 1:length(fields)
   if ~strcmp(fields{k},'tag') && ...
      ~strcmp(fields{k},'text') && ...
      ~strcmp(fields{k},'type') && ...
      ~strcmp(fields{k},'altitude') && ...
      ~strcmp(fields{k},'Geometry')  && ...
      ~strcmp(fields{k},'BoundingBox')  && ...
      ~strcmp(fields{k},'lat')  && ...
      ~strcmp(fields{k},'long')  && ...
      ~strcmp(fields{k},'X')  && ...
      ~strcmp(fields{k},'Y') 
      % remove empty fields
      f=extractfield(gstruct,fields{k});
      if ~isempty(f)
         if ~(numel(f) ==1 && iscell(f) && isempty(f{1}))
           [shape.(fields{k})] = deal(gstruct.(fields{k}));
         end
      end
   end
end

%---------------------------------------------------------------------------
function type = getStructType(gstruct)
type = [];
if isfield(gstruct,'type')
   type = gstruct.type;
end

%---------------------------------------------------------------------------
function symbolSpec = getSymbolSpec(reqSymbolSpec, shape, cmap)

symbolSpec = [];
if reqSymbolSpec
   if isfield(shape,'tag') || isfield(shape,'string')
      if isfield(shape,'string')
         specName = 'string';
      else
         specName = 'tag';
      end
      name = '';
      if isempty(cmap)
        shapeColors = num2cell(jet(numel(shape)),2);
      else
        shapeColors = num2cell(cmap,2);
      end
      %shapeColors = {'green','blue','yellow','magenta','cyan','red'};
      %shapeColors = { [0, 0, 1.0], ...
      %                [0, 0.5, 0], ...
      %                [1.0, 0, 0], ...
      %                [0, 0.75, .75], ...
      %                [0.75,0, 0.75], ...
      %                [0.75, 0.75,0], ...
      %                [0.25, 0.25,0.25]};
      indx = 1;
      k = 1;
      for j = 1:length(shape)
        if ~strcmp(name,shape(j).(specName))
           colors(k,1) = {specName};
           colors(k,2) = {shape(j).(specName)};
           colors(k,3) = shapeColors(indx);
           k = k + 1;
           indx = indx+1;
           if indx > numel(shapeColors) 
              indx = 1;
           end
        end
        name = shape(j).(specName);
      end
   elseif isfield(shape,'otherproperty')
      colors = cell(numel(shape),3);
      for j = 1:length(shape)
        if iscell(shape(j).otherproperty)
           if strcmp(shape(j).otherproperty{1},'color')
              if isfield(shape,'tag')
                 colors(j,1) = {'tag'};
                 colors(j,2) = {shape(j).tag};
                 colors(j,3) = shape(j).otherproperty(2);
              end
           end
        end
      end
   else
      %colors = [];
      symbolSpec = [];
      return;
   end
   symbolSpec.ShapeType = shape(1).Geometry;
   if strcmp(symbolSpec.ShapeType,'Line') ...
     || strcmp(symbolSpec.ShapeType,'Text')
      symbolSpec.ShapeType = 'Line';
      symbolSpec.Color = colors;
   elseif strcmp(symbolSpec.ShapeType,'Polygon')
      symbolSpec.facecolor= colors;
      symbolSpec.EdgeColor={'Default'  ''  [0 0 0]};
   else
      symbolSpec = [];
   end
end

%---------------------------------------------------------------------------
function gstruct = checkgeostruct(S) 
gstruct = S;

if ~all(size(S(1).BoundingBox) == [2 2])
   error('map:updategeostruct:invalidBoundingBox', ...
       'The ''BoundingBox'' field must be a 2x2 matrix with [minX minY;maxX maxY].')
end
if ~any(strcmp(S(1).Geometry,{'Point','MultiPoint','Line','Polygon','Text'}))
   error('map:updategeostruct:invalidGeometry', ...
       'Invalid Geographic Data Structure. Geometry must be one of: ''Point'',''MultiPoint'',''Line'',''Text'', or ''Polygon.')
end
if isfield(S,'X')
   xName = 'X';
   yName = 'Y';
else
   xName = 'Lon';
   yName = 'Lat';
end
if isInvalidCoordinateArray(S(1).(xName)) || ...
   isInvalidCoordinateArray(S(1).(yName))
   error('map:updategeostruct:invalidCoordinates', ...
       'The coordinate fields must be 1xM or Mx1 vectors.')
end
if any(size(S(1).(xName)) ~= size(S(1).(yName)))
   error('map:updategeostruct:invalidCoordinateSize', ...
       'The coordinate fields must be the same size.')
end

%---------------------------------------------------------------------------
function tf = isInvalidCoordinateArray(v)
if ~isvector(v) && ~isempty(v)
  tf = true;
else
  tf = false;
end

%---------------------------------------------------------------------------
function S = fixShapeStruct(shape)
if isfield(shape,'ShapeType')
   [S(1:length(shape)).Geometry] = deal(shape.ShapeType);
   if isequal(shape(1).ShapeType,'PolyLine')
      [S.Geometry] = deal('Line');
   elseif isequal(shape(1).ShapeType,'Multipoint')
      [S.Geometry] = deal('MultiPoint');
   end
   % Add all fields except special field names
   fields = fieldnames(shape);
   for k = 1:length(fields)
      if ~strcmp(fields{k},'ShapeType') 
         [S.(fields{k})] = deal(shape.(fields{k}));
      end
   end
   if ~isfield(shape,'BoundingBox')
      X = extractfield(shape,'X');
      Y = extractfield(shape,'Y');
      BoundingBox = [ min(X), min(Y); max(X), max(Y)];

      % Set all BoundingBox fields to the computed bounding box
      [S.BoundingBox] = deal(BoundingBox);
   end
else
   S = shape;
end

%---------------------------------------------------------------------------
function shape = calcBBox(shape)
if ~isfield(shape,'BoundingBox')

   xName = getCoordName(shape,{'X','Lon'});
   yName = getCoordName(shape,{'Y','Lat'});
   X = extractfield(shape,xName);
   Y = extractfield(shape,yName);
   BoundingBox = [ min(X), min(Y); max(X), max(Y)];

   % Set all BoundingBox fields to the computed bounding box
   [shape.BoundingBox] = deal(BoundingBox);
end

%---------------------------------------------------------------------------
function name = getCoordName(S, names)
name = [];
fields = fieldnames(S);
for i=1:length(names)
   if any(strcmp(names{i},fields))
      name = names{i};
      break
   end
end

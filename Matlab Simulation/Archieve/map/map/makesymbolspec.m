function symbolspec = makesymbolspec(Geometry,varargin)
%MAKESYMBOLSPEC Construct vector symbolization specification 
%
%   SYMBOLSPEC = MAKESYMBOLSPEC(GEOMETRY,RULE1,RULE2,...RULEN) constructs a
%   Symbol Specification structure for symbolizing a shape layer in the Map
%   Viewer or when using MAPSHOW.  GEOMETRY is one of 'Point',
%   'MultiPoint', 'Line', 'Polygon', or 'Patch'.  RULEN, defined in detail
%   below, is the rule to use to determine the graphics properties for each
%   feature of the layer.  RULEN may be a default rule that is applied to
%   all features in the layer or it may limit the symbolization to only
%   features that have a particular value for a specified attribute.
%   Features that don't match any rules will be displayed using the default
%   graphics properties.
%
%   To create a rule that applies to all features, a default rule, use the
%   following syntax for RULEN:
%
%      {'Default',Property1,Value1,Property2,Value2,...,PropertyN,ValueN}
%
%   To create a rule that applies to only features that have a particular
%   value or range of values for a specified attribute, use the following
%   syntax:
%
%      {AttributeName,AttributeValue,Property1,Value1,...
%       Property2,Value2,...,PropertyN,ValueN}
%
%      AttributeValue and ValueN can each be a two element vector, [low
%      high], specifying a range. If AttributeValue is a range, ValueN may
%      or may not be a range. 
%
%   The following is a list of allowable values for PropertyN.  
%
%      Lines: 'Color', 'LineStyle', 'LineWidth', and 'Visible.'
%    
%      Points or Multipoints: 'Marker', 'Color', 'MarkerEdgeColor',
%      'MarkerFaceColor','MarkerSize', and 'Visible.'
%    
%      Polygons: 'FaceColor', 'FaceAlpha', 'LineStyle', 'LineWidth',
%      'EdgeColor', 'EdgeAlpha', and 'Visible.'
%
%   Example 1 
%   ---------
%   % Setting Default Color
%   roads = shaperead('concord_roads.shp');
%   blueRoads = makesymbolspec('Line',{'Default','Color',[0 0 1]});
%   mapshow(roads,'SymbolSpec',blueRoads);
%
%   Example 2 
%   ---------
%   % Setting Discrete Attribute Based
%   roads = shaperead('concord_roads.shp');
%   roadColors = makesymbolspec('Line',{'CLASS',2,'Color','r'},...
%                                      {'CLASS',3,'Color','g'},...
%                                      {'CLASS',6,'Color','b'},...
%                                      {'Default','Color','k'});
%   mapshow(roads,'SymbolSpec',roadColors);
%
%   Example 3 
%   ---------
%   % Using a Range of Attribute Values
%   roads = shaperead('concord_roads.shp');
%   lineStyle = makesymbolspec('Line',{'CLASS',[1 3],'LineStyle','-.'},...
%                                     {'CLASS',[4 6],'LineStyle',':'});
%   mapshow(roads,'SymbolSpec',lineStyle);
%
%   Example 4 
%   ---------
%   % Using a Range of Attribute Values and a Range of Property Values
%   roads = shaperead('concord_roads.shp');
%   colorRange = makesymbolspec('Line',{'CLASS',[1 6],'Color',summer(10)});
%   mapshow(roads,'SymbolSpec',colorRange);
%
%   See also: GEOSHOW, MAPSHOW, MAPVIEW.

% Copyright 1996-2017 The MathWorks, Inc.

%   The output structure (the Symbol Spec) is a "datatype" that will be
%   used as input into other (MathWorks developed) functions or into the
%   Map Viewer.  It is expected that users will always use MAKESYMBOLSPEC
%   to create the Symbol Spec, that they won't rely on it as input into
%   their own functions, and therefore the structure can be changed from
%   release to release without breaking backwards compatibility.  It
%   currently has the following form:
%
%   spec.ShapeType = ShapeType
%   spec.(HGPropertyName) = {AttributeName, AttributeValue, HGPropertyValue}
%   spec.(HGPropertyName) = {'Default','',HGPropertyValue}

if nargin > 0
    Geometry = convertStringsToChars(Geometry);
end
if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end
validateattributes(Geometry,{'char','string'},{'nonempty','scalartext'},mfilename,'GEOMETRY',1);
symbolspec.ShapeType = getGeometry(Geometry);
checkrules(varargin{:});

defaultStrs = {};
for i=1:length(varargin)
  rule = varargin{i};
  [rule{:}] = convertStringsToChars(rule{:});
  if isdefault(rule) 
    for j=2:2:length(rule)
      if isfield(symbolspec,rule{j})
        symbolspec.(rule{j}) = cat(1,symbolspec.(rule{j}),{'Default','',rule{j+1}});
      else
        symbolspec.(rule{j}) = {'Default','',rule{j+1}};
      end
      if any(strcmpi(rule{j},defaultStrs))
          error('map:makesymbolspec:defaultRuleSet', ...
              'The default rule for property ''%s'' has already been set.', ...
              rule{j})
      end
      defaultStrs{end+1} = lower(rule{j}); %#ok<AGROW>
    end
  else
    for j=3:2:length(rule)
      if isfield(symbolspec,rule{j})
        symbolspec.(rule{j}) = cat(1,symbolspec.(rule{j}),rule([1 2 j+1]));
      else
        symbolspec.(rule{j}) = rule([1 2 j+1]);
      end
    end
  end
end
checkSymbolSpec(symbolspec);

%----------------------------------------------------------------------
function checkSymbolSpec(symbolspec)
% Check and verify the symbolspec

fnames = fieldnames(symbolspec);
if length(fnames) <= 1
  error('map:makesymbolspec:noRule', ...
      'The SymbolSpec does not contain any valid rules.')
end

pointProperties   = {'marker','color','markeredgecolor','markerfacecolor', ...
                     'markersize','visible'};
lineProperties    = {'color','linestyle','linewidth','visible'};
polygonProperties = {'facecolor','facealpha','edgealpha','linestyle', ...
                     'linewidth','edgecolor','visible'};

idx = find(strcmpi('shapetype',fnames));
if ~isempty(idx)
  geometry = lower(symbolspec.(fnames{idx}));
  fnames(idx) = [];
else
  error('map:makesymbolspec:internalError', ...
      'The SymbolSpec does not contain fieldname ''ShapeType''.')
end

switch geometry
  case 'point'
    properties = pointProperties;
    geometry = 'point or multipoint';
  case 'line'
    properties = lineProperties;
  case 'polygon'
    properties = polygonProperties;
    geometry = 'polygon or patch';
end

for i=1:length(fnames)
  idx =strcmpi(fnames{i},properties);
  if ~any(idx)
    error('map:makesymbolspec:invalidProperty', ...
        'The property ''%s'' is invalid for %s geometry.', ...
        fnames{i}, geometry)
  end
end

%----------------------------------------------------------------------
function b = isdefault(rule)
% Return true if 'Default' is in the command line inputs.

b = false;
if strcmpi(rule{1},'default')
  b = true;
end
    
%----------------------------------------------------------------------
function geometry = getGeometry(type)
% Verify and obtain the type of Geometry.

switch lower(type)
 case {'line','polyline'}
  geometry = 'Line';
 case {'point','multipoint'}
  geometry = 'Point';
 case {'polygon','patch'}
  geometry = 'Polygon';
 otherwise
  error('map:makesymbolspec:invalidGeometry', ...
     'Geometry must be ''Point'', ''MultiPoint'', ''Line'',  ''Polygon'', or ''Patch''.')
end

%----------------------------------------------------------------------
function checkrules(varargin)
% Verify the symbolspec rule

for i=1:length(varargin)
  rule = varargin{i};
  if ~iscell(rule)
    error('map:makesymbolspec:ruleNotCell', ...
        'RULE number %d is invalid. RULE must be a cell array.', i)
  end
  [rule{:}] = convertStringsToChars(rule{:});
  
  if isempty(rule)
    error('map:makesymbolspec:ruleIsEmpty', ...
        'RULE number %d is invalid. A RULE must be defined.', i)
  end

  if (ischar(rule{1}) || isStringScalar(rule{1})) && strcmpi(rule{1},'default')
    % ('Default', ..., PropertyNameN, PropertyValueN, ...)
    if ~rem(length(rule),2) 
      % Default Rule, requires odd number of inputs
      error('map:makesymbolspec:defaultRuleNotOdd', ...
          'RULE number %d is invalid. The first element is ''Default'', but an even number of PropertyN and ValueN pairs are not present.', ...
          i)
      
    end

    if numel(rule) == 1 
      error('map:makesymbolspec:emptyDefaultRule', ...
          'RULE number %s is invalid. The first element is ''Default'', but PropertyN and ValueN are not present.', ...
          i)
    end
    checkParamValuePairs(rule{2:end});

  else 
    % (AttributeName, AttributeValue, ..., PropertyNameN, PropertyValueN, ...)
    if numel(rule) < 4
      error('map:makesymbolspec:invalidNumel', ...
          'RULE number %d is invalid. An Attribute Name/Value pair must precede a Property Name/Value pair.', ...
          i)
    end

    if ~(ischar(rule{1}) || isStringScalar(rule{1}))
      error('map:makesymbolspec:badAttributeName', ...
          'RULE number %d is invalid. The AttributeName must be a character string.', ...
          i)
    end

    if isstruct(rule{2}) || (numel(rule{2}) > 2) && ~(ischar(rule{2}) || isStringScalar(rule{2}))
      error('map:makesymbolspec:badAttributeValue', ...
          'RULE number %d is invalid. The AttributeValue must be a single number or a character string or a 2 element numeric array.', ...
          i)
    end
    checkParamValuePairs(rule{1:end});
  end

end

%----------------------------------------------------------------------
function checkParamValuePairs(varargin)
% Verify the inputs are in 'Parameter', value pairs syntax form,
%  by checking for pairs (even) and a string or character vector first pair. 

pairs = varargin;
if ~isempty(pairs)
  if rem(length(pairs),2)
    error('map:makesymbolspec:invalidPairs', ...
        'The PropertyN and ValueN inputs must always occur as pairs.')
  end
  params = pairs(1:2:end);
  for i=1:length(params)
    if ~(ischar(params{i}) || isStringScalar(params{i}))
      error('map:makesymbolspec:invalidPropString', ...
          'The PropertyN and ValueN pairs must be a property followed by value.')
    end
  end
end

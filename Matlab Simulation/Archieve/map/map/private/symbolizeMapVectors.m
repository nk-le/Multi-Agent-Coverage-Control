function hg = symbolizeMapVectors(...
                          S, symspec, plotfcn, defaultProps, otherProps)
%symbolizeMapVectors Symbolize map vector features
%
%   hg = symbolizeMapVectors(S, symspec, plotFcn, defaultProps, otherProps)
%   uses the symbol spec in SYMSPEC, if SYMSPEC is non-empty, to map the
%   attributes of the features in the geostruct or dynamic vector S to
%   graphics properties. This step is skipped for empty SYMSPEC. Each
%   feature is displayed using the function handle given in PLOTFCN.  The
%   return value hg is a handle to an hggroup object with one graphics
%   object child for each feature in S.  In the case of polygon
%   features, each child is a modified patch object; otherwise it is a
%   line object.  defaultProps and otherProps are both cell arrays
%   containing name-value pairs for graphic properties,
%
%       {prop1, val1, prop2, val2, ...}
%
%   In the event of conflicts, otherProps overrides the symbolization
%   rules from symbolspec, and both override any property values
%   specified in defaultProps.
%
%   The plotting function, PLOTFCN, must have the following signature:
%
%       h = plotfcn(s, prop1, val1, prop2, val2, ...)
%
%   where s is a geostruct SCALAR and prop1, val1, prop2, val2, ... are
%   optional graphics property name-value pairs.  It may be convenient
%   to define PLOTFCN as an anonymous function with the form
%
%       plotfcn = @(s, varargin) <expression>
%
%   as in the examples below.
%
%   Example 1
%   ---------
%   symspec = makesymbolspec('Line',...
%       {'CLASS',2,'Color','red','LineWidth',3},...
%       {'CLASS',3,'LineWidth',2},...
%       {'CLASS',6,'Color',[0 0 1],'LineStyle','-.'},...
%       {'Default','LineWidth',1},...
%       {'CLASS',5,'Color','green'},...
%       {'STREETNAME','FULKERSON STREET','Color','magenta'});
%   S = shaperead('boston_roads');
%   plotfcn = @(s, varargin) line(s.X, s.Y, varargin{:});
%   hg = symbolizeMapVectors(S, symspec, plotfcn, {}, {});
%   axis equal
%
%   % Now repeat with a color override
%   figure
%   symbolizeMapVectors(S, symspec, plotfcn, {}, {'Color', 'red'});
%   axis equal
%
%   Example 2
%   ---------
%   % Create a map of North America.
%   figure
%   worldmap('na');
%
%   % Read the USA high resolution data.
%   states = shaperead('usastatehi', 'UseGeoCoords', true);
%
%   % Create a SymbolSpec to display Alaska and Hawaii as red polygons
%   % and show the other states in blue.
%   symspec = makesymbolspec('Polygon', ...
%                            {'Name', 'Alaska', 'FaceColor', 'red'}, ...
%                            {'Name', 'Hawaii', 'FaceColor', 'red'}, ...
%                            {'Default', 'FaceColor', 'blue'});
%
%   % Display all the states.
%   fcn = @map.graphics.internal.mappolygon;
%   hg = symbolizeMapVectors(states, symspec, @(s, varargin) geovec( ...
%           gcm, s.Lat, s.Lon, 'geopolygon', fcn, varargin{:}),...
%           {'EdgeColor','green'},{});
%
%   % Exploit the one-to-one correspondence between the children of hg
%   % and the features in states to turn Illinois magenta.
%   ch = get(hg,'Children');
%   set(ch(13),'FaceColor','magenta')

% Copyright 2006-2014 The MathWorks, Inc.

% Initialize output to empty, in case S is empty.
hg = reshape(gobjects(0),[0 1]);

% Create a graphics object for each feature and make the hggroup its
% parent.  Iterate in reverse so that the order of the children of hg
% matches the order of the features in S.  Note that the value of hg is
% empty before we start to loop over the features.  It will remain empty
% until a non-empty object is encountered, then it will switch to its final
% value, which comes from the call to the hggroup function in subfunction
% plotMapFeature.  Note that the line
%
%     hg = hggroup('Parent', get(h,'Parent'));
%
% is executed only once, at most.  In the case of mapshow, this line is
% executed on the first iteration of the loop.  In geoshow, however, it is
% executed on the first iteration only if the first feature is not trimmed;
% otherwise it is not executed until the first non-trimmed feature is
% encountered.  In the edge case where all features are trimmed away,
% hggroup is never called and the value of hg remains empty.
if ~isempty(symspec)
   % Map feature attributes to graphics properties.
   properties = attributes2properties(symspec, S);
   for k = length(S):-1:1
      % Get the graphics properties that are controlled by the symbol spec
      % and combine them with the rest.
      symspecProps = extractprops(properties,k);
      props = [defaultProps symspecProps otherProps];
      
      % Plot the individual feature.
      hg = plotMapFeature(S(k), hg, props, plotfcn);
   end
else
   % Combine the default properties with other properties.
   props = [defaultProps otherProps];  
   
   % Plot the individual feature.
   for k = length(S):-1:1
      hg = plotMapFeature(S(k), hg, props, plotfcn);
   end
end

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(hg)

%--------------------------------------------------------------------------

function hg = plotMapFeature(s, hg, props, plotfcn)
% Plot the map feature in the scalar object, s, with properties, props,
% using plotfcn and add it to the hggroup with handle hg. 

if isempty(hg)
   % We don't have an hggroup yet
   h = plotfcn(s, props{:});
   if ~isempty(h)
      % We've found our first non-empty object. Create an hggroup
      % object with the same parent, then re-parent this object
      % into the group.
      hg = hggroup('Parent', get(h,'Parent'));
      set(h,'Parent',hg)
   end
else
   % We already have an hggroup, so specify it as the parent
   % of this feature.
   plotfcn(s, props{:}, 'Parent', hg);
end

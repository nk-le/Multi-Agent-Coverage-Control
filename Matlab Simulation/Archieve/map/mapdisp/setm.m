function setm(varargin)
%SETM Set properties of map axes and graphics objects
%
%  SETM(H,'MapAxesPropertyName',PropertyValue,...), where H is a valid map
%  axes handle, sets the map properties specified in the input list.  The
%  map properties must be recognized by AXESM.
%
%  SETM(H, 'MapPosition', POSITION), where H is a valid projected map text
%  object, uses a two or three element position vector specifying
%  [latitude, longitude, altitude].  For two element vectors, altitude = 0
%  is assumed.
%
%  SETM(H, 'Graticule', LAT, LON, ALT), where H is a valid projected
%  surface object, uses LAT and LON matrices of same size to specify the
%  graticule vertices.  The input ALT can be either a scalar to specify the
%  altitude plane, a matrix of the same size as LAT and LON, or an empty
%  matrix.  If omitted, ALT = 0 is assumed.
%
%  For projected surface objects displayed using MESHM: 
%  SETM(H,'MeshGrat', GSIZE, ALT), where H is a valid surface object
%  displayed using MESHM, uses the two element vector gsize to specify the
%  graticule size (see MESHM).  The last input ALT can be either a scalar
%  to specify the altitude plane, a matrix of the size(GSIZE), or an empty
%  matrix.  If omitted, ALT = 0 is assumed.
%
%  See also GETM, AXESM, SET

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1, inf)

[varargin{:}] = convertStringsToChars(varargin{:});

%  Determine the object type
if ischar(varargin{1})
   varargin{1} = handlem(varargin{1});
end

if ~isscalar(varargin{1}) || ~ishghandle(varargin{1})
   error(message('map:validate:expectedHGHandle','H'))
end

switch get(varargin{1},'Type')
    case 'axes'
        if numel(varargin) == 1
            displayAxesProperties
        elseif numel(varargin) == 2 && ischar(varargin{2})
            displayAxesProperties(varargin{2});
        else
            setmaxes(varargin{:});
        end

    case 'surface'
        if numel(varargin) == 1
            displaySurfProperties
        elseif numel(varargin) == 2 && ischar(varargin{2})
            displaySurfProperties(varargin{2})
        else
            setmsurf(varargin{:});
        end

    case 'text'
        if numel(varargin) == 1
            displayTextProperties
        elseif numel(varargin) == 2 && ischar(varargin{2})
            displayTextProperties(varargin{2})
        else
            setmtext(varargin{:});
        end
    otherwise
        tagstr = get(varargin{1},'Tag');
        if strncmp('scaleruler',tagstr,numel('scaleruler'))
            % strip trailing numbers
            tagstr = 'scaleruler';
        end
        switch tagstr
            case 'scaleruler'
                if numel(varargin) == 1
                    displayScaleProperties
                elseif numel(varargin) == 2 && ischar(varargin{2})
                    displayScaleProperties(varargin{2})
                else
                    scaleruler('setm',varargin{:})
                end
            otherwise
                error(message('map:setm:unsupportedType'))
        end
end

%--------------------------------------------------------------------------
function setmaxes(varargin)
%SETMAXES  Processes the SETM operations for an axes object
%
%  Processing of the property list for errors is accomplished by
%  the call to AXESM.

if nargin < 2 || (nargin == 2 && ~isstruct(varargin{2}))
    error(message('map:validate:invalidArgCount'))
end

% Ensure that the input object is a map axes
ax = varargin{1};
if ~ismap(ax)
    error(message('map:validate:expectedMapAxes'))
end

% Get the current projection data
oldstruct = gcm(ax);

% Verify that the axes children can be reprojected.
% If not, issue an error message.
verifyAxesChildren(ax, oldstruct, varargin{:});

% Delete the mdistort lines and text. If they were present, recompute after
% reprojecting
mdistortparam = mdistort('off');

% Delete the parallelui lines. If they were present, restore after
% reprojecting
hpar = findobj(gca,'Tag','paralleluiline');
onparui = 0;
if ~isempty(hpar)
   onparui = 1;
   hpar = findobj(gca,'Tag','paralleluiline');
   delete(hpar)
end

%  Eliminate the frame, grid, meridian and parallel labels from the map.
%  AXESM will redisplay them if their status is currently on.
delete(handlem('frame',ax));
delete(handlem('grid',ax));
delete(handlem('plabel',ax));
delete(handlem('mlabel',ax));

%  Get the children of the current map axes.  Must be done
%  after the deletions above but before those objects
%  are restored in the axesm call.
children = get(ax,'Children');

%  Make the map axes current.  This control of the current figure
%  and current axes properties avoids activating the figure window
%  during the reprojection of the map.  This behavior mirrors SET.
oldfigure = get(0,'CurrentFigure');
oldaxes = get(oldfigure,'CurrentAxes');

figureWithMap = ancestor(ax,'figure');
set(0,'CurrentFigure',figureWithMap)
set(figureWithMap,'CurrentAxes',ax)

%  Get the axes properties which axesm changes to defaults
properties.nextplot   = get(ax,'NextPlot');
properties.dataaspect = get(ax,'DataAspectRatio');
properties.dataaspmode= get(ax,'DataAspectRatioMode');
properties.boxvar     = get(ax,'Box');
properties.buttondwn  = get(ax,'ButtonDownFcn');
properties.visible    = get(ax,'Visible');

%  Process the map properties.  Reset the axes after this process
try 
    if isstruct(varargin{2})      %  Special operation from axesmui
        h = axesm(varargin{2});
    else
        varargin{1} = oldstruct;
        h = axesm(varargin{:});
        ax = h;
    end
catch e
    %  Restore deleted objects if necessary (oldstruct still in axes)
    gridm(oldstruct.grid);
    framem(oldstruct.frame);
    plabel(oldstruct.parallellabel);
    mlabel(oldstruct.meridianlabel);
    %  Reset the current figure and axes
    set(0,'CurrentFigure',oldfigure)
    set(oldfigure,'CurrentAxes',oldaxes)
    rethrow(e)
end

%  Reset the current figure and axes
set(0,'CurrentFigure',oldfigure)
set(oldfigure,'CurrentAxes',oldaxes)

%  Restore the axes properties which a successful call to
%  axesm will have changed to the default map settings.
%  The user may have changed these properties, especially the
%  DataAspectRatio for 3D plots.
set(h,'NextPlot',            properties.nextplot);
set(h,'DataAspectRatio',     properties.dataaspect);
set(h,'DataAspectRatioMode', properties.dataaspmode);
set(h,'Box',                 properties.boxvar);
set(h,'ButtonDownFcn',       properties.buttondwn);
set(h,'Visible',             properties.visible);

%  Get the new map structure
newstruct = gcm(h);

% Determine if objects need to be reprojected
reproQ = determineIfReprojecting(oldstruct, newstruct);

%  Reproject each child of the map axes
if reproQ

   % The axes limits will have to change under reprojection.  Make sure
   % that this can happen by setting the limit modes to 'auto.'
   % (If the axes was created with worldmap or usamap, or if the user
   % has called tightmap, these modes will be 'manual.')
   set(ax,'XLimMode','auto')
   set(ax,'YLimMode','auto')

   for i = 1:numel(children)
      hChild = children(i);
      mapgraph = getappdata(hChild,'mapgraph');

      %  Make sure each object is projected
      if ~isempty(mapgraph)
          if mapgraph.ObjectIsLoaded  
              hHandle = getMapGraphHandle(hChild);
              mapgraph.updateMapGraphHandle(hHandle)              
          else
              mapgraph.reproject()
          end
      elseif ismapped(hChild)

         % get the geographic coordinates, and reproject
         object = get(hChild,'Type');
         switch object
            case 'hggroup'
                error(message('map:setm:hggroupHandleNotReprojectable'))

            case 'patch'

               FVCD = get(hChild,'FaceVertexCData');

               if length(FVCD) > 1 
                  % completely general patch made mapped by PROJECT. 
                  % CLIPDATA and SETFACES aren't set up to handle this
                  %  Note: CART2GRN returns a scalar ALT variable if the object is a patch
                  vertices = get(hChild,'Vertices');
                  x = vertices(:,1);
                  y = vertices(:,2);
                  alt = vertices(:,3);
                  oldz = alt;
                  savepts = getm(hChild);
                  [lat,lon,alt] = map.crs.internal.minvtran(oldstruct,x,y,alt,'surface',savepts);                  
                  r = unitsratio(newstruct.angleunits, oldstruct.angleunits);
                  lat = r * lat;
                  lon = r * lon;
                  
                  %  New projection
                  [x,y,z,savepts] = map.crs.internal.mfwdtran(newstruct,lat,lon,alt,'surface');  
                  
               else
                  % patch created using a mapping toolbox command
                  userdata = get(hChild,'UserData');
                  
                  %  New projection
                  lat = userdata.lat;
                  lon = userdata.lon;
                  oldz = userdata.z;
                  [x,y,z] = projectpatch(newstruct,lat,lon,oldz);

               end
            otherwise
               [lat,lon,alt] = cart2grn(hChild,oldstruct);  %  Greenwich data
               
               r = unitsratio(newstruct.angleunits, oldstruct.angleunits);
               lat = r * lat;
               lon = r * lon;
                  
               %  New projection
               [x,y,z,savepts] = map.crs.internal.mfwdtran(newstruct,lat,lon,alt,object);  
         end

         switch object
            case 'hggroup'
            case 'text'
               set(hChild,'Position', [x y z],'UserData',savepts);

            case 'light'
               if isempty(x) || isempty(y) || isempty(z)
                  delete(hChild)      %  Remove trimmed lights
               else
                  set(hChild,'Position',[x y z])
               end

            case 'patch'   
               % Patch objects are a little complicated. 
               % See similar code in project
               if length(lat) == 1		
                  % point data; undo closure of patch
                  x = x(1); y = y(1); z = z(1);
                  set(hChild,'Vertices',[x y z],'UserData',savepts);
               else
                  if isempty(FVCD) || length(FVCD) == 1 
                     % standard mapping toolbox patches
                     faces = setfaces(x,y);	
                     % Determine the vertices of the faces for this map
                     vertices = [x y z];
                     if isempty(vertices)
                         vertices = [];
                     end
                     set(hChild,'Faces',faces,'Vertices',vertices);
                  elseif  length(FVCD)+2 == length(x) 
                     % general patches, not clipped. 
                     % SETFACES won't handle this either
                     set(hChild,'Vertices',[x(1:end-2) y(1:end-2) oldz],'UserData',savepts);
                  else
                     % general patches, clipped. 
                     % Can't clip them yet, so try to do as much right as possible
                     % Currently can trim down, but not untrim
                     [x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,oldz,'surface');
                     set(hChild,'Vertices',[x y z],'UserData',savepts);
                  end
               end

            otherwise
               if strcmp(object,'surface') 
                  %  Keep the maplegend property if available.
                  userdata = get(hChild,'UserData');      
                  mfields = char(fieldnames(userdata));       
                  indx = find(strcmp('maplegend',mfields)); 
                  if isscalar(indx)
                     savepts.maplegend = userdata.maplegend;
                  end
               end
               set(hChild,'Xdata',x,'Ydata',y,'Zdata',z,'UserData',savepts);
         end
      end
   end

   % Also handle interactive tracks, lines and sectors, which do not
   % have the signature of projected objects
   scircleg reproject
   sectorg reproject
   trackg reproject

   % Move the frame to the bottom of the stacking order to avoid blocking access to
   % other object's buttondownfcns
   hframe = findobj(gca,'Type','patch','Tag','Frame');
   uistack(hframe,'bottom')

end % if reproQ

% reset the frame. This is required for the vertical perspective
% projection, which may change the range of the frame from the center of
% the projection.
hframe = findobj(gca,'Type','patch','Tag','Frame');
if ~isempty(hframe)
   vis = get(hframe,'Visible');
   hframe = framem('reset');
   set(hframe,'Visible',vis)
end

% Restack the Frame to the bottom, so that buttondownfcns on
% objects are still accessible.
uistack(hframe,'bottom')

% Restore the mdistort lines and text if they were present before.
% These will now be recomputed for the current projection.
if ~isempty(mdistortparam)
   mdistort(mdistortparam)
end

% Restore the parallelui lines if they were present before.
if onparui
   parallelui on
end

% Update scale ruler, if present
h = handlem('scaleruler');
for k = 1:length(h)
   setm(h(k),'lat',[],'long',[],'xloc',[],'yloc',[])
end

%--------------------------------------------------------------------------
function verifyAxesChildren(ax, oldstruct, varargin)
%VERIFYAXESCHILDREN Verifies that the children of axes AX can be
% reprojected. If not, an error message is issued.

if isstruct(varargin{2})      %  Special operation from axesmui
   newstruct = varargin{2};
else
   % Update the projection from VARARGIN inputs.
   % VARARGIN{1} is the axes handle.
   newstruct = updateProjection(oldstruct, varargin{2:end});
end

% Determine if objects need to be reprojected.
reproQ = determineIfReprojecting(oldstruct, newstruct);

if reproQ
   % The axes children need to be reprojected.
   % Verify that each hggroup is either mapped or has a mapgraph object.
   children = get(ax, 'Children');
   for k = 1:numel(children)
      h = children(k);
       mapgraph = getappdata(h,'mapgraph');
       if ishghandle(h,'hggroup') && ~ismapped(h) && isempty(mapgraph)
           error(message('map:setm:hggroupHandleNotReprojectable'))
      end
   end
end

%--------------------------------------------------------------------------
function S = updateProjection(mstruct, varargin)
%UPDATEPROJECTION Update the MSTRUCT projection structure with inputs from
% VARARGIN. VARARGIN must contain at least two inputs. VARARGIN is not
% verified. The inputs will be verified with a call to AXESM.

S = mstruct;
if numel(varargin) >= 2
   validNumPairs = ~mod(numel(varargin), 2);
   paramPairs = varargin(1:2:end);
   valuePairs = varargin(2:2:end);
   validFields = validNumPairs && ...
      (numel(paramPairs) == numel(valuePairs)) && ...
      all(cellfun(@ischar, paramPairs));
   if validFields
      paramPairs = lower(paramPairs);
      % Update S with values from varargin without verifying inputs.
      for k=1:numel(paramPairs)
         S.(paramPairs{k}) = valuePairs{k};
      end
   end
end
      
%--------------------------------------------------------------------------
function setmtext(varargin)
%SETMTEXT  Processes the SETM operations for a text object
%
%  Only one property is recognized for text objects.  The MapPosition
%  property is a vector of [lat, lon, alt].  The third element, alt, is
%  optional.

if nargin == 1
    disp(' MapPosition      [2 or 3 element vector]') 
   return
elseif nargin ~= 3
    error(message('map:validate:invalidArgCount'))
end

%  Make sure that the text object is projected

if ~ismapped(varargin{1})
   error(message('map:setm:expectedProjectedObject','text'))
end

%  Make sure that the valid property is supplied

indx = findstr(lower(varargin{2}),'mapposition');  %#ok<FDEPR>
if isempty(indx) || indx ~= 1
       error(message('map:setm:unrecognizedProperty','text'))
end

%  Test the input position vector.  Set the alt value if necessary

position = varargin{3};   position = position(:);   %  Ensure vector
if length(position) ~= 2 && length(position) ~= 3
   error(message('map:setm:invalidPositionVector'))
end

%  Get the position data

lat = position(1);  lon = position(2);
if length(position) == 2   
   alt = 0;
else
   alt = position(3);
end

%  Project the new position and then
%  set the position property of the text object

[x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,alt,'text');
set(varargin{1},'Position', [x y z],'UserData',savepts);

%--------------------------------------------------------------------------
function setmsurf(varargin)
%SETMSURF  Processes the SETM operations for a surface object
%
%  Only two properties are recognized for surface objects.
%           'Graticule'   requires a lat, lon and alt matrix input
%           'MeshGrat'    requires an gratsize vector input and the surface
%                         object must be displayed using meshm, which
%                         retains the maplegend data.  An alt input
%                         can also be supplied.

if nargin == 1
   fprintf('%s\n%s\n', 'Regular Surface Maps',...
      'MeshGrat       [2 element vector of graticule size] ')
   fprintf('%s\n%s\n','General Surface Maps','Graticule      [lat,lon matrices] ')
   return

elseif nargin < 3 || nargin > 5
    error(message('map:validate:invalidArgCount'))

elseif nargin == 3
   hndl = varargin{1};
   property = 'meshgrat';
   gratsize = varargin{3};
   alt      = [];
   indx = strmatch(lower(varargin{2}),property);
   if length(indx) ~= 1
       error(message('map:setm:unrecognizedProperty','surface'))
   end

elseif nargin == 4
   hndl = varargin{1};
   validprop = {'meshgrat','graticule'};
   indx = strmatch(lower(varargin{2}),validprop);

   if length(indx) ~= 1
       error(message('map:setm:unrecognizedProperty','surface'))
   else
      property = validprop{indx};
   end

   switch property
      case 'meshgrat',      gratsize = varargin{3};    alt = varargin{4};
      case 'graticule',     lat  = varargin{3};    lon = varargin{4};
         alt  = [];
   end

elseif nargin == 5
   hndl = varargin{1};
   property = 'graticule';
   lat = varargin{3};      lon = varargin{4};   alt = varargin{5};

   indx = strmatch(lower(varargin{2}),property);
   if length(indx) ~= 1
       error(message('map:setm:unrecognizedProperty','surface'))
   end

end


%  Make sure that the surface object is projected

if ~ismapped(varargin{1})
   error(message('map:setm:expectedProjectedObject','surface'))
end

%  Test for a valid maplegend field in the userdata structure
%  Need to hold onto maplegend, to reset the user data properties

maplegend = [];
userdata = get(hndl,'UserData');
mfields = char(fieldnames(userdata));
indx = strmatch('maplegend',mfields,'exact');
if length(indx) == 1;  maplegend = userdata.maplegend;  end


switch property
   %*************************************************************
   case 'meshgrat'     %  New graticules for a regular matrix map
      %*************************************************************

      %  Test for a valid maplegend in existence

      if isempty(maplegend)
         error(message('map:setm:expectedMeshmObject'))
      end

      %  Test the gratsize vector

      gratsize = gratsize(:);
      if ~isempty(gratsize) && length(gratsize) ~= 2
         error(message('map:setm:expectedGratsizeToBe2by1'))
      end

      %  Get the map and compute the new graticule

      A = get(hndl,'Cdata');
      R = internal.map.convertToGeoRasterRef(userdata.maplegend, ...
          size(A), 'degrees', mfilename, 'R', 2);
      [lat, lon] = map.internal.graticuleFromRasterReference(R, gratsize);

      %*********************************************
   case 'graticule'     %  General map graticules
      %*********************************************

      %  Test that the lat and lon graticule matrices are the same size

      if ~ismatrix(lat) || ~ismatrix(lon)
         error(message('map:setm:expected2DGraticuleMesh'))
      elseif any(size(lat) ~= size(lon))
         error(message('map:setm:inconsistentGraticuleSizes'))
      end
end

%  Test the altitude input

if isempty(alt)
   alt = zeros(size(lat));
elseif max(size(alt)) == 1
   alt = alt(ones(size(lat)));
elseif ~ismatrix(alt) || any(size(lat) ~= size(alt))
   error(message('map:setm:expectedConsistentGraticuleAndAltitude'))
end

%  Project the new graticule and then
%  set the x and y data properties of the surface object

[x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,alt,'surface');

if ~isempty(maplegend)                        %  Restore the maplegend
   savepts.maplegend = maplegend;            %  property if necessary
end

if isequal(size(x),size(get(hndl,'Cdata')))
   set(hndl,'Xdata',x,'Ydata',y,'Zdata',z,'UserData',savepts,...
      'FaceColor','flat');
else
   set(hndl,'Xdata',x,'Ydata',y,'Zdata',z,'UserData',savepts,...
      'FaceColor','texturemap');
end

%--------------------------------------------------------------------------
function displayAxesProperties(PropString)
%  Display the text properties recognized by setm.


%  Define the Map Properties as a 2 column cell array

MapProperties = {
   'AngleUnits',     '[ {degrees} | radians ]'
   'Aspect',         '[ {normal} | transverse ]'
   'FalseEasting',    ''
   'FalseNorthing',   ''
   'FixedOrient',    'FixedOrient is a read-only property'
   'Geoid',          ''
   'MapLatLimit',    ''
   'MapLonLimit',    ''
   'MapParallels',   ''
   'MapProjection',  ''
   'NParallels',     'NParallels is a read-only property'
   'Origin',         ''
   'ScaleFactor',    ''
   'TrimLat',        'TrimLat is a read-only property'
   'TrimLon',        'TrimLon is a read-only property'
   'Zone',           ''
   'Frame',          '[ on | {off} ]'
   'FEdgeColor',     ''
   'FFaceColor',     ''
   'FFill',          ''
   'FLatLimit',      ''
   'FLineWidth',     ''
   'FLonLimit',      ''
   'Grid',           '[ on | {off} ]'
   'GAltitude',      ''
   'GColor',         ''
   'GLineStyle',     '[ - | -- | -. | {:} ]'
   'GLineWidth',     ''
   'MLineException', ''
   'MLineFill',      ''
   'MLineLimit',     ''
   'MLineLocation',  ''
   'MLineVisible',   '[ {on} | off ]'
   'PLineException', ''
   'PLineFill',      ''
   'PLineLimit',     ''
   'PLineLocation',  ''
   'PLineVisible',   '[ {on} | off ]'
   'FontAngle',      '[ {normal} | italic | oblique ]'
   'FontColor',      ''
   'FontName',       ''
   'FontSize',       ''
   'FontUnits',      '[ inches | centimeters | normalized | {points} | pixels ]'
   'FontWeight',     '[ {normal} | bold ]'
   'LabelFormat',    '[ {compass} | signed | none ]'
   'LabelRotation', '[ on | {off} ]'
   'LabelUnits',     '[ {degrees} | radians ]'
   'MeridianLabel',  '[ on | {off} ]'
   'MLabelLocation', ''
   'MLabelParallel', ''
   'MLabelRound',    ''
   'ParallelLabel',  '[ on | {off} ]'
   'PLabelLocation', ''
   'PLabelMeridian', ''
   'PLabelRound',    ''
   };


if nargin == 0;    PropString = 'all';   end

%  Display either all the properties, or the inputted property

if strcmp(PropString,'all')
   for i = 1:size(MapProperties,1)
      fprintf('%-25s   %-40s\n',MapProperties{i,1},MapProperties{i,2})
   end
else
   indx = find(strcmpi(PropString,MapProperties(:,1)));
   if isempty(indx)
      fprintf('%s\n',['Unrecognized Property String:  ',PropString])
   elseif length(indx) > 1
      fprintf('%s\n','Non-unique Property String.  Supply more characters.')
   elseif isempty(MapProperties{indx,2})
      fprintf('%s\n',...
         ['An axes''s "',MapProperties{indx,1},'" property does not have a fixed set of property values.'])
   else
      fprintf('%-25s   %-40s\n',MapProperties{indx,1},MapProperties{indx,2})
   end

end

%--------------------------------------------------------------------------
function displayTextProperties(PropString)
%  Display the text properties recognized by setm.


%  Define the Text Properties as a 2 column cell array

MapProperties = {
   'MapPosition',     ''
   };


if nargin == 0;    PropString = 'all';   end

%  Display either all the properties, or the inputted property

if strcmp(PropString,'all')
   for i = 1:size(MapProperties,1)
      fprintf('%-25s   %-40s\n',MapProperties{i,1},MapProperties{i,2})
   end
else
   indx = find(strcmpi(PropString,MapProperties(:,1)));
   if isempty(indx)
      fprintf('%s\n',['Unrecognized Property String:  ',PropString])
   elseif length(indx) > 1
      fprintf('%s\n','Non-unique Property String.  Supply more characters.')
   elseif isempty(MapProperties{indx,2})
      fprintf('%s\n',...
         ['A text''s "',MapProperties{indx,1},'" property does not have a fixed set of property values.'])
   else
      fprintf('%-25s   %-40s\n',MapProperties{indx,1},MapProperties{indx,2})
   end

end

%--------------------------------------------------------------------------
function displaySurfProperties(PropString)
%  Display the surface properties recognized by setm.

%  Define the Surface Properties as a 2 column cell array
MapProperties = {
   'Graticule',     ''
   'MeshGrat',     ''
   };

if nargin == 0   
   PropString = 'all';  
end

%  Display either all the properties, or the inputted property

if strcmp(PropString,'all')
   for i = 1:size(MapProperties,1)
      fprintf('%-25s   %-40s\n',MapProperties{i,1},MapProperties{i,2})
   end
else
   indx = find(strcmpi(PropString,MapProperties(:,1)));
   if isempty(indx)
      fprintf('%s\n',['Unrecognized Property String:  ',PropString])
   elseif length(indx) > 1
      fprintf('%s\n','Non-unique Property String.  Supply more characters.')
   elseif isempty(MapProperties{indx,2})
      fprintf('%s\n',...
         ['A surface''s "',MapProperties{indx,1},'" property does not have a fixed set of property values.'])
   else
      fprintf('%-25s   %-40s\n',MapProperties{indx,1},MapProperties{indx,2})
   end

end

%--------------------------------------------------------------------------
function displayScaleProperties(PropString)
%  Display the scale ruler properties recognized by setm.

%  Define the Surface Properties as a 2 column cell array
MapProperties = {
   'Azimuth',				''
   'Children',				'Children is a read-only property'
   'Color',				''
   'FontAngle',			'[ {normal} | italic | oblique ]'
   'FontName',				''
   'FontSize',				''
   'FontUnits',			'[ inches | centimeters | normalized | {points} | pixels ]'
   'FontWeight',			'[ light | {normal} | demi | bold ]'
   'Label',				''
   'Lat',					''
   'LineWidth',			''
   'Long',					''
   'MajorTick',			''
   'MajorTickLabel',		''
   'MajorTickLength',		''
   'MinorTick',			''
   'MinorTickLabel',		''
   'MinorTickLength',		''
   'Radius',				''
   'RulerStyle',			'{ruler} | lines | patches '
   'TickDir',				'[{up} | down]'
   'TickMode',				'[{auto} | manual]'
   'Units',				'[ (valid distance unit strings) ]'
   'XLoc',					''
   'YLoc',					''
   'ZLoc',					''
   };


if nargin == 0;    PropString = 'all';   end

%  Display either all the properties, or the inputted property

if strcmp(PropString,'all')
   for i = 1:size(MapProperties,1)
      fprintf('%-25s   %-40s\n',MapProperties{i,1},MapProperties{i,2})
   end
else
   indx = find(strcmpi(PropString,MapProperties(:,1)));
   if isempty(indx)
      fprintf('%s\n',['Unrecognized Property String:  ',PropString])
   elseif length(indx) > 1
      fprintf('%s\n','Non-unique Property String.  Supply more characters.')
   elseif isempty(MapProperties{indx,2})
      fprintf('%s\n',...
         ['A scale ruler''s "',MapProperties{indx,1},'" property does not have a fixed set of property values.'])
   else
      fprintf('%-25s   %-40s\n',MapProperties{indx,1},MapProperties{indx,2})
   end

end

%--------------------------------------------------------------------------
function reproQ = determineIfReprojecting(oldstruct, newstruct)
%determineIfReprojecting Determine if the axes objects need to be
% reprojected.

reproQ=1;
mstructdiff = fielddiff(oldstruct,newstruct);
if ~isstruct(mstructdiff) &&  mstructdiff == 0
   reproQ = 0;
elseif ~isstruct(mstructdiff) && mstructdiff == 1 	
   % structure fields different.
   % Not properly updated for new fields?
   reproQ = 1;
elseif ~isequal(1,mstructdiff)
   reproQ = reprojectQ(mstructdiff);
end

%--------------------------------------------------------------------------
function reproQ = reprojectQ(sdiff)
%REPROJECTQ determine if projected objects need to be reprojected
% properties which affect projected objects

objectprops = {
   'mapprojection'
   'zone'
   'angleunits'
   'aspect'
   'geoid'
   'maplatlimit'
   'maplonlimit'
   'flatlimit'
   'flonlimit'
   'mapparallels'
   'origin'
   'falsenorthing'
   'falseeasting'
   'scalefactor'
   'trimlat'
   'trimlon'
   };

reproQ = 0;
for i=1:length(objectprops)
   reproQ = reproQ | sdiff.(objectprops{i});
end

%--------------------------------------------------------------------------
function sdiff = fielddiff(s1,s2)

% FIELDDIFF compares contents of two structures, puts 1 in the fields that are different
if isequal(s1,s2)
   sdiff = 0;
else
   fields1 = sort(fieldnames(s1));
   fields2 = sort(fieldnames(s2));

   if isequal(fields1,fields2)
      sdiff = struct; % in case there are no fields at all
      for i=1:length(fields1)

         sdiff.(fields1{i}) = ~isequal( s1.(fields1{i}), s2.(fields1{i}));
      end
   else
      sdiff = 1;
   end
end

%--------------------------------------------------------------------------
function h = getMapGraphHandle(h)
% Obtain the handle or handles to the mapgraph object.

ax = ancestor(h, 'axes');
if isequal(get(h, 'type'), 'surface')
    % Find the secondary surface handle, if present, by matching the
    % mapgraph_ID appdata. If found, then add it to the return handle.
    hSurfaces = findall(ax, 'Type','surface');
    appdataName = 'mapgraph_ID';
    if isappdata(h, appdataName)
        mapgraphID = getappdata(h, appdataName);
        hSecondary = [];
        k = 1;
        while(isempty(hSecondary) && k <= numel(hSurfaces))
            if isappdata(hSurfaces(k), appdataName)
                mapgraphID_2 = getappdata(hSurfaces(k), appdataName);
                if isequal(mapgraphID, mapgraphID_2)
                    hSecondary = hSurfaces(k);
                end
            end
            k = k+1;
        end
        h = [h hSecondary];
    end
end

%-----------------------------------------------------------------------

function tf = mnemonicMatches(identifier, options)
% Return true if the last part of the colon-delimited string IDENTIFIER,
% typically called the mnemonic, is an exact match for any of the strings
% in the cell string OPTIONS.

parts = textscan(identifier,'%s','Delimiter',':');
mnemonic = parts{1}{end};
tf = any(strcmp(mnemonic,options));

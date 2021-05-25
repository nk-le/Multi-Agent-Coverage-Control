function [h,msg] = axesm(varargin)
%AXESM Define map axes and set map properties
%
%  AXESM activates a GUI to define a map projection for the current axes.
%
%  AXESM(PROPERTYNAME, PROPERTYVALUE,...) uses the map properties in the
%  input list to define a map projection for the current axes. For a list
%  of map projection properties, execute GETM AXES.  All standard
%  (non-mapping) axes properties are controlled using the axes command. For
%  a list of available projections, execute MAPS.
%
%  AXESM(PROJID,...) uses PROJID to designate which map projection to use.
%  PROJID should match one of the entries in the last column of the table
%  displayed by the MAPS function.
%
%  See also AXES, GETM, MAPLIST, MAPS, PROJFWD, PROJINV, PROJLIST, SETM

% Copyright 1996-2020 The MathWorks, Inc.

% The following syntax is invoked from within Mapping Toolbox(TM)
% function SETM, but is not intended for general use.
%
%    AXESM(MSTRUCT,...) uses the map structure specified by MSTRUCT to
%                       initialize the map projection.

% Obsolete syntax
% ---------------
% [h,msg] = AXESM(...) returns a message indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

%  Initialize output variables
if nargout ~= 0
    h = [];
end

%  Initialize default map structure.
%  Save each of the field names to compare with passed in properties

mstruct = initmstruct;            %  AXESM algorithm requires mfields to
mfields = fieldnames(mstruct);    %  always remain a cell array.

%  Test input arguments
if (nargin > 0) && any(ishghandle(varargin{1}))
    error(message('map:axesm:invalidFirstParameter','AXESM'))
end

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
if nargin == 0
    % AXESM
    if ~ismap(gca)
        [~,defproj] = maplist; % get the default projection
        mstruct.mapprojection = defproj;
        mstruct = feval(mstruct.mapprojection,mstruct);
        mstruct = resetmstruct(mstruct);
        set(gca,...
            'NextPlot','Add', ...
            'UserData',mstruct, ...
            'DataAspectRatio',[1 1 1], ...
            'Box','on',...
            'ButtonDownFcn',@uimaptbx)
        %  May not hit mapprojection case with non-map axes
        set(gca,'XLimMode','auto','YLimMode','auto')
        showaxes off
    end
    cancelflag = axesmui;
    if nargout ~= 0
        h = cancelflag;
    end
elseif nargin == 1 && ~ischar(varargin{1}) && ~isstruct(varargin{1}) ...
        && ~isstring(varargin{1})
    gcm(varargin{1})
    axes(varargin{1});
else
    if rem(nargin,2)
        if isstruct(varargin{1})
            % AXESM(MSTRUCT,...)
            mstruct   = varargin{1};
            startpt   = 2;
            newfields  = sortrows(char(fieldnames(mstruct)));
            testfields = sortrows(char(mfields));
            if any(size(testfields) ~= size(newfields)) ...
                    || any(any(testfields ~= newfields))
                error(message('map:axesm:invalidMap'))
            end
        else
            % AXESM(PROJFCN,...)
            startpt = 2;
            try
                mstruct.mapprojection = maps(varargin{1});
                mstruct = feval(mstruct.mapprojection,mstruct);
            catch %#ok<CTCH>
                if exist(varargin{1},'file') == 2
                    mstruct = feval(varargin{1},mstruct);
                else
                    error(message('map:axesm:undefinedMapAxis'))
                end
            end
        end
    else
        % AXESM(PROPERTYNAME, PROPERTYVALUE,...)
        startpt = 1;
    end

    %  Permute the property list so that 'angleunits' (if supplied) is first
    %  and 'mapprojection' is second.  'angleunits' must be processed first
    %  so that all defaults end up in the proper units.  'mappprojection'
    %  must be processed second so that any supplied parameter, such as
    %  'parallels', is not overwritten by the defaults in the projection
    %  function.
    varargin(1:(startpt-1)) = [];
    varargin = reorderprops(varargin);

    % Assign variables to test if a reset property is being set to 'reset'.
    resetFrameGrat = false;
    resetProperties = {'grid', 'meridianlabel', 'parallellabel' ,'frame'};
    
    % Validate the property name-value pairs.
    n = length(varargin)/2;
    propname = cell(n,1);
    propvalue = cell(n,1);
    j = 0;
    for k = 1 : 2 : numel(varargin)
        j = j + 1;
        % Allow 'spheroid' as a synonym for 'geoid'
        [propname{j}, propvalue{j}] = validateprop(varargin, [{'spheroid'}; mfields], k);
        if strcmp(propname{j},'spheroid')
            propname{j} = 'geoid';
        end
        if isequal(propvalue{j}, 'reset') && ...
                any(strncmp(propname{j}, resetProperties, numel(propname{j})))
             resetFrameGrat = true;
        end
    end
    
    % Apply pre-processing if the mapprojection is UTM.
    % If the mapprojection is being set to UTM using Name,Value pairs, and
    % latitude and longitude limits are available, and 'zone' is not
    % included, then add a new 'zone' propname and propvalue calculated by
    % using utmzone and the limits.
    %
    % If 'zone' and limits are included and the zone value is empty, then
    % calculate and replace its value in propvalue by using utmzone and the
    % limits. Otherwise make no changes.
    projIndex = find(strcmpi('mapprojection',propname));
    if ~isempty(projIndex) && strcmpi('utm', propvalue{projIndex})
        [propname, propvalue] = preprocessUTM(projIndex, propname, propvalue, mstruct);
    end
           
    % True if an mstruct is supplied to the function and the projection is
    % UTM. This condition requires post processing.
    mapProjSetToUTM = strcmpi(mstruct.mapprojection, 'utm');
    
    % Set the fields of the mstruct.
    for j = 1:numel(propname)
        mstruct = setprop(mstruct, propname{j}, propvalue{j});
    end

    % Remove possible NaN left by setMapLatLimit.
    mstruct.origin(isnan(mstruct.origin)) = 0;
    
    % Check for defaults to be computed.
    mstruct = resetmstruct(mstruct);
    
    if mapProjSetToUTM && ~isempty(mstruct.maplatlimit) && ~isempty(mstruct.maplonlimit)
        % mapProjSetToUTM is true if the projection is UTM and using setm
        % or if axesm is provided with an mstruct. Post process the mstruct
        % to potentially reset the zone value, if needed, to prevent the
        % frame from being skewed.
        mstruct = postprocessUTM(mstruct);        
    end
    
    if resetFrameGrat
        % Update the axes with the new mstruct.
        set(gca, 'UserData', mstruct);
    else
        % Set GCA to be a map axes
        setgca(mstruct)
    end

    %  Display map frame, lat-lon graticule, and meridian and parallel
    %  labels, if necessary
    setframegrat(mstruct)

    %  Set output variable if necessary
    if nargout >= 1
        h = gca;
    end
end

%-----------------------------------------------------------------------

function props = reorderprops(props)
% Permute the property list, moving the following properties (when
% present) to the start and ordering them as listed here: angleunits,
% mapprojection, zone, origin, flatlimit, flonlimit, maplatlimit,
% maplonlimit.  Also, convert all the property names to lower case.

% Reshape to a 2-by-N: Property names are in row 1, values in row 2.
props = reshape(props,[2,numel(props)/2]);

% Convert all property names to lower case.
for k = 1:size(props,2)
   props{1,k} = char(props{1,k});
end
props(1,:) = lower(props(1,:));

% Index properties: 101, 102, 103, ...
indx = 100 + (1:size(props,2));

% Determine which columns contain 'angleunits', 'mapprojection', etc.
indx(strmatch('an',    props(1,:))) = 1;  %#ok<*MATCH2> % 'angleunits' 
indx(strmatch('mappr', props(1,:))) = 2;  % 'mapprojection'
indx(strmatch('z',     props(1,:))) = 3;  % 'zone'
indx(strmatch('o',     props(1,:))) = 4;  % 'origin'
indx(strmatch('fla',   props(1,:))) = 5;  % 'flatlimit'
indx(strmatch('flo',   props(1,:))) = 6;  % 'flonlimit'
indx(strmatch('mapla', props(1,:))) = 7;  % 'maplatlimit'
indx(strmatch('maplo', props(1,:))) = 8;  % 'maplonlimit'

% Sort indx and save the required permutations in indexsort.
[~, indexsort] = sort(indx);

% Permute the columns of props.
props = props(:,indexsort);

% Turn props back into a row vector.
props = props(:)';

%-----------------------------------------------------------------------

function [propname, propvalu] = validateprop(props, mfields, j)

%  Get the property name and test for validity.
try
    propname = validatestring(props{j}, mfields, 'axesm');
catch e
    if mnemonicMatches(e.identifier, {'unrecognizedStringChoice'})
        error(message('map:axesm:unrecognizedProperty',props{j}))
    elseif mnemonicMatches(e.identifier, {'ambiguousStringChoice'})
        error(message('map:axesm:ambiguousPropertyName',props{j}))
    else
        e.rethrow();
    end
    
end

%  Get the property value, ensure that it's a row vector and convert
%  string-valued property values to lower case.
propvalu = props{j+1};
propvalu = propvalu(:)';
if ischar(propvalu) || (isstring(propvalu) && isscalar(propvalu))
    propvalu = char(propvalu);
    propvalu = lower(propvalu);
end

%-----------------------------------------------------------------------

function [propname, propvalue] = preprocessUTM( ...
    projIndex, propname, propvalue, mstruct)
% Add 'zone' to propname and a calculated value to propvalue if it is not
% included and if maplatlimit and maplonlimit are set. If it is included
% but empty and maplatlimit and maplonlimit are set, then calculate a new
% value and reset its value in propvalue. Otherwise make no changes. Make
% no changes if the zone value calculation results in an error.

zoneIndex = strcmpi('zone',propname);
haveZone = any(zoneIndex);
zoneIsEmpty = haveZone && isempty(propvalue{zoneIndex});

maplatlimitIndex = strcmpi('maplatlimit',propname);
haveMaplatlimit = any(maplatlimitIndex);

maplonlimitIndex = strcmpi('maplonlimit',propname);
haveMaplonlimit = any(maplonlimitIndex);

if haveMaplatlimit && haveMaplonlimit && (~haveZone || zoneIsEmpty)
    latlim = propvalue{maplatlimitIndex};
    lonlim = propvalue{maplonlimitIndex};
    
    unitsIndex = strcmpi('angleunits',propname);
    if any(unitsIndex) 
        angleUnits = propvalue{unitsIndex};
    else
        angleUnits = mstruct.angleunits;
    end
    
    try
        zone = calculateZoneFromLimits(angleUnits, latlim, lonlim);
        if zoneIsEmpty
            % Zone is set (but empty)
            propvalue{zoneIndex} = zone;
        else
            % Zone is not set, include.
            propname = [propname(1:projIndex); 'zone'; propname(projIndex+1:end)];
            propvalue = [propvalue(1:projIndex); zone;  propvalue(projIndex+1:end)];
        end
    catch
        % Ignore errors, use default
    end
end

%-----------------------------------------------------------------------

function mstruct = postprocessUTM(mstruct)
% Recalculate the zone value from the map limits. Reset the zone value in
% the mstruct if the quadrangle formed by the limits of the current zone do
% not intersect the quadrangle of the current limits. This will allow the
% user to specify limits that extend well outside the zone, as long as they
% intersect with the zone itself. When the quadrangles do not intersect,
% the zone reset prevents the frame from being skewed. If there are any
% errors, do not reset the zone.

% Obtain values from mstruct.
latlim = mstruct.maplatlimit;
lonlim = mstruct.maplonlimit;
angleUnits = mstruct.angleunits;

try
    % Calculate zone from current map limits.
    zone = calculateZoneFromLimits(angleUnits, latlim, lonlim);
    
    % Calculate limits of current zone.
    [latlimZone, lonlimZone] = utmzone(mstruct.zone);
    
    % Determine if bounding boxes of the zones intersect.
    [latlim, lonlim] = toDegrees(angleUnits, latlim, lonlim);
    [ilat, ilon] = intersectgeoquad(latlim, lonlim, latlimZone, lonlimZone);
    boundingBoxesDoNotIntersect = isempty(ilat) && isempty(ilon);
    
    if boundingBoxesDoNotIntersect
        % Reset the zone value.
        mstruct.zone = zone;
        mstruct.origin = [];
        mstruct.flatlimit = [];
        mstruct.flonlimit = [];
        mstruct = defaultm(mstruct);
    end
catch
    % Ignore all errors.
end

%-----------------------------------------------------------------------

function zone = calculateZoneFromLimits(angleUnits, latlim, lonlim)
% Calculate a zone value from latitude and longitude limits. Use the mean
% value of the limits.

[latlim, lonlim] = toDegrees(angleUnits, latlim, lonlim);
lat = mean(latlim);
lon = centerlon(lonlim);
zone = utmzone(lat, lon);

%-----------------------------------------------------------------------

function lon = centerlon(lonlim)
% Center of an interval in longitude
%
%   Accounts for wrapping.  Returns the longitude of the meridian halfway
%   from the western limit to the eastern limit, when traveling east.
%   All angles are in degrees.

lon = wrapTo180(lonlim(1) + wrapTo360(diff(lonlim))/2);

%-----------------------------------------------------------------------

function mstruct = setprop(mstruct, propname, propvalu)

switch propname

    %*************************************
    %  Properties That Get Processed First
    %*************************************

    case 'angleunits'
        mstruct = setAngleUnits(mstruct,propvalu);

    case 'mapprojection'
        mstruct = setMapProjection(mstruct, propvalu);
        
    case 'zone'
        mstruct = setZone(mstruct, propvalu);

    case 'origin'
        mstruct = setOrigin(mstruct, propvalu);

    case 'flatlimit'
        mstruct = setflatlimit(mstruct, propvalu);

    case 'flonlimit'
        mstruct = setflonlimit(mstruct, propvalu);

    case 'maplatlimit'
        if isempty(propvalu)
            mstruct.maplatlimit = [];
        else
            mstruct = setMapLatLimit(mstruct, propvalu);
        end

    case 'maplonlimit'
        if isempty(propvalu)
            mstruct.maplonlimit = [];
        else
            mstruct = setMapLonLimit(mstruct, propvalu);
        end

    %************************
    %  General Map Properties
    %************************

    case 'aspect'
        mstruct.aspect = validateStringValue(propvalu, ...
            {'normal','transverse'}, propname);

    case 'geoid'
        if isa(propvalu,'oblateSpheroid') || isa(propvalu,'referenceSphere')
            mstruct.geoid = propvalu;
        else
            mstruct.geoid = checkellipsoid(propvalu,'AXESM','ELLIPSOID');
        end
        
    case 'mapparallels'
        if ischar(propvalu) || length(propvalu) > 2
            invalidPropertyValue(propname)
        elseif mstruct.nparallels == 0
            error(message('map:axesm:unsupportedProperty', ...
                upper('mapparallels')))
        elseif numel(propvalu) > mstruct.nparallels
            error(message('map:axesm:tooManyElements', ...
                upper('mapparallels')))
        else
            mstruct.mapparallels = propvalu;
        end

    case 'scalefactor'
        if ~isnumeric(propvalu) || length(propvalu) > 1 ||  propvalu == 0
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('scalefactor')))
            else
                mstruct.scalefactor = propvalu;
            end
        end

    case 'falseeasting'
        if ~isnumeric(propvalu) || length(propvalu) > 1
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('falseeasting')))
            else
                mstruct.falseeasting = propvalu;
            end
        end

    case 'falsenorthing'
        if ~isnumeric(propvalu) || length(propvalu) > 1
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('falsenorthing')))
            else
                mstruct.falsenorthing = propvalu;
            end
        end


    %******************
    %  Frame Properties
    %******************

    case 'frame'
        value = validateStringValue(propvalu, {'on','off','reset'}, propname);        
        if strcmp(value,'reset')
            value = 'on';
        end       
        mstruct.frame = value;

    case 'fedgecolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.fedgecolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'ffacecolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.ffacecolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'ffill'
        if ~ischar(propvalu)
            mstruct.ffill = max([propvalu,2]);
        else
            invalidPropertyValue(propname)
        end

    case 'flinewidth'
        if ~ischar(propvalu)
            mstruct.flinewidth = max([propvalu(:),0]);
        else
            invalidPropertyValue(propname)
        end

    %*************************
    %  General Grid Properties
    %*************************

    case 'grid'
       
        value = validateStringValue(propvalu, {'on','off','reset'}, propname);        
        if strcmp(value,'reset')
            value = 'on';
        end        
        mstruct.grid = value;

    case 'galtitude'
        if ~ischar(propvalu)
            mstruct.galtitude = propvalu(1);
        else
            invalidPropertyValue(propname)
        end

    case 'gcolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.gcolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'glinestyle'
        lstyle = internal.map.parseLineSpec(propvalu);
        mstruct.glinestyle = lstyle;
        if isempty(lstyle)
            warning(message('map:axesm:missingGridLineStyle'))
        end

    case 'glinewidth'
        if ~ischar(propvalu)
            mstruct.glinewidth = max([propvalu(:),0]);
        else
            invalidPropertyValue(propname)
        end


    %**************************
    %  Meridian Grid Properties
    %**************************

    case 'mlineexception'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        else
            mstruct.mlineexception = propvalu;
        end

    case 'mlinefill'
        if ~ischar(propvalu)
            mstruct.mlinefill = max([propvalu, 2]);
        else
            invalidPropertyValue(propname)
        end

    case 'mlinelimit'
        if ischar(propvalu) || length(propvalu) ~= 2
           invalidPropertyValue(propname)
        else
            mstruct.mlinelimit = propvalu;
        end

    case 'mlinelocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.mlinelocation = abs(propvalu);
        else
            mstruct.mlinelocation = propvalu;
        end

    case 'mlinevisible'
        mstruct.mlinevisible = validateStringValue( ...
            propvalu, {'on','off'}, propname);

    %**************************
    %  Parallel Grid Properties
    %**************************

    case 'plineexception'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        else
            mstruct.plineexception = propvalu;
        end

    case 'plinefill'
        if ~ischar(propvalu)
            mstruct.plinefill = max([propvalu, 2]);
        else
            invalidPropertyValue(propname)
        end

    case 'plinelimit'
        if ischar(propvalu) || length(propvalu) ~= 2
            invalidPropertyValue(propname)
        else
            mstruct.plinelimit = propvalu;
        end

    case 'plinelocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.plinelocation = abs(propvalu);
        else
            mstruct.plinelocation = propvalu;
        end

    case 'plinevisible'
        mstruct.plinevisible = validateStringValue( ...
            propvalu, {'on','off'}, propname);

    %**************************
    %  General Label Properties
    %**************************

    case 'fontangle'
        mstruct.fontangle = validateStringValue( ...
            propvalu, {'normal','italic','oblique'}, propname);

    case 'fontcolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.fontcolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'fontname'
        if ischar(propvalu)
            mstruct.fontname = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'fontsize'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.fontsize = propvalu;
        end

    case 'fontunits'
        mstruct.fontunits = validateStringValue(propvalu, ...
             {'points','normalized', 'inches','centimeters','pixels'}, ...
             propname);

    case 'fontweight'
        mstruct.fontweight = validateStringValue( ...
            propvalu, {'normal','bold'}, propname);
        
    case 'labelformat'
        mstruct.labelformat = validateStringValue( ...
            propvalu, {'compass','signed','none'}, propname);

    case 'labelunits'
        if strncmpi(propvalu, 'dms', numel(propvalu))
            mstruct.labelunits = lower(propvalu);
        else
            mstruct.labelunits = checkangleunits(propvalu);
        end
        
    case 'labelrotation'
        mstruct.labelrotation = validateStringValue( ...
            propvalu, {'on','off'}, propname);
        
        %***************************
    %  Meridian Label Properties
    %***************************

    case 'meridianlabel'
        value =  validateStringValue( ...
            propvalu, {'on','off','reset'}, propname);
        if strcmp(value,'reset')
            value = 'on';
        end
        mstruct.meridianlabel = value;

    case 'mlabellocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.mlabellocation = abs(propvalu);
        else
            mstruct.mlabellocation = propvalu;
        end

    case 'mlabelparallel'
        if ischar(propvalu)
            mstruct.mlabelparallel = validateStringValue( ...
                propvalu, {'north','south','equator'}, propname);
        elseif length(propvalu) == 1
            mstruct.mlabelparallel = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'mlabelround'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.mlabelround = round(propvalu);
        end


    %***************************
    %  Parallel Label Properties
    %***************************

    case 'parallellabel'
        value = validateStringValue( ...
            propvalu, {'on','off','reset'}, propname);
        if strcmp(value,'reset')
            value = 'on';
        end
        mstruct.parallellabel = value;

    case 'plabellocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.plabellocation = abs(propvalu);
        else
            mstruct.plabellocation = propvalu;
        end

    case 'plabelmeridian'
        if ischar(propvalu)
            mstruct.plabelmeridian = validateStringValue( ...
                propvalu, {'east','west','prime'}, propname);
        elseif length(propvalu) == 1
            mstruct.plabelmeridian = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'plabelround'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.plabelround = round(propvalu);
        end

    otherwise
        error(message('map:axesm:readOnlyProperty', upper(propname)))
end

%-----------------------------------------------------------------------

function mstruct = setflatlimit(mstruct, flatlimit)

if ischar(flatlimit) || length(flatlimit) > 2
    invalidPropertyValue('flatlimit')
elseif strcmp(mstruct.mapprojection,'globe')
    warning(message('map:axesm:flatlimitGlobe','FLatLimit','globe'))
else
    mstruct.flatlimit = flatlimit;
end

%-----------------------------------------------------------------------

function mstruct = setflonlimit(mstruct, flonlimit)

if ischar(flonlimit) || (length(flonlimit) ~= 2 && ~isempty(flonlimit))
    invalidPropertyValue('flonlimit')
elseif strcmp(mstruct.mapprojection,'globe')
    warning(message('map:axesm:flonlimitGlobe','FLonLimit','globe'))
else
    mstruct.flonlimit = flonlimit;
end

%-----------------------------------------------------------------------

function setgca(mstruct)

%  Set GCA to be map axes.
set(gca, ...
    'NextPlot','Add',...
    'UserData',mstruct,...
    'DataAspectRatio',[1 1 1],...
    'Box','on', ...
    'ButtonDownFcn',@uimaptbx)

%  Show the axes background but not the axes labels.
showaxes('off');

%-----------------------------------------------------------------------

function setframegrat(mstruct)

%  Display grid and frame if necessary
if strcmp(mstruct.frame,'on')
    framem('reset');
end

if strcmp(mstruct.grid,'on')
    gridm('reset');
end

if strcmp(mstruct.meridianlabel,'on')
    mlabel('reset');
end

if strcmp(mstruct.parallellabel,'on')
    plabel('reset');
end

%-----------------------------------------------------------------------

function value = validateStringValue(value, options, propname)
% If VALUE is a string that uniquely matches an element in the string
% cell OPTIONS, return that element. Otherwise throw an error announcing an
% invalid property value.

if isscalar(value) && isa(value, "matlab.lang.OnOffSwitchState")
    value = char(value);
end

try
    value = validatestring(value, options, 'axesm');
catch e
    if mnemonicMatches(e.identifier, ...
            {'ambiguousStringChoice','unrecognizedStringChoice'})
        invalidPropertyValue(propname)
    else
        e.rethrow();
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

%-----------------------------------------------------------------------

function invalidPropertyValue(propname)
% Throw error to indicate that the value provided for property
% PROPNAME is not value.

throwAsCaller(MException('map:validate:invalidPropertyValue', ...
    'AXESM', upper(propname)))

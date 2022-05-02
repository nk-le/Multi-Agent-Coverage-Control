function [h,msg] = handlem(object,ax,searchmethod)
%HANDLEM Handles of displayed map objects
%
%   H = HANDLEM or H = HANDLEM('taglist') displays a dialog box for
%   selecting objects in the current axes that have their Tag property set.
%
%   H = HANDLEM('prompt') displays a dialog box for selecting objects in
%   the current axes based on the object strings listed below.
%
%   H = HANDLEM('visible') returns the handles of the children of the
%   current axes whose Visible property is set to 'on'.
%
%   H = HANDLEM('hidden') returns the handles of the children of the
%   current axes whose Visible property is set to 'off'.
%
%   H = HANDLEM(OBJECT), where OBJECT is one of the strings listed below,
%   returns the handles of matching objects in the current axes.
%
%   H = HANDLEM(TAGSTR), where TAGSTR is not one of the supported OBJECT
%   strings listed below, returns handles for those objects whose tags
%   exactly match TAGSTR.
%
%   H = HANDLEM(___, AXESH) searches within the axes with handle AXESH.
%
%   H = HANDLEM(TAGSTR, AXESH, SEARCHMETHOD) controls the method used to
%   match the TAGSTR input. If omitted, 'exact' is assumed. Search method
%   'strmatch' searches for matches that start at the beginning of the tag.
%   Search method 'findstr' searches anywhere within the TAGSTR.
%
%   H = HANDLEM(HANDLES) returns the elements of the vector HANDLES that
%   are valid handles to graphics objects.
%
%   List of supported OBJECT values:
%
%      ALL         All objects
%      ALLIMAGE    All image objects
%      ALLLIGHT    All light objects
%      ALLLINE     All line objects
%      ALLPATCH    All patch objects
%      ALLSURFACE  All surface objects
%      ALLTEXT     All text objects
%      CLABEL      Contour labels
%      CONTOUR     hggroups containing contours
%      FILLCONTOUR hggroups containing filled contours
%      FRAME       Map frame
%      GRID        Map grid lines
%      HGGROUP     All hggroup objects
%      IMAGE       Untagged image objects
%      LIGHT       Untagged light objects
%      LINE        Untagged line objects
%      MAP         All objects on the map axes, excluding the frame and grid
%      MERIDIAN    Longitude grid lines
%      MLABEL      Longitude labels
%      PARALLEL    Latitude grid lines
%      PLABEL      Latitude labels
%      PATCH       Untagged patch objects
%      SCALERULER  Scaleruler objects
%      SURFACE     Untagged surface objects
%      TEXT        Untagged text objects
%      TISSOT      Tissot indicatrices
%
%   If there is no current axes or if AXESH is empty, the result H will be
%   empty. If the current axes or AXESH is not a map axes, handlem('map')
%   will error.
%
%  See also FINDOBJ

% Copyright 1996-2017 The MathWorks, Inc.

% Obsolete syntax
% ---------------
% [h,msg] = HANDLEM(...) returns a string indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

if nargin < 1
    % HANDLEM is equivalent to HANDLEM('taglist')
    object = 'taglist';
end

if nargin < 2
    % Assign to ax the handle of the current axes. If there is no
    % current axes, ax will be empty.
    ax = get(get(0,'CurrentFigure'),'CurrentAxes');
end

if nargin < 3
    searchmethod = 'exact';
else
    searchmethod = validatestring(searchmethod, ...
        {'exact','findstr','strmatch'},'','METHOD',3);
end

if ~ischar(object) && ~isStringScalar(object)
    % HANDLEM(HANDLES)
    
    % The AXESH and SEARCHMETHOD inputs are not needed;
    % if they were supplied anyway, just ignore them.
    h = object;
    if ~isempty(h)
        validateattributes(h,{'double','handle'},{'vector'},mfilename,'HANDLES',1)
        h = h(ishghandle(h));
    end
else
    % Ensure string input
    validateattributes(object,{'char','string'},{'scalartext'},'','',1)
    
    if isempty(ax)
        h = gobjects(0);
    else
        % The first input argument has the value 'prompt' or 'taglist', or
        % is an OBJECT or TAGSTR string.  AX is non-empty.
 
        % Validate axes
        validateattributes(ax,{'double','handle'},{'scalar'},'','AXESH',2)
        if ~ishghandle(ax,'axes')
            error('map:validate:expectedAxesHandle', ...
                'Expected input %s to be a valid axes handle.','AX')
        end
       
        if strcmpi(object,'all')
            % HANDLEM('all',___) or HANDLEM('all',AX)
            h = get(ax,'children');
        elseif strcmpi(object,'visible')
            % HANDLEM('visible',___) or HANDLEM('visible',AX)
            h = findobj(get(ax,'children'),'Visible','on');
        elseif strcmpi(object,'hidden')
            % HANDLEM('hidden',___) or HANDLEM('hidden',AX)
            h = findobj(get(ax,'children'),'Visible','off');
        elseif strcmpi(object,'taglist')
            % HANDLEM('taglist') or HANDLEM('taglist',AX)
            %    Allow for multiple selections
            tags = promptWithTags(ax);
            h = cellfun(@(tag) findTagMatch(tag,ax,searchmethod), ...
                tags, 'UniformOutput', false);
            h =  unique(vertcat(h{:}),'stable');
        elseif strcmpi(object,'prompt')
            % HANDLEM('prompt',___)
            
            objectDescriptionList = objectDescriptions();
            [index, OK] = listdlg( ...
                'Name', 'Choose Object Description', ...
                'ListString',objectDescriptionList(:,2), ...
                'SelectionMode','multiple', ...
                'ListSize',[300 300]);
            if OK
                % Allow for multiple descriptions
                names = objectDescriptionList(index,1);
                h = cellfun(@(name) findObjectMatch(name,ax), ...
                    names, 'UniformOutput', false);
                h = unique(vertcat(h{:}),'stable');
            else
                h = gobjects(0);
            end
        else
            % HANDLEM(OBJECT) or HANDLEM(OBJECT,AX)
            % HANDLEM(TAGSTR) or HANDLEM(TAGSTR,AX) or
            %   HANDLEM(TAGSTR,AX,SEARCHMETHOD)
            
            % Look for an exact match in the list of supported names.
            objectDescriptionList = objectDescriptions();
            supportedObjectNames = objectDescriptionList(:,1);
            index = find(strcmpi(object,supportedObjectNames));
            
            % The elements of objectnames are unique, so index will be
            % either empty or scalar. (It cannot contain multiple
            % elements.)
            if isscalar(index)
                h = findObjectMatch(supportedObjectNames{index},ax);
            else
                % The first input is not a exact match for any of the
                % supported object names, so search for objects with
                % matching tags.
                h = findTagMatch(object,ax,searchmethod);
            end
        end
    end
end

if isempty(h)
    h = gobjects(0);
end

%--------------------------------------------------------------------------

function objectDescriptionList = objectDescriptions()

objectDescriptionList = { ...
       'ALL',        'All objects'
       'ALLIMAGE'    'All image objects'
       'ALLLIGHT'    'All light objects'
       'ALLLINE'     'All line objects'
       'ALLPATCH'    'All patch objects'
       'ALLSURFACE'  'All surface objects'
       'ALLTEXT'     'All text objects'
       'CLABEL'      'Contour labels'
       'CONTOUR'     'hggroups containing contours'
       'FILLCONTOUR' 'hggroups containing filled contours'
       'FRAME'        'Map frame'
       'GRID'        'Map grid lines'
       'HGGROUP'     'All hggroup objects'
       'IMAGE'       'Untagged image objects'
       'LIGHT'       'Untagged light objects'
       'LINE'        'Untagged line objects'
       'MAP'         'All objects on map, excluding frame and grid'
       'MERIDIAN'    'Longitude grid lines'
       'MLABEL'      'Longitude labels'
       'PARALLEL'    'Latitude grid lines'
       'PLABEL'      'Latitude labels'
       'PATCH'       'Untagged patch objects'
       'SCALERULER'  'Scaleruler objects'
       'SURFACE'     'Untagged surface objects'
       'TEXT'        'Untagged text objects'
       'TISSOT'      'Tissot indicatrices'
       };

objectDescriptionList(:,1) = lower(objectDescriptionList(:,1));

%--------------------------------------------------------------------------

function h = findObjectMatch(object,ax)

%  Determine if prefix 'all' is applied.
basicTypes = {'image','light','line','patch','surface','text'};
allflag = isequal(strfind(lower(object),'all'),1) ...
    && any(strcmpi(object(4:end), basicTypes));
if allflag
    object(1:3) = [];
end

children = get(ax,'Children');

switch object
    
    case 'all'
        h = children;
        
    case {'image','light','line','patch','surface','text'} % Basic types
        if allflag
            h = findobj(children,'Type',object);
        else
            h = findobj(children,'Type',object,'Tag','');
        end
        
    case 'clabel'
        g = findContourHandle(children);
        h = findobj(g, 'Type', 'text');
        
    case 'contour'
        h = findContourHandle(children);
        
    case 'fillcontour'
        h = findFillContourHandle(children);
        
    case 'hggroup'
        h = findobj(children,'Type','hggroup');
        
    case 'frame'
        h = findobj(children,'Tag','Frame');
        
    case 'grid'
        h = [ ...
            findobj(children,'Tag','Parallel');
            findobj(children,'Tag','Meridian')];
        if isempty(h)
            h = findobj(children,'Tag',object);
        end
        
    case 'map'
        % Error if ax is not a map axes
        gcm(ax);
        
        h = children;
        h = setdiff(h, [...
            findobj(h,'Tag','Frame'); ...
            findobj(h,'Tag','Parallel'); ...
            findobj(h,'Tag','Meridian')],'stable');
                
    case 'meridian'
        h = findobj(children,'Tag','Meridian');
        
    case 'mlabel'
        h = findobj(children,'Tag','MLabel');
        
    case 'parallel'
        h = findobj(children,'Tag','Parallel');
        
    case 'plabel'
        h = findobj(children,'Tag','PLabel');
        
    case 'tissot'
        h = findobj(children,'Tag','Tissot');
        
    case 'scaleruler'
        h = findall(children, 'Type', 'hggroup', ...
            '-regexp', 'Tag',  'scaleruler*');
        
    otherwise
        h = gobjects(0);
end

if isempty(h)
    h = gobjects(0);
end

%--------------------------------------------------------------------------

function h = findTagMatch(tagstr,ax,method)

% Remove trailing blanks from tagstr, unless tagstr contains nothing but blanks.

tag = deblank(tagstr);
if strlength(tag) == 0
    tag = tagstr;
end

%  Get the children of the current axes
children = get(ax,'Children');

if isempty(children)
    h = gobjects(0);
else
    switch method
       % If we reach this block, then children is non-empty.        
        case 'exact'
            h = findobj(children,'Tag',tag);
            
            % Exclude hggroup children when tag matches 'scaleruler*'.
            if ~isempty(h)
                tagMatchesScaleruler = strncmp('scaleruler',tag,length('scaleruler'));
                if tagMatchesScaleruler
                    hHGGroup = findobj(h,'Type','hggroup');
                    c = get(hHGGroup,'Children');
                    if iscell(c)
                        c = vertcat(c{:});
                    end
                    h = setdiff(h,c);
                end
            end
            
        case 'strmatch'
            tags = get(children,'Tag');
            h = children(startsWith(tags,tag));
            
        case 'findstr'
            tags = get(children,'Tag');
            h = children(contains(tags,tag));
    end
end

if isempty(h)
    h = gobjects(0);
end

%--------------------------------------------------------------------------

function tags = promptWithTags(ax)
%  promptWithTags produces a modal dialog box allowing selection from the
%  object tags of children of the axes AX.

children = get(ax,'Children');
if isempty(children)
    uiwait(errordlg('No objects on axes','Object Specification','modal'));
    tags = {};
else
    tags = get(children,'Tag');
    tags = convertStringsToChars(tags);
    if ischar(tags)
        tags = {tags};
    end
    tags(cellfun(@isempty,tags)) = [];
    if ~isempty(tags)
        tags = unique(tags, 'stable');
        index = listdlg('ListString',tags,...
            'SelectionMode','multiple',...
            'ListSize',[160 170],...
            'Name','Select Object');
        
        tags = tags(index);
    end
end

%--------------------------------------------------------------------------

function hndl = findContourHandle(children)
% Find contour hggroup handles.

hndl = findobj(children, 'Type', 'hggroup');
if ~isempty(hndl)
    tf = false(size(hndl));
    for k=1:numel(tf)
        h = hndl(k);
        if isappdata(h,'mapgraph')
            obj = getappdata(h, 'mapgraph');
            if ~isempty(findprop(obj, 'Fill'))
                tf(k) = true;
            end
        end
    end
    hndl = hndl(tf);
end

%--------------------------------------------------------------------------

function hndl = findFillContourHandle(children)
% Find filled contour hggroup handles.

hndl = findContourHandle(children);
tf = false(size(hndl));
for k=1:numel(tf)
    h = hndl(k);
    obj = getappdata(h, 'mapgraph');
    if isequal(obj.Fill, 'on')
        tf(k) = true;
    end
end
hndl = hndl(tf);

function h = mappolygon(x, y, varargin)
%MAPPOLYGON Display polygon in projected map coordinate system
%
%   map.graphics.internal.MAPPOLYGON(X, Y, Name, Value) constructs a patch
%   and an "edge line", in order to display a polygon in map (x-y)
%   coordinates.  The polygon is drawn in the Z == 0 plane.
%
%   map.graphics.internal.MAPPOLYGON(X, Y, Z, Name, Value) displays the
%   polygon in the horizontal plane indicated by the scalar Z.
%
%   H = map.graphics.internal.MAPPOLYGON(___) returns a handle to a patch
%   object, that may be used to reset various properties (or empty, if X
%   and Y are empty).
%
%   Inputs
%   ------
%   X and Y contain the polygon vertices, and may include NaN values to
%   delimit multiple parts, including inner rings.  X and Y must match in
%   size and the locations of NaN delimiters.
%
%   Z is a scalar defining the horizontal plane in which to display the
%   polygon.
%
%   Name and Value indicate optional name-value pairs, corresponding to
%   graphics properties of patch.  An optional 'EdgeLine' parameter may
%   also be specified, with a scalar logical value.  If true (the default),
%   an "edge line" object is created and used to display the polygon edges.
%   If false, the edge line is omitted and the polygon edges are not
%   shown. 
%
%   Another optional parameter, 'FaceVertexForm', controls the the way in
%   which patch is used to display multipart polygons (including polygons
%   with "holes"). When its value is true, each multipart polygon is
%   represented as a single patch in face-vertex form, with an auxiliary
%   line object used to show the external edges.
%
%   When FaceVertexForm is false, or omitted, a "multipatch" approach is
%   used. Each multipart polygon is cut vertically until only a set set of
%   simple closed curves remains. A separate patch is constructed for each
%   curve, using vertex-list form. The edges of these patches are not
%   displayed. One additional patch is constructed, also. It also uses
%   vertex-list form, but there are NaN-delimiters in its XData and YData
%   and only its edges are shown.
%
%   FaceVertexForm is false by default.
%
%   If the EdgeAlpha, EdgeColor, LineWidth, or LineStyle properties (or any
%   marker properties) are set during construction, or via set(h,...),
%   their values may be applied to an "edge line" object, not the patch
%   itself.
%
%   Example
%   -------
%   load coastlines
%   [y, x] = maptrimp(coastlat, coastlon, [-90 90], [-180 180]);
%   figure('Color','white')
%   h = map.graphics.internal.mappolygon(x,y,'FaceColor',[0.7 0.7 0.4]);
%   axis equal; axis off
%   set(h,'FaceAlpha',0.5)
%   get(h)
%
%   See also map.graphics.internal.GLOBEPOLYGON

% Copyright 2012-2017 The MathWorks, Inc.

defaultFaceColor = [1 1 0.5];   % Pale yellow

% Extract Z from the input, if provided. Otherwise set Z to [] and omit
% ZData when constructing graphics objects.
if numel(varargin) >= 1 && ~ischar(varargin{1})
    z = varargin{1};
    varargin(1) = [];
else
    z = [];
end

internal.map.checkNameValuePairs(varargin{:})

% Separate out any 'Parent' properties from varargin
qParent = strncmpi(varargin,'pa',2);
qParent = qParent | circshift(qParent,[0 1]);
parents = varargin(qParent);
varargin(qParent) = [];

% Check the 'EdgeLine' flag, which is true by default.
[edgeLine, varargin] = map.internal.findNameValuePair('EdgeLine',true,varargin{:});

% Use false for the default value of FaceVertexForm.
[faceVertexForm, varargin] ...
    = map.internal.findNameValuePair('FaceVertexForm', false, varargin{:});

if ~isempty(x) || ~isempty(y)
    if any(~isnan(x(:))) || any(~isnan(y(:)))
        % The polygon has at least one part.
        
        % Clean up data, making sure that the edge-line closes.
        [x, y] = closePolygonParts(x, y);
        
        if isShapeMultipart(x,y)
            % The polygon has multiple parts.
            if faceVertexForm
                hPatch = faceVertexPolygon( ...
                    x, y, z, defaultFaceColor, edgeLine, parents);
            else
                hPatch = multiPatchPolygon( ...
                    x, y, z, defaultFaceColor, edgeLine, parents);
            end
        else
            % The polygon has only one part. Construct a single patch,
            % using the vertices provided, taking care not to include any
            % NaNs in the vertex list.
            n = isnan(x);
            x(n) = [];
            y(n) = [];
            if isempty(z)
                hPatch = patch('XData', x,'YData', y, ...
                    parents{:}, 'FaceColor', defaultFaceColor);
            else
                hPatch = patch('XData', x,'YData', y, ...
                    'ZData', z + zeros(size(x)), ...
                    parents{:}, 'FaceColor', defaultFaceColor);
            end
        end
    else
        % Construct a patch with no data when X and Y contain only NaN.
        hPatch = patch('XData', NaN, 'YData', NaN, 'ZData', NaN, ...
            parents{:}, 'FaceColor', defaultFaceColor);
    end
    
    % Apply user-supplied properties, if any, and make patch visible.
    set(hPatch,'Visible','on',varargin{:})
else
    % Return empty when X and Y are both empty.
    hPatch = reshape(gobjects(0),[0 1]);
end

% Suppress output if called with no return value and no semicolon.
if nargout > 0
    h = hPatch;
end

end

%--------------------------------------------------------------------------

function hPatch = faceVertexPolygon(x, y, z, faceColor, edgeLine, parents)
% Use face-vertex form to construct a "fill patch" in which the edges are
% turned off.  Construct an edge line if the edgeLine flag is true.

[f,v] = map.internal.polygonToFaceVertex(x,y);
if ~isempty(z)
    v = [v, z + zeros(size(v,1),1)];
end
hPatch = patch('Faces', f, 'Vertices', v, parents{:}, ...
    'FaceColor', adjustWhite(faceColor), ...
    'EdgeColor','none', 'Visible','off');

if edgeLine
    % Construct an "edge line," with HandleVisibility off.
    if isempty(z)
        map.graphics.internal.constructEdgeLine(hPatch, x, y);
    else
        map.graphics.internal.constructEdgeLine( ...
            hPatch, x, y, z + zeros(size(x)));
    end   
end
end

%--------------------------------------------------------------------------

function hPatch = multiPatchPolygon(x, y, z, faceColor, edgeLine, parents)
% Use vertex-list (XData, YData) form to construct multiple patch that fill
% the area occupied by a polygon.  Construct an "edge patch" to display the
% polygon edges if edgeLine is true.  Otherwise, construct it anyway, but
% make it a "null patch," without the actual vertices.

% Ensure terminating NaNs, to avoid an edge that connects the
% first and last vertices.
if ~isnan(x(end))
    x(end+1) = NaN;
    y(end+1) = NaN;
end

% Construct two or more "fill patches" as needed to fill in the
% interior of the polygon, gathered together in an hggroup.
% Set EdgeColor last, to ensure that it is 'none'.
% Handle visibility is off for both group and patches.
p = polygonToSimpleCurves(x(:), y(:));
hFillPatchGroup = hggroup(parents{:}, ...
    'Visible','off','HandleVisibility','off');
for k = 1:numel(p)
    for r = 1:p(k).NumRegions
        [xdata, ydata] = boundary(p(k), r);
        if isempty(z)
            patch('Parent',hFillPatchGroup,'XData',xdata,'YData',ydata)
        else
            patch('Parent',hFillPatchGroup,...
                'XData',xdata,'YData',ydata,'ZData',z + zeros(size(xdata)))
        end
    end
end
set(allchild(hFillPatchGroup),'FaceColor',adjustWhite(faceColor), ...
    'EdgeColor','none','HandleVisibility','off');

% Construct an "edge patch" object in which only the edges are visible.
% This is the object whose handle will be visible, and which will be
% returned if requested. If edgeLine is false, then this object should not
% display anything -- and need not contain any actual coordinates, in fact,
% but still needs to be constructed, in order to provide the "master"
% handle that is returned.
if edgeLine
    if isempty(z)
        hPatch = patch('XData',x,'YData',y,parents{:},'FaceColor',faceColor);
    else
        hPatch = patch('XData',x,'YData',y,'ZData',z + zeros(size(x)), ...
            parents{:},'FaceColor',faceColor);
    end
else
    hPatch = patch('XData', NaN, 'YData', NaN, 'ZData', NaN, parents{:});
end

% Provide access to the fill patch group.
setappdata(hPatch, 'FillPatchGroup', hFillPatchGroup)

% Set DeleteFcn and CreateFcn callbacks.
set(hPatch, 'DeleteFcn', @deleteFillPatchGroup)
set(hPatch, 'CreateFcn', @copyFillPatchGroup)

% Set up listeners such that the fill patch group responds to
% set(h,'FaceColor',...) and set(h,'FaceAlpha',...), and to
% ensure that it gets deleted appropriately.
addListeners(hPatch, hFillPatchGroup)

% Make the fill patches visible.
set(hFillPatchGroup,'Visible','on')

end

%--------------------------------------------------------------------------

function deleteFillPatchGroup(hPatch, ~)
% Delete the fill patch.
% if ishghandle(hFillPatchGroup)
%     delete(hFillPatchGroup);
% end

if ishghandle(hPatch, 'patch') && isappdata(hPatch, 'FillPatchGroup')
    hFillPatchGroup = getappdata(hPatch, 'FillPatchGroup');
    if ishghandle(hFillPatchGroup, 'hggroup') ...
            && isequal(ancestor(hFillPatchGroup, 'axes'), ancestor(hPatch,'axes'))
        delete(hFillPatchGroup)
        rmappdata(hPatch, 'FillPatchGroup')
    end
end
end
    
%--------------------------------------------------------------------------

function copyFillPatchGroup(hPatch, ~)
% If the hgroup in the hPatch appdata is in a different axes than hPatch,
% copy it into the axes ancestor of hPatch and set the appdata and
% listeners. These actions will be performed when copyobj is called but not
% when openfig is called.

if ishghandle(hPatch, 'patch') && isappdata(hPatch, 'FillPatchGroup')
    hFillPatchGroup = getappdata(hPatch, 'FillPatchGroup');
    if ishghandle(hFillPatchGroup, 'hggroup')
        ax = ancestor(hPatch, 'axes');
        if ~isequal(ax, ancestor(hFillPatchGroup, 'axes'))
            hCopy = copyobj(hFillPatchGroup, ax);
            setappdata(hPatch, 'FillPatchGroup', hCopy);
            addListeners(hPatch, hCopy)
            uistack(hCopy, 'down')
        end
    end
end
end

%--------------------------------------------------------------------------

function addListeners(hPatch, hFillPatchGroup)

% Set up listeners that transfer face property settings from edge patch
% to the fill patches.
addlistener(hPatch,'FaceColor','PostSet',@setFillProps);
addlistener(hPatch,'FaceAlpha','PostSet',@setFillProps);
addlistener(hPatch,'Visible',  'PostSet',@setFillProps);
addlistener(hPatch,'CData',    'PostSet',@setFillProps);
addlistener(hPatch,'EdgeColor','PostSet',@setEdgeColor);

% Keep some state information to help the listener callbacks work.
updateFillProps = true;
updateEdgeColor = true;
edgeColor = get(hPatch,'EdgeColor');

%------------------- nested callback functions ------------------

    function setFillProps(hSrc,evnt)
        % Apply FaceColor, FaceAlpha, Visible, and CData values to the fill
        % patches rather than to the edge patch. Use allchild because the
        % fill patches have hidden handles.
        if updateFillProps
            hEdgePatch = evnt.AffectedObject;
            name = hSrc.Name;
            value = get(hEdgePatch,name);
            if strcmp(name,'FaceColor')
                value = adjustWhite(value);
            end
            set(allchild(hFillPatchGroup), name, value)
            updateFillProps = false;
        end
        updateFillProps = true;
    end

    function setEdgeColor(~,evnt)
        % If EdgeColor is set to 'flat' or 'interp', quietly restore it to
        % its previous setting.
        if updateEdgeColor
            hEdgePatch = evnt.AffectedObject;
            value = get(hEdgePatch,'EdgeColor');
            if any(strcmpi(value,{'flat','interp'}))
                % Filter out values that match 'flat' or 'interp'.
                updateEdgeColor = false;
                set(hEdgePatch,'EdgeColor',edgeColor)
                updateEdgeColor = true;
            end
        end
        edgeColor = get(hPatch,'EdgeColor');
    end
end

%--------------------------------------------------------------------------

function color = adjustWhite(color)
    if isfloat(color)
        pureWhite = [1 1 1];
        nearlyWhite = 0.999 * pureWhite;
        if all(color > nearlyWhite)
            color = nearlyWhite;
        end
    end
end

%--------------------------------------------------------------------------

function p = polygonToSimpleCurves(x, y)
% Cut polygon (x,y) into simple closed curves, returning a polyshape vector
    [x, y] = removeExtraNanSeparators(x, y);
    ccw = ~ispolycw(x, y);
    if all(ccw)
        warning('map:polygons:noClockwiseParts', ...
            'Expected at least one polygon part to be clockwise.')
    end
    w = warning('off','MATLAB:polyshape:boundary3Points');
    c = onCleanup(@() warning(w));
    p = polyshape(x(:), y(:), 'Simplify', false);
    if p.NumHoles > 0
        p = polyshapeToSimplePolygons(p);
    else
        p = simplify(p);
    end
end

%--------------------------------------------------------------------------

function p = polyshapeToSimplePolygons(p)
% Cut polygon p into simple closed curves
%
%   Repeatedly cut a multipart polygon p on vertical lines until there are
%   no remaining holes -- only a collection of simple, closed curves. This
%   function is recursive. The recursion terminates when p has no holes.
%
%   To prevent invalid input from causing infinite recursion, it's verified
%   that the input polygon includes at least one hole.
%
%   Note: When this function is called from polygonToSimpleCurves, there's
%   always at least one hole and local functions cutOnVerticalLeft and
%   cutOnVerticalRight perform intersections. This means that the input
%   does not need to be "pre-simplified."

    h = ishole(p);
    if any(h)
        % At this point, there's at least one hole to be eliminated.

        % Choose the cut location, c, to be centered between the left-most
        % and right-most extremities of the first hole.
        k = find(h,1);
        [xHole, ~] = boundary(p,k);
        v = (min(xHole) + max(xHole))/2;

        % Make the cut.
        [pL] = cutOnVerticalLeft(p, v);
        [pR] = cutOnVerticalRight(p, v);

        % Recurse on both sides of the cut.
        pL = polyshapeToSimplePolygons(pL);
        pR = polyshapeToSimplePolygons(pR);

        % Combine results.
        p = [pL pR];
    end
end

%--------------------------------------------------------------------------

function p = cutOnVerticalLeft(p, v)
% Cut a polygon p along the vertical line x == v, keeping only the part to
% the left of the line.

    x = p.Vertices(:,1);
    y = p.Vertices(:,2);

    ymin = min(y);
    ymax = max(y);
    xmin = min(x);
    xb = [xmin xmin    v    v];
    yb = [ymin ymax ymax ymin];
    box = polyshape(xb, yb, 'Simplify', false, 'SolidBoundaryOrientation', 'cw');
    p = intersect(p, box);
end

%--------------------------------------------------------------------------

function p = cutOnVerticalRight(p, v)
% Cut polygon p along the vertical line x == v, keeping only the part to
% the right of the line.

    x = p.Vertices(:,1);
    y = p.Vertices(:,2);

    ymin = min(y);
    ymax = max(y);
    xmax = max(x);
    xb = [xmax xmax    v    v];
    yb = [ymax ymin ymin ymax];
    box = polyshape(xb, yb, 'Simplify', false, 'SolidBoundaryOrientation', 'cw');
    p = intersect(p, box);
end

%--------------------------------------------------------------------------

function setUpListenersAndCallbacks(~,~) %#ok<DEFNU>
% Allow figures from R2013b and earlier to be opened.
    function deleteFillPatch(hFillPatchGroup,~) %#ok<DEFNU>
        if ishghandle(hFillPatchGroup)
            delete(hFillPatchGroup);
        end
    end
end

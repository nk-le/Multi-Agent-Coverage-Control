function surfaceAdapterCallback(hSrc,~,eventType)
%SURFACEAPAPTERCALLBACK Callback function for SurfaceAdapter
%
%   surfaceAdapterCallback(hSrc, event, eventType) either deletes secondary
%   surfaces or copies secondary surfaces depending on the value of the
%   string eventType. If eventType is 'delete', secondary surfaces are
%   deleted. If eventType is 'create', secondary surfaces are copied. If
%   the 'mapgraph_handle' appdata is empty or eventType does not match
%   either 'delete' or 'create', then no action is preformed. hSrc is a
%   scalar surface handle or a vector of surface handles.
%
%   See also internal.mapgraph.SurfaceAdapter

% Copyright 2013-2014 The MathWorks, Inc.

appId = 'mapgraph_handle';
if ~isempty(hSrc) && ishghandle(hSrc, 'surface') && isappdata(hSrc, appId)
    % Obtain mapgraph handle or handles.
    % If h is not empty, it contains one or more handles from the app data
    % denoted by appId and references the original surface or surfaces.
    % hSrc is the primary copied surface handle.
    h = getappdata(hSrc, appId);
    
    if ~isempty(h)
        % hSrc contains the appdata. Either delete the secondary surface
        % or copy the secondary surface.
        if strcmp(eventType, 'delete')
            % Delete secondary surface(s).
            deleteSecondarySurfaces(h, hSrc);
            
        elseif strcmp(eventType, 'create')
            % Copy secondary surface(s).
            copySecondarySurfaces(h, hSrc);
        end
    end
end

%--------------------------------------------------------------------------

function deleteSecondarySurfaces(h, hSrc)
% Delete the secondary surface(s) from h only when the primary surface
% handle is being deleted.

if numel(h) > 1
    % A secondary surface is found. Delete it only if either h(1) or hSrc
    % is being deleted. This is determined by the BeingDeleted property.
    if all(ishghandle(h, 'surface')) ...
            && (strcmp(get(h(1), 'BeingDeleted'), 'on') ...
            ||  strcmp(get(hSrc, 'BeingDeleted'), 'on'))
       
        % Delete secondary surfaces, but not the primary one.
        for k = 2:length(h)
            delete(h(k))
        end
    end
end

%--------------------------------------------------------------------------

function copySecondarySurfaces(h, hSrc)
% Copy the secondary surface(s) to the parent of hSrc when copyobj is being
% used to copy the primary surface to a new ancestor. When the function is
% called from openfig, all the surfaces are already copied. In this case,
% do not copy the secondary surface or surfaces.

if numel(h) > 1
    % A secondary surface is found in h. Determine whether to copy the
    % secondary surface to the parent of hSrc.
    if isappdata(hSrc, 'mapgraph_handle')
        % needToCopy is true when this function is called by copyobj.
        mapgraphHandles = getappdata(hSrc, 'mapgraph_handle');
        needToCopy = mapgraphHandlesInFigure(hSrc, mapgraphHandles);
        
        if needToCopy
            ax = get(hSrc, 'Parent');
            if all(ishghandle(h, 'surface')) && ishghandle(ax, 'axes')
                % Copy secondary surface(s), but not the primary one.
                for k = 2:length(h)
                    hSecondaryCopies(k - 1) = copyobj(h(k), ax); %#ok<AGROW>
                end
                                
                % Set the hSrc appdata to allow the deletion of the primary
                % surface to also delete the secondary surfaces.
                mapgraph_handles = [hSrc, hSecondaryCopies];
                setappdata(hSrc, 'mapgraph_handle', mapgraph_handles);
            end
            
            % Remove mapgraph appdata from primary handle. setm will not
            % function properly on the copied objects.
            if isappdata(hSrc, 'mapgraph')
                rmappdata(hSrc, 'mapgraph')
            end
        end
    end
end

%--------------------------------------------------------------------------

function needToCopy = mapgraphHandlesInFigure(hSrc, mapgraphHandles)
% Determine whether any mapgraph handles are already contained in the 
% ancestor of hSrc. If so, then there is no need to copy any handles.

sourceAncestor = ancestor(hSrc(1), 'figure');
tf = false(1, length(mapgraphHandles));
for k = 1:length(mapgraphHandles)
    mapgraphAncestor = ancestor(mapgraphHandles(k), 'figure');
    if isequal(mapgraphAncestor, sourceAncestor)
        tf(k) = true;
    end
end

% If tf is all true, then the mapgraphHandles are already contained in the
% ancestor of hSrc. In that case, there is no need to copy the handles.
needToCopy = ~all(tf);

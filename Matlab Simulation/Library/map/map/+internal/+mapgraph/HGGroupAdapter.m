%HGGroupAdapter Adapt hggroup class for use within map data objects
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the class
%       itself may be removed in a future release.

% Copyright 2009-2020 The MathWorks, Inc.

classdef HGGroupAdapter < matlab.mixin.SetGetExactNames
    
    properties (Dependent = true, SetAccess = private)
        % Annotation
        BeingDeleted
        Type
    end
        
    properties (Dependent = true)
        
        % Full list of hggroup properties; the ones that are commented
        % out are not to be accessed from within mapgraph classes. The
        % others (which are declared Dependent) can be accessed via set
        % and get methods.
    
        DisplayName
        HitTestArea
        ButtonDownFcn
        Children
        Clipping
        % CreateFcn
        % DeleteFcn
        % BusyAction
        HandleVisibility
        HitTest
        Interruptible
        Parent
        Selected
        SelectionHighlight
        Tag
        UIContextMenu
        UserData
        Visible
    end
    
    % properties (SetAccess = protected, Hidden = true)
    properties (Dependent, SetAccess = protected, Hidden = true)
        % Handle to an associated MATLAB hggroup object
        HGGroup
    end
    
    
    properties (Transient, SetAccess = private, Hidden = true)
        pHGGroup = [];
        ObjectIsLoaded = false;
    end
    
    
    methods
        
        function h = HGGroupAdapter(ax)
            if nargin > 0
                g = hggroup('Parent',ax);
                drawnow
                
                % Use appdata to establish a link back from the hggroup.
                setappdata(g,'mapgraph',h)
                
                % Cache the handle to the hggroup for use in get.HGGroup.
                h.pHGGroup = g;
            end
        end
       
        
        function setSpecgraphGroupProps(h, specgraphGroupProps)
            % Set most of the properties of h.HGGroup to match the
            % the structure array specgraphGroupProps, which contains
            % properties of an object derived from hggroup, such as a
            % scattergroup or contourgroup.
            
            g = h.HGGroup;
            
            % Identify fields in specgraphGroupProps that do _not_
            % correspond to the properties of an hggroup.
            extraSpecgraphGroupProps ...
                = setdiff(fields(specgraphGroupProps), fields(get(g)));
            
            % Avoid trying to set read-only properties ('Annotation',
            % 'BeingDeleted', and 'Type') and properties that affect
            % child-parent relationships.
            otherExceptions = { ...
                'Annotation'; ...
                'BeingDeleted'; ...
                'Children'; ...
                'Parent'; ...
                'Type'};
            
            hggroupProps = rmfield(specgraphGroupProps, ...
                [extraSpecgraphGroupProps; otherExceptions]);
            
            set(g,hggroupProps)            
        end
        
        function g = get.HGGroup(h)
            if isempty(h.pHGGroup)
                % Find the hggroup object that has the object with handle h
                % in its 'mapgraph' appdata.
                groups = findobj('Type','hggroup');
                for k = 1:numel(groups)
                    if isappdata(groups(k),'mapgraph')
                        if getappdata(groups(k),'mapgraph') == h
                            h.pHGGroup = groups(k);
                        end
                    end
                end
            end
            g = h.pHGGroup;
        end
        
        % Read-only: No set method
        % function v = get.Annotation(h)
        %     v = get(h.HGGroup,'Annotation');
        % end
        
        function v = get.DisplayName(h)
            v = get(h.HGGroup,'DisplayName');
        end
        
        function set.DisplayName(h,v)
            set(h.HGGroup,'DisplayName', v)
        end

        function v = get.HitTestArea(h)
            v = get(h.HGGroup,'HitTestArea');
        end
        
        function set.HitTestArea(h,v)
            set(h.HGGroup,'HitTestArea', v)
        end

        % Read-only: No set method
        function v = get.BeingDeleted(h)
            v = get(h.HGGroup,'BeingDeleted');
        end
        
        function v = get.ButtonDownFcn(h)
            v = get(h.HGGroup,'ButtonDownFcn');
        end
        
        function set.ButtonDownFcn(h,v)
            set(h.HGGroup,'ButtonDownFcn', v)
        end

        function v = get.Children(h)
            v = get(h.HGGroup,'Children');
        end
        
        function set.Children(h,v)
            set(h.HGGroup,'Children', v)
        end

        function v = get.Clipping(h)
            v = get(h.HGGroup,'Clipping');
        end
        
        function set.Clipping(h,v)
            set(h.HGGroup,'Clipping', v)
        end

        % function v = get.CreateFcn(h)
        %     v = get(h.HGGroup,'CreateFcn');
        % end
        
        % function set.CreateFcn(h,v)
        %     set(h.HGGroup,'CreateFcn', v)
        % end

        % function v = get.DeleteFcn(h)
        %     v = get(h.HGGroup,'DeleteFcn');
        % end
        
        % function set.DeleteFcn(h,v)
        %     set(h.HGGroup,'DeleteFcn', v)
        % end

        % function v = get.BusyAction(h)
        %     v = get(h.HGGroup,'BusyAction');
        % end
        
        % function set.BusyAction(h,v)
        %     set(h.HGGroup,'BusyAction', v)
        % end

        function v = get.HandleVisibility(h)
            v = get(h.HGGroup,'HandleVisibility');
        end
        
        function set.HandleVisibility(h,v)
            set(h.HGGroup,'HandleVisibility', v)
        end

        function v = get.HitTest(h)
            v = get(h.HGGroup,'HitTest');
        end
        
        function set.HitTest(h,v)
            set(h.HGGroup,'HitTest', v)
        end

        function v = get.Interruptible(h)
            v = get(h.HGGroup,'Interruptible');
        end
        
        function set.Interruptible(h,v)
            set(h.HGGroup,'Interruptible', v)
        end

        function v = get.Parent(h)
            v = get(h.HGGroup,'Parent');
        end
        
        function set.Parent(h,v)
            set(h.HGGroup,'Parent', v)
        end

        function v = get.Selected(h)
            v = get(h.HGGroup,'Selected');
        end
        
        function set.Selected(h,v)
            set(h.HGGroup,'Selected', v)
        end

        function v = get.SelectionHighlight(h)
            v = get(h.HGGroup,'SelectionHighlight');
        end
        
        function set.SelectionHighlight(h,v)
            set(h.HGGroup,'SelectionHighlight', v)
        end

        function v = get.Tag(h)
            v = get(h.HGGroup,'Tag');
        end
        
        function set.Tag(h,v)
            set(h.HGGroup,'Tag', v)
        end

        % Read-only: No set method
        function v = get.Type(h)
            v = get(h.HGGroup,'Type');
        end
         
        function v = get.UIContextMenu(h)
            v = get(h.HGGroup,'UIContextMenu');
        end
        
        function set.UIContextMenu(h,v)
            set(h.HGGroup,'UIContextMenu', v)
        end

        function v = get.UserData(h)
            v = get(h.HGGroup,'UserData');
        end
        
        function set.UserData(h,v)
            set(h.HGGroup,'UserData', v)
        end

        function v = get.Visible(h)
            v = get(h.HGGroup,'Visible');
        end
        
        function set.Visible(h,v)
            set(h.HGGroup,'Visible', v)
        end        
    end
    
    methods (Static = true)
        
        function obj = loadobj(obj)
        % Update properties when the object is loaded from a MAT-file or
        % from a FIG-file.
        
            % Update ObjectIsLoaded property to true.
            obj.ObjectIsLoaded = true;
            
            % Set the HGGroup property to [] since its Parent property is
            % no longer valid for this object.
            obj.pHGGroup = [];
        end
    end
    
    methods (Hidden = true)
        
        function updateMapGraphHandle(h, hggroupHandle)
        % Update the HGGroup property of H to hggroupHandle. Reproject the
        % data to make the object current. This method is only intended for
        % use after the object is loaded from a file.
            
            if h.ObjectIsLoaded
                h.pHGGroup = hggroupHandle;
                h.reproject();
                h.ObjectIsLoaded = false;
            end
        end
    end       
end

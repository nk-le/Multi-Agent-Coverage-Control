%Text Text class for Map Viewer

% Copyright 2012-2020 The MathWorks, Inc.

classdef Text < matlab.mixin.SetGetExactNames

    properties (SetAccess = private)
        % Handle to HG text object
        hText
    end
    
    methods
        function this = Text(varargin)
            
            % Construct an HG text object and keep track of its handle.
            this.hText = text(varargin{:});
            
            % Set back-pointer from the HG text object to this Text object.
            setappdata(this.hText,'AnnotationObject',this)
            
            % If its HG text object is deleted, also delete this Text object.
            set(this.hText, 'DeleteFcn', @deleteAnnotation)
        end
        
        
        function delete(this)
            if ishghandle(this.hText) && strcmp(get(this.hText, 'BeingDeleted'), 'on')
                delete(this.hText)
            end
        end
        
        
        function paste(this, xShift, yShift)
            
            position = [xShift yShift 0] + get(this.hText,'Position');
            set(this.hText, 'Position', position, 'Visible','on')
            
        end
        
        
        function newText = makeCopy(this)
            %makeCopy Copy this Text object
            %
            %   makeCopy constructs a new mapgraphics.Text object that is
            %   identical this one, and that contains a handle to a new HG
            %   text object which is identical to the original except that
            %   it is invisible and unselected. The return value is handle
            %   to the new HG text object.
            
            % Construct an invisible HG text object with nominal properties.
            parent = get(this.hText,'Parent');
            
            newText = text(...
                'Position', get(this.hText,'Position'),...
                'String',   get(this.hText,'String')',...
                'Parent',   parent,...
                'Selected', 'off',...
                'Visible',  'off');
                        
            % Assign the rest of the properties.
            readOnlyProperties = {'Annotation','BeingDeleted','Extent','Type'};
            props = rmfield(get(this.hText),...
                [readOnlyProperties {'Selected','Visible'}]);
            set(newText,props)
            
            % Construct a new default mapgraphics.Text object.
            hCopy = internal.mapview.graphicw.Text;
            
            % Remove nominal text object.
            defaultText = hCopy.hText;
            set(defaultText,'DeleteFcn',[])
            delete(defaultText)
            
            % Assign hText to it.
            hCopy.hText = newText;
            
            % Set back-pointer from HG text object to mapgraphics.Text object.
            setappdata(hCopy.hText,'AnnotationObject',hCopy)
            
            % If its HG text object is deleted, also delete this Text object.
            set(hCopy.hText, 'DeleteFcn', @deleteAnnotation)
            
            
            % Why not just:
            
%             hCopy = internal.mapview.graphics.Text(
%                 'Position', get(this.hText,'Position'),...
%                 'String',   get(this.hText,'String')',...
%                 'Parent',   get(this.hText,'Parent'),...
%                 'Selected', 'off',...
%                 'Visible',  'off');
%             
%             % Assign the rest of the properties.
%             readOnlyProperties = {'Annotation','BeingDeleted','Extent','Type'};
%             props = rmfield(get(this.hText),...
%                 [readOnlyProperties {'Selected','Visible'}]);
%             set(hCopy.hText,props)
        end
        
        
        function hText = cut(this)
            %CUT Cut this Text object
            
            hText = this.hText;
            set(hText,'Selected','off','Visible','off')
        end
    end
end

%--------------------------------------------------------------------------

function deleteAnnotation(hSrc, ~)

hAnnotation = getappdata(hSrc, 'AnnotationObject');
if isvalid(hAnnotation)
    delete(hAnnotation)
end
end

function render(this,layerName,legend,ax,visibility)
%RENDER Render the point component.
%
%   RENDER(LAYERNAME,LEGEND,AX,VISIBILITY) renders all features 
%   of the point component into the axes AX using the symbolization 
%   defined in the legend, LEGEND. The point visibility is defined by 
%   VISIBILITY. 

% Copyright 1996-2008 The MathWorks, Inc.

features = this.Features;
for k = 1:numel(features)
    % Vertex arrays.
    xdata = features(k).xdata;
    ydata = features(k).ydata;
    
    % Graphics properties from symbolization rules.
    properties = legend.getGraphicsProperties(features(k));
    
    % Insert default point properties, if needed.
    if ~isfield(properties,'Marker')
        properties.Marker = 'x';
    end
    if ~isfield(properties,'LineStyle')
        properties.LineStyle = 'none';
    end
    
    % Construct the k-th point -- a line with scalar XData and YData.
    h = line( ...
        'Tag', layerName, ...
        'Parent', ax, ...
        'XData', xdata, ...
        'YData', ydata, ...
        'Visible', visibility, ...
        'HitTest', 'off', ...
        properties);
    
    % Store the Attributes structure in the appdata of the line.
    setappdata(h,'Attributes',features(k).Attributes)
end

function render(this,layerName,legend,ax,visibility)
%RENDER Render the line component.
%
%   RENDER(LAYERNAME, LEGEND, AX, VISIBILITY) renders all features 
%   of the line component into the axes AX using the symbolization 
%   defined in the legend, LEGEND, for the layer defined by LAYERNAME.
%   The line visibility is defined by VISIBILITY.

% Copyright 1996-2008 The MathWorks, Inc.

features = this.Features;
for k = 1:numel(features)
    % Vertex arrays.
    xdata = features(k).xdata;
    ydata = features(k).ydata;
    
    % Graphics properties from symbolization rules.
    properties = legend.getGraphicsProperties(features(k));
    
    % Construct the k-th line.
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

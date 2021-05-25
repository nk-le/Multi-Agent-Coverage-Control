function h = geoglobe(parent, varargin)
% geoglobe Create geographic globe
% 
%    gl = geoglobe(parent) creates a GeographicGlobe object in the
%    container specified by parent using default property values and
%    returns the object in gl. Use gl to modify properties of the
%    geographic globe after it is created. parent can be a Figure object
%    created using the uifigure function, or one of its child containers.
% 
%    gl = geoglobe(parent,Name,Value) specifies GeographicGlobe properties
%    using one or more Name,Value pair arguments.
%     
%    Execute get(gl), where gl is a GeographicGlobe object, to see a list
%    of GeographicGlobe properties and their current values. Execute
%    set(gl) to see a list of GeographicGlobe properties and legal property
%    values.
%
%    Example
%    -------
%    hfig = uifigure;
%    gl = geoglobe(hfig)
%
%    See also addCustomBasemap, addCustomTerrain, geobasemap, geoplot3,
%    removeCustomBasemap, removeCustomTerrain

% Copyright 2019 The MathWorks, Inc.

    try
        [status, msg] = builtin('license','checkout','MAP_Toolbox');
        if ~status
            error('map:license:NoMapLicense', msg);
        end

        gl = globe.graphics.GeographicGlobe('Parent', parent, varargin{:});
    catch e
        throwAsCaller(e)
    end
    
    % Prevent outputs when not assigning to variable.
    if nargout > 0
        h = gl;
    end
end

function varargout = geoplot3(gl, lat, lon, height, varargin)
%GEOPLOT3 Geographic globe plot
%
%   GEOPLOT3(gl,lat,lon,height) plots a 3-D line in a geographic globe
%   specified by gl with vertices at the latitude-longitude-height
%   locations specified by the vectors lat, lon, and height, where lat,
%   lon, and height are the same size. lat and lon are in specified in
%   degrees. height is specified in meters and is the height above the
%   terrain. height can be specified as a scalar to indicate a constant
%   height or as an empty to indicate ground-level height.
%  
%   GEOPLOT3(gl,lat,lon,height,LineSpec) uses a LineSpec to specify the
%   line style, marker symbol, and color for the line. By default, GEOPLOT3
%   draws a solid line, with no markers, using colors specified by the
%   geoglobe ColorOrder property.
%  
%   GEOPLOT3(___,Name,Value) specifies line properties using one or more
%   Name,Value pair arguments.
% 
%   GEOPLOT3(___,'HeightReference',heightReferenceValue, __) specifies the
%   height reference for the height values.  Permissible values are:
%   'terrain'   height values are relative to the terrain (default)
%   'geoid'     height values are relative to geoid (approximate mean sea level)
%   'ellipsoid' height values are relative to WGS84 ellipsoid
% 
%   H = GEOPLOT3(___) returns a scalar map.graphics.primitive.Line object. Use
%   H to modify the properties of the object after it is created.
% 
%   The vertices can be NaN-delimited to indicate line segments.
% 
%   A Line object created by GEOPLOT3 can be re-parented to a different
%   geographic globe but can not be re-parented to a geographic axes or
%   regular axes.
%
%   Example
%   -------
%   trk = gpxread('sample_mixed','FeatureType','track');
%   lat = trk.Latitude;
%   lon = trk.Longitude;
%   height = trk.Elevation;
%   fig = uifigure;
%   gl = geoglobe(fig);
%   h = geoplot3(gl,lat,lon,height,'c')
%
%   See also addCustomBasemap, addCustomTerrain, geobasemap, geoglobe,
%   removeCustomBasemap, removeCustomTerrain

% Copyright 2019 The MathWorks, Inc.

    narginchk(4, inf)
    v = map.graphics.internal.globe.GeographicGlobeDataValidator("variables");
    args = varargin;
    
    try
        validateattributes(gl, {'globe.graphics.GeographicGlobe'}, ...
            {'scalar'}, mfilename, 'gl')
        validateLatitude(v, lat);
        validateLongitude(v, lon);
        validateHeight(v, height);
        validateSizeConsistency(v, lat, lon, height);
        
        if isempty(lat)
            % lat, lon, and height are empty.
            h = map.graphics.primitive.Line.empty(0,1);
        else
            if rem(length(args),2) ~= 0
                args = parseLineSpec(args);
            end
            
            newplot(gl)
            h = map.graphics.primitive.Line( ...
                'Parent', gl, ...
                'LatitudeData', lat, ...
                'LongitudeData', lon, ...
                'HeightData', height, ...
                args{:});
            assignSeriesIndex(h)
        end
    catch e
        throwAsCaller(e)
    end
    
    if nargout > 0
        varargout{1} = h;
    end
end


function outargs = parseLineSpec(args)
    outargs = args;
    if ~isempty(args)
        lineSpec = args{1};
        if matlab.graphics.internal.isLineSpec(lineSpec)
            [l, c, m] = colstyle(lineSpec, 'plot');
            outargs(1) = [];
            
            if ~isempty(l)
                outargs = [{'LineStyle',l} outargs];
            end
            
            if ~isempty(c)
                outargs = [{'Color',c} outargs];
            end
            
            if ~isempty(m)
                outargs = [{'Marker',m} outargs];
            end
        end
    end

    % outargs must be name-value pairs
    if rem(length(outargs),2) ~= 0
        msg = message('MATLAB:plot:ArgNameValueMismatch');
        e = MException('map:graphics:globe:ArgNameValueMismatch',msg);
        throwAsCaller(e)
    end    
end

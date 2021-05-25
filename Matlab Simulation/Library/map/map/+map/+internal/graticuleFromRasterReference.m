function [lat, lon] = graticuleFromRasterReference(R, gratsize)
%Construct latitude-longitude graticule from raster reference object
%
%   [LAT, LON] = graticule(R, GRATSIZE) constructs a latitude-longitude
%   graticule mesh for a regular data grid with geographic raster reference
%   R. In typical usage, a latitude-longitude graticule is projected, and
%   the grid is warped to the graticule using MATLAB graphics functions.
%   GRATSIZE is a two-element vector of the form:
%
%             [number_of_parallels number_of_meridians].
%
%   If GRATSIZE = [], then the graticule returned has the default size
%   50-by-100.  A finer graticule uses larger arrays and takes more memory
%   and time but produces a higher fidelity display.

% Copyright 2020 The MathWorks, Inc.

    if isempty(gratsize)
       % If gratsize is empty, use the Mapping Toolbox default graticule size.
        gratsize = [50 100];
    end
    
    % Use epsilon to eliminate edge collisions (e.g., 0 and 360 degrees).
    epsilon = 1.0E-10;
    
    latlim = R.LatitudeLimits  + epsilon * [1 -1];
    lonlim = R.LongitudeLimits + epsilon * [1 -1];
    
    if columnsRunSouthToNorth(R)
        lat = linspace(latlim(1), latlim(2), gratsize(1));
    else
        lat = linspace(latlim(2), latlim(1), gratsize(1));
    end
    
    if rowsRunWestToEast(R)
        lon = linspace(lonlim(1), lonlim(2), gratsize(2));
    else
        lon = linspace(lonlim(2), lonlim(1), gratsize(2));
    end
    
    [lat, lon] = ndgrid(lat, lon);
end

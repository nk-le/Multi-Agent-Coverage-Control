function R = maprefcells(xWorldLimits, yWorldLimits, varargin)
%MAPREFCELLS Reference raster cells to map coordinates
%
%   R = MAPREFCELLS() returns a default referencing object for a regular
%   raster of cells in planar (map) coordinates.
%
%   R = MAPREFCELLS(xlimits,ylimits,rasterSize) constructs a referencing
%   object for a raster of cells spanning the specified limits in planar
%   world coordinates, with the numbers of rows and columns specified by
%   rasterSize.
%
%   R = MAPREFCELLS(xlimits,ylimits,xcellextent,ycellextent) allows the
%   cell extents in world X and Y to be set precisely. The limits of the
%   raster will be adjusted slightly, if necessary, to ensure an integer
%   number of cells in each dimension.
%
%   R = MAPREFCELLS(xlimits,ylimits,___,Name,Value) allows the
%   directions of the columns and rows to be specified via name-value
%   pairs. Use either 'ColumnsStartFrom','south' (the default) or
%   'ColumnsStartFrom','north' to control the column direction. Likewise,
%   use 'RowsStartFrom','west' (the default) or 'RowsStartFrom','east' to
%   control the row direction.
%
%   To construct a map raster reference object from a world file matrix,
%   use the maprasterref function.
%
%   Example
%   -------
%   % Construct a referencing object for an 1000-by-2000 image with
%   % square, 1/2 meter pixels referenced to a planar map coordinate
%   % system (the "world" system). The X-limits in the world system are
%   % 207000 and 208000. The Y-limits are 912500 and 913000. The image
%   % follows the popular convention in which world X increases from
%   % column to column and world Y decreases from row to row.
%   xlimits = [207000 208000];
%   ylimits = [912500 913000];
%   rasterSize = [1000 2000]
%   extent = 1/2;
%
%   % Specify raster size.
%   R = maprefcells(xlimits,ylimits,rasterSize,'ColumnsStartFrom','north')
%
%   % Obtain the same result by specifying pixel extents.
%   R = maprefcells(xlimits,ylimits,extent,extent,'ColumnsStartFrom','north')
%
%   See also MAPREFPOSTINGS, GEOREFCELLS, map.rasterref.MapCellsReference

% Copyright 2015-2019 The MathWorks, Inc.

    R = map.rasterref.MapCellsReference();
    if nargin > 0
        narginchk(3,8)
        R.XWorldLimits = validateWorldLimits(xWorldLimits(:)', 'xWorldLimits');
        R.YWorldLimits = validateWorldLimits(yWorldLimits(:)', 'yWorldLimits');
        
        switch nargin
            case {3,5,7}
                R.RasterSize = varargin{1};
                if nargin > 3
                    R = parseRasterDirection(R, varargin{2:end});
                end

            case {4,6,8}
                cellExtentInWorldX = varargin{1};
                cellExtentInWorldY = varargin{2};
                
                validateattributes(cellExtentInWorldX, {'double'}, ...
                    {'real','scalar','finite','positive'}, '', 'cellExtentInWorldX')

                validateattributes(cellExtentInWorldY, {'double'}, ...
                    {'real','scalar','finite','positive'}, '', 'cellExtentInWorldY')

                R.CellExtentInWorldX = cellExtentInWorldX;
                R.CellExtentInWorldY = cellExtentInWorldY;
                if nargin > 4
                    R = parseRasterDirection(R, varargin{3:end});
                end
        end
    end
end


function lim = validateWorldLimits(lim, varname)
    validateattributes(lim, {'double'}, ...
        {'real','row','finite','size', [1 2]}, '', varname)

    map.internal.assert(lim(1) < lim(2), ...
        'map:spatialref:expectedAscendingLimits', varname)
end

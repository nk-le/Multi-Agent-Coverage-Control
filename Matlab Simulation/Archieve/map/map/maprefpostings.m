function R = maprefpostings(xWorldLimits, yWorldLimits, varargin)
%MAPREFPOSTINGS Reference raster postings to map coordinates
%
%   R = MAPREFPOSTINGS() returns a default referencing object for a raster
%   of regularly posted samples in planar (map) coordinates.
%
%   R = MAPREFPOSTINGS(xlimits,ylimits,rasterSize) constructs a referencing
%   object for a raster spanning the specified limits in planar world
%   coordinates, with the numbers of rows and columns specified by
%   rasterSize.
%
%   R = MAPREFPOSTINGS(xlimits,ylimits,xspacing,yspacing) allows the sample
%   spacings in world X and Y to be set precisely. The limits of the raster
%   will be adjusted slightly, if necessary, to ensure an integer number of
%   samples in each dimension.
%
%   R = MAPREFPOSTINGS(xlimits,ylimits,___,Name,Value) allows the
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
%   % Construct a referencing object for an 1001-by-2001 grid with
%   % postings separated by 1/2 meter, referenced to a planar map
%   % coordinate system (the "world" system). The X-limits in the world
%   % system are 207000 and 208000. The Y-limits are 912500 and 913000.
%   xlimits = [207000 208000];
%   ylimits = [912500 913000];
%   rasterSize = [1001 2001]
%   spacing = 1/2;
%
%   % Specify raster size.
%   R = maprefpostings(xlimits,ylimits,rasterSize)
%
%   % Obtain the same result by specifying sample spacings.
%   R = maprefpostings(xlimits,ylimits,spacing,spacing)
%
%   See also MAPREFCELLS, GEOREFPOSTINGS, map.rasterref.MapPostingsReference

% Copyright 2015-2019 The MathWorks, Inc.

    R = map.rasterref.MapPostingsReference();
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
                sampleSpacingInWorldX = varargin{1};
                sampleSpacingInWorldY = varargin{2};
                
                validateattributes(sampleSpacingInWorldX, {'double'}, ...
                    {'real','scalar','finite','positive'}, '', 'sampleSpacingInWorldX')

                validateattributes(sampleSpacingInWorldY, {'double'}, ...
                    {'real','scalar','finite','positive'}, '', 'sampleSpacingInWorldY')

                R.SampleSpacingInWorldX = sampleSpacingInWorldX;
                R.SampleSpacingInWorldY = sampleSpacingInWorldY;
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

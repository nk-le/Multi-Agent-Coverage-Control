classdef (Hidden) MapRasterReference ...
    < map.rasterref.internal.MapRasterReferenceAlias
%MapRasterReference (abstract) Reference raster to map coordinates

% Most of the content of this file was copied from the file
% map/+spatialref/MapRasterReference.m, which was introduced in R2011a.

% Copyright 2010-2020 The MathWorks, Inc.
    
    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent = true)
        %XWorldLimits - Limits of raster in world X [xMin xMax]
        %
        %    XWorldLimits is a two-element row vector.
        XWorldLimits
        
        %YWorldLimits - Limits of raster in world Y [yMin yMax]
        %
        %    YWorldLimits is a two-element row vector.
        YWorldLimits
        
        %RasterSize Number of cells or samples in each spatial dimension
        %
        %   RasterSize is a two-element vector [M N] specifying the
        %   number of rows (M) and columns (N) of the raster or image
        %   associated with the referencing object. In addition, for
        %   convenience, you may assign a size vector having more than
        %   two elements to RasterSize. This flexibility enables
        %   assignments like R.RasterSize = size(RGB), for example, where
        %   RGB is M-by-N-by-3. However, in such cases, only the first two
        %   elements of the size vector will actually be stored. The higher
        %   (non-spatial) dimensions will be ignored. M and N must be
        %   positive in all cases and must be 2 or greater when
        %   RasterInterpretation is 'postings'.
        RasterSize
        
        %ColumnsStartFrom Edge from which column indexing starts
        %
        %   ColumnsStartFrom is a string that equals 'south' or 'north'.
        ColumnsStartFrom
        
        %RowsStartFrom Edge from which row indexing starts
        %
        %   RowsStartFrom is a string that equals 'west' or 'east'.
        RowsStartFrom
    end

    properties (Dependent = true, SetAccess = private)
        %RasterExtentInWorldX - Full extent in along-row direction
        %
        %   RasterExtentInWorldX is the extent of the full raster
        %   or image as measured in the world system in a direction
        %   parallel to its rows. In the case of a rectilinear geometry,
        %   which is most typical, this is the horizontal direction
        %   (east-west).
        RasterExtentInWorldX
        
        %RasterExtentInWorldY - Full extent in along-column direction
        %
        %   RasterExtentInWorldY is the extent of the full raster
        %   or image as measured in the world system in a direction
        %   parallel to its columns. In the case of a rectilinear
        %   geometry, which is most typical, this is the vertical
        %   direction (north-south).
        RasterExtentInWorldY
    end
    
    properties (Abstract, SetAccess = protected, Transient = true)
        XIntrinsicLimits;  % Limits of raster in intrinsic X [xMin xMax]
        YIntrinsicLimits;  % Limits of raster in intrinsic Y [yMin yMax]
    end

    properties (Dependent = true, SetAccess = private)
        %TransformationType - Transformation type: 'rectilinear' or 'affine'
        %
        %   TransformationType is a string describing the type of geometric
        %   relationship between the intrinsic coordinate system and the
        %   world coordinate system. Its value is 'rectilinear' when world
        %   X depends only on intrinsic X and vice versa, and world Y
        %   depends only on intrinsic Y and vice versa. When the value is
        %   'rectilinear', the image will display without rotation
        %   (although it may be flipped) in the world system. Otherwise the
        %   value is 'affine'.
        TransformationType
    end
    
    properties (Constant = true)
        %CoordinateSystemType - Type of external system (constant: 'planar')
        %
        %   CoordinateSystemType describes the type of coordinate system
        %   to which the image or raster is referenced. It is a constant
        %   string with value 'planar'.
        CoordinateSystemType = 'planar';
    end
    
    properties (Dependent)
        % ProjectedCRS - A projcrs representing the coordinate reference
        % system
        ProjectedCRS
    end
    
    properties (Access = protected)
        % pProjectedCRS - A place to hold the value of the public
        % ProjectedCRS property.
        pProjectedCRS
    end
    
    %---------------------- Properties: Protected ------------------------
    
    properties (Constant, Abstract, Access = protected)
        % Number of columns or rows ("elements") minus number of intervals
        % of width abs(DeltaX) or abs(DeltaY). Equals either 0 or 1.
        ElementsMinusIntervals
    end

    %----------------- Properties: Protected + hidden --------------------

    properties (Access = protected, Hidden)
        % The world limits, column/row direction, delta, raster size, and
        % transformation type properties, along with all the methods except
        % for sizesMatch, depend on a hidden geometric transformation
        % object stored in the Transformation property. It is not
        % initialized, because until the subclass constructor runs, we
        % cannot tell if Transformation will hold an instance of a
        % map.rasterref.internal.RectilinearTransformation object or an
        % instance of a map.rasterref.internal.AffineTransformation
        % object.
        Transformation
    end
    
    properties (Abstract, Access = protected, Hidden)
        Intrinsic
    end
    
    %---------------- Constructor and ordinary methods --------------------
    
    methods
        function R = MapRasterReference(rasterSize)
            % Initialize intrinsic and transient properties.
            
            if nargin > 0
                % Update intrinsic properties on which RasterSize depends
                % and the transient properties that depend on them.
                try
                    R = setIntrinsicRasterSize(R, rasterSize);
                catch e
                    throwAsCaller(e)
                end
            else
                % Initialize transient properties.
                [xlimits, ylimits] = limits(R.Intrinsic);
                R.XIntrinsicLimits = xlimits;
                R.YIntrinsicLimits = ylimits;
            end
        end
        
        
        function tf = sizesMatch(R,A)
            %sizesMatch True if object and raster or image are size-compatible
            %
            %   TF = sizesMatch(R,A) returns true if the size of the raster
            %   (or image) A is consistent with the RasterSize property of
            %   the referencing object R. That is,
            %
            %           R.RasterSize == [size(A,1) size(A,2)].
            
            tf = sizesMatch(R.Intrinsic, A);
        end
        
        
        function [xw, yw] = intrinsicToWorld(R, xi, yi)
            %intrinsicToWorld Convert from intrinsic to world coordinates
            %
            %   [xWorld, yWorld] = intrinsicToWorld(R, ...
            %   xIntrinsic, yIntrinsic) maps point locations from the
            %   intrinsic system (xIntrinsic, yIntrinsic) to the world
            %   system (xWorld, yWorld) based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside limits of
            %   the raster (or image) in the intrinsic system. In this
            %   case world X and Y are extrapolated outside the bounds
            %   of the image in the world system.
            
            map.internal.validateCoordinatePairs(xi, yi, ...
                [class(R), '.intrinsicToWorld'], ...
                'xIntrinsic', 'yIntrinsic')
            
            [xw, yw] = R.Transformation.intrinsicToWorld(xi, yi);
        end
        
        
        function [xi, yi] = worldToIntrinsic(R, xw, yw)
            %worldToIntrinsic Convert from world to intrinsic coordinates
            %
            %   [xIntrinsic, yIntrinsic] = worldToIntrinsic(R, ...
            %   xWorld, yWorld) maps point locations from the
            %   world system (xWorld, yWorld) to the intrinsic
            %   system (xIntrinsic, yIntrinsic) based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside limits of
            %   the raster (or image) in the world system. In this
            %   case world X and Y are extrapolated outside the bounds
            %   of the image in the intrinsic system.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.worldToIntrinsic'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
        end
        
        
        function [row,col] = worldToDiscrete(R, xw, yw)
            %worldToDiscrete Transform map to discrete coordinates
            %
            %   [I,J] = worldToDiscrete(R, xWorld, yWorld) returns the
            %   subscript arrays I and J. When the referencing object R has
            %   RasterInterpretation 'cells', these are the row and column
            %   subscripts of the raster cells (or image pixels) containing
            %   each element of a set of points given their world
            %   coordinates (xWorld, yWorld).  If R.RasterInterpretation is
            %   'postings', then the subscripts refer to the nearest sample
            %   point (posting). xWorld and yWorld must have the same size.
            %   I and J will have the same size as xWorld and yWorld. For
            %   an M-by-N raster, 1 <= I <= M and 1 <= J <= N, except when
            %   a point xWorld(k), yWorld(k) falls outside the image, as
            %   defined by contains(R, xWorld, yWorld), then
            %   both I(k) and J(k) are NaN.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.worldToDiscrete'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
            [row, col] = R.Intrinsic.intrinsicToDiscrete(xi, yi);
        end
        
        
        function tf = contains(R, xw, yw)
            %contains True if raster contains points in world coordinate system
            %
            %   TF = contains(R, xWorld, yWorld) returns a logical array TF
            %   having the same size as xWorld, yWorld such that TF(k) is
            %   true if and only if the point (xWorld(k), yWorld(k)) falls
            %   within the bounds of the raster associated with
            %   referencing object R.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.contains'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
            tf = R.Intrinsic.contains(xi, yi);
        end
        
        
        function [X, Y] = worldGrid(R, gridOption)
            % worldGrid - World coordinates of raster elements
            %
            %   [X,Y] = worldGrid(R) returns the locations of raster
            %   elements in world coordinates as 2-D arrays, X and Y. When
            %   R is a MapCellsReference object, the locations are cell
            %   centers. When R is a MapPostingsReference object, the
            %   locations are posting points. The location of raster
            %   element (i,j) is (X(i,j), Y(i,j)). The values of size(X)
            %   and size(Y) both equal the RasterSize property of R.
            %
            %   [X,Y] = worldGrid(R,gridOption), where gridOption is
            %   'gridvectors', returns X and Y as row vectors. The location
            %   of raster element (i,j) is (X(j), Y(i)). The value of
            %   [length(Y) length(X)] equals the RasterSize property of R.
            %   You can only specify gridOption as 'gridvectors' when the
            %   TransformationType property of R has a value of
            %   'rectilinear'. The default for gridOption is 'fullgrid'.
            %   worldGrid(R,'fullgrid') is equivalent to worldGrid(R).
            % 
            %   Example
            %   -------
            %   R = maprefcells([7000 7600],[2700 3100],[4 6])
            %   [X,Y] = worldGrid(R)
            %   [X,Y] = worldGrid(R,"gridvectors")
            
            arguments
                R (1,1) map.rasterref.MapRasterReference
                gridOption (1,1) map.rasterref.GridOption = "fullgrid"
            end
            if gridOption == map.rasterref.GridOption.gridvectors ...
                    && matches(R.TransformationType,"affine")
                warning(message('map:spatialref:fullGridForAffine'))
                gridOption = "fullgrid";
            end
            I = R.Intrinsic;
            numrows = I.NumRows;
            numcols = I.NumColumns;
            xi = 1:numcols;
            yi = 1:numrows;
            if gridOption == map.rasterref.GridOption.fullgrid
                xi = repmat(xi,  [numrows 1]);
                yi = repmat(yi', [1 numcols]);
                [X, Y] = intrinsicToWorld(R, xi, yi);
            else
                [X, ~] = intrinsicToWorld(R, xi, ones(size(xi)));
                [~, Y] = intrinsicToWorld(R, ones(size(yi)), yi);
            end
        end
        
        
        function W = worldFileMatrix(R)
            %worldFileMatrix - World file parameters for transformation
            %
            %   W = worldFileMatrix(R) returns a 2-by-3 world file matrix.
            %   Each of the 6 elements in W matches one of the lines in a
            %   world file corresponding to the rectilinear or affine
            %   transformation defined by the referencing object R.
            %
            %   Given W with the form:
            %
            %                    W = [A B C;
            %                         D E F],
            %
            %   a point (xi, yi) in intrinsic coordinates maps to a point
            %   (xw, yw) in planar world coordinates like this:
            %
            %         xw = A * (xi - 1) + B * (yi - 1) + C
            %         yw = D * (xi - 1) + E * (yi - 1) + F.
            %
            %   Or, more compactly, [xw yw]' = W * [(xi - 1) (yi - 1) 1]'.
            %   The -1s allow the world file matrix to work with the
            %   Mapping Toolbox convention for intrinsic coordinates, which
            %   is consistent with the 1-based indexing used throughout
            %   MATLAB. W is stored in a world file with one term per line
            %   in column-major order: A, D, B, E, C, F.  That is, a world
            %   file contains the elements of W in the following order:
            %
            %         W(1,1)
            %         W(2,1)
            %         W(1,2)
            %         W(2,2)
            %         W(1,3)
            %         W(2,3).
            %
            %   The expressions above hold for both affine and rectilinear
            %   transformations, but whenever R.TransformationType is
            %   'rectilinear', B, D, W(2,1) and W(1,2) are identically 0.
            %
            %   See also WORLDFILEREAD, WORLDFILEWRITE.
            
            J = R.Transformation.jacobianMatrix();
            [c, f] = R.intrinsicToWorld(1,1);
            W = [J  [c; f]];
        end
        
        
        function xw = firstCornerX(R)
            %firstCornerX - World X coordinate of the (1,1) corner of the raster
            %
            %   firstCornerX(R) returns the world X coordinate of the
            %   outermost corner of the first cell (1,1) of the raster
            %   associated with referencing object R (if
            %   R.RasterInterpretation is 'cells') or the first sample
            %   point (if R.RasterInterpretation is 'postings').
            xw = R.Transformation.TiePointWorld(1);
        end
        
        
        function yw = firstCornerY(R)
            %firstCornerY - World Y coordinate of the (1,1) corner of the raster
            %
            %   firstCornerY(R) returns the world Y coordinate of the
            %   outermost corner of the first cell (1,1) of the raster
            %   associated with referencing object R (if
            %   R.RasterInterpretation is 'cells') or the first sample
            %   point (if R.RasterInterpretation is 'postings').
            yw = R.Transformation.TiePointWorld(2);
        end
    end
    
    
    methods (Hidden)
       function [Rnew, xSample, ySample] = scaleSizeAndDensity(R, scale)
            %scaleSizeAndDensity Scale reference object for resized raster 
            %
            %       FOR INTERNAL USE ONLY -- This method is intentionally
            %       undocumented and is intended for use only within other
            %       toolbox methods and functions. Its behavior may change,
            %       or the method itself may be removed in a future
            %       release.
            %
            %   [Rnew, xSample, ySample] = scaleSizeAndDensity(R, scale)
            %   scales the raster size and cell extents/sample sizes of the
            %   map raster reference object R, creating a new reference
            %   object with equal, or nearly equal, x and y world limits.
            %   It also returns the locations of the new cell centers /
            %   sample postings in the intrinsic coordinates of the input.
            %   These can be used to scale and resample the raster itself
            %   to a new size.
            %
            %   R is either a MapCellsReference object or a
            %   MapPostingsReference object.
            %
            %   scale is the factor by which to scale sample density and
            %   raster size (the same in both dimensions).
            %
            %   Rnew is a raster reference object with the same class and
            %   row/column directions as R, with RasterSize and cell
            %   extents/sample spacing values that preserve, or nearly
            %   preserve, the world x-y limits of R. If necessary, the
            %   limits are tightened slightly to enclose a discrete array
            %   of cells or postings within the original limits, while
            %   matching scale factors exactly as specified.
            %
            %   xSample indicates the location of the new cell centers or
            %   sample postings in the intrinsic space of the original
            %   raster. It's a vector of size Rnew.RasterSize(2)-by-1 such
            %   that xSample(j) is the location, relative to the input
            %   raster, of the cell centers or posting points in the j-th
            %   column of the new raster.
            %
            %   ySample indicates the location of the new cell centers or
            %   sample postings in the intrinsic space of the original
            %   raster. It's a vector of size Rnew.RasterSize(1)-by-1
            %   such that ySample(i) is the location, relative to the input
            %   raster, of the cell centers or posting points in the i-th
            %   row of the new raster.
            %
            %   Together, xSample and ySample indicate the locations at
            %   which to interpolate the columns and rows of a raster
            %   associated with R while resampling it to match Rnew.
            %
            %   Example
            %   -------
            %   xWorldLimits = [207000 208000];
            %   yWorldLimits = [912500 913000];
            %   rasterSize = [1000 2000]
            %   R = maprefcells(xWorldLimits,yWorldLimits,rasterSize, ...
            %       'ColumnsStartFrom','north')
            %   [Rnew, xSample, ySample] = scaleSizeAndDensity(R, 1/5);
            %   Rnew
            
            scale = abs(scale);
            
            % Let the intrinsic raster reference object do as much of the
            % work as possible.
            [numrows, numcols, xSample, ySample, xshift, yshift] ...
                = scaleRaster(R.Intrinsic, scale, scale);
            
            % Copy defining properties of R to the struct S.
            S = encodeInStructure(R);
            
            % New raster size
            S.RasterSize = [numrows numcols];
            
            % Scale Jacobian matrix
            [numScale, denScale] = map.rasterref.internal.simplifyRatio(scale, 1);
            if isfield(S, "Jacobian")
                % Affine transformation
                J = S.Jacobian;
                J.Numerator   = denScale * J.Numerator;
                J.Denominator = numScale * J.Denominator;
                S.Jacobian = J;
            else
                % Rectilinear transformation
                S.DeltaNumerator   = denScale * S.DeltaNumerator;
                S.DeltaDenominator = numScale * S.DeltaDenominator;
            end
            
            % Shift tie point, if necessary
            if xshift ~= 0 || yshift ~= 0
                xi = S.TiePointIntrinsic(1) + xshift;
                yi = S.TiePointIntrinsic(2) + yshift;
                [xw, yw] = intrinsicToWorld(R, xi, yi);
                S.TiePointWorld = [xw yw];
            end
            
            % Construct raster reference object for scaled raster.
            Rnew = restoreFromStructure(R, S);
        end
        
        
        function Rblock = maprefblock(R, rowLimits, colLimits)
            %maprefblock Referencing object for sub-block of map raster
            %
            %       FOR INTERNAL USE ONLY -- This method is intentionally
            %       undocumented and is intended for use only within other
            %       toolbox methods and functions. Its behavior may change,
            %       or the method itself may be removed in a future
            %       release.
            %
            %   Rblock = maprefblock(R,rowLimits,colLimits) returns a
            %   referencing object for a sub-block of a regular raster or
            %   image in planar map coordinates, with referencing object R,
            %   consisting of the following rows and columns:
            %
            %        rowLimits(1):rowLimits(2)
            %        colLimits(1):colLimits(2).
            %
            %   The two-element row and column limits vectors must contain
            %   positive real integer values, must be strictly ascending,
            %   and must be bounded by R.RasterSize. An error is thrown if:
            %
            %       rowLimits(2) > R.RasterSize(1) or
            %       colLimits(2) > R.RasterSize(2).
            %
            %   Example
            %   -------
            %   % Derive a raster reference object for a 500-by-1000 block
            %   % from the center of a 1000-by-2000 grid of 0.5-meter cells
            %   % in map coordinates.
            %   xWorldLimits = [207000 208000];
            %   yWorldLimits = [912500 913000];
            %   rasterSize = [1000 2000];
            %   R = maprefcells(xWorldLimits,yWorldLimits,rasterSize, ...
            %       'ColumnsStartFrom','north')
            %   Rblock = maprefblock(R, [251 750], [501 1500])
            
            attributes = {'real','positive','integer','numel',2,'increasing'};  
            validateattributes(rowLimits, {'double'}, attributes, '', 'rowLimits')
            validateattributes(colLimits, {'double'}, attributes, '', 'colLimits')
            
            if rowLimits(2) > R.RasterSize(1)
                error(message('map:spatialref:exceeds','rowLimits(2)', ...
                    'R.RasterSize(1)', num2str(R.RasterSize(1))))
            end
            
            if colLimits(2) > R.RasterSize(2)
                error(message('map:spatialref:exceeds','colLimits(2)', ...
                    'R.RasterSize(2)', num2str(R.RasterSize(2))))
            end
            
            % The following implementation is appropriate to both cells and
            % postings (which is why it is implemented here in the
            % map raster reference superclass), is also appropriate to both
            % rectilinear and affine transformation types.
            
            % Size of sub-block raster
            rasterSize = [diff(rowLimits) + 1, diff(colLimits) + 1];
            
            % Copy the transformation and shift its world tie point.
            % (Compute the shift in the intrinsic system, but apply it in
            % the world system.)
            T = R.Transformation;
            xIntrinsic = T.TiePointIntrinsic(1) + colLimits(1) - 1;
            yIntrinsic = T.TiePointIntrinsic(2) + rowLimits(1) - 1;
            [xWorldTie, yWorldTie] = intrinsicToWorld(T, xIntrinsic, yIntrinsic);
            T.TiePointWorld = [xWorldTie; yWorldTie];
            
            % Rblock is like R, but may have a smaller raster size and
            % different world tie point in its transformation.
            Rblock = setIntrinsicRasterSize(R, rasterSize);
            Rblock.Transformation = T;
        end
    end
    
    %-------------------------- Set methods ----------------------------
    
    methods
        function R = set.RasterSize(R, rasterSize)
            
            % Current dimensions in intrinsic system.
            currentIntrinsicWidth  = diff(R.XIntrinsicLimits);
            currentIntrinsicHeight = diff(R.YIntrinsicLimits);
            
            % Update intrinsic properties on which RasterSize depends
            % and the transient properties that depend on them.
            try
                R = setIntrinsicRasterSize(R, rasterSize);
            catch e
                rethrow(e)
            end
            
            % Rescale the columns of the Jacobian matrix, as appropriate.
            R = rescaleJacobian(R, ...
                currentIntrinsicWidth, currentIntrinsicHeight);
        end
        
        
        function R = set.XWorldLimits(R, xWorldLimits)
            validateattributes(xWorldLimits, ...
                {'double'}, {'real','row','finite','size', [1 2]}, ...
                [class(R) '.set.XWorldLimits'], ...
                'xWorldLimits')
            
            map.internal.assert(xWorldLimits(1) < xWorldLimits(2), ...
                'map:spatialref:expectedAscendingLimits','xWorldLimits')
            
            currentXWorldLimits = R.getXWorldLimits();
            
            % Take differences of limits (widths of bounding
            % rectangles); these will be positive numbers.
            difference = diff(xWorldLimits);
            currentDifference = diff(currentXWorldLimits);
            
            % Scale the first row of the Jacobian matrix to match the
            % change in world X extent.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            N(1,:) = N(1,:) * difference;
            D(1,:) = D(1,:) * currentDifference;
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
            
            % Reset the X component of the tie point to take care of
            % any translation that is also occurring.
            R = shiftTiePointWorldX(R, xWorldLimits);
        end
        
        
        function R = set.YWorldLimits(R, yWorldLimits)
            
            validateattributes(yWorldLimits, ...
                {'double'}, {'real','row','finite','size', [1 2]}, ...
                [class(R) '.set.YWorldLimits'], ...
                'yWorldLimits')
            
            map.internal.assert(yWorldLimits(1) < yWorldLimits(2), ...
                'map:spatialref:expectedAscendingLimits','YWorldLimits')
            
            currentYWorldLimits = R.getYWorldLimits();
            
            % Take differences of limits (widths of bounding
            % rectangle); these will be positive numbers.
            difference = diff(yWorldLimits);
            currentDifference = diff(currentYWorldLimits);
            
            % Scale the second row of the Jacobian matrix to match the
            % change in world Y extent.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            N(2,:) = N(2,:) * difference;
            D(2,:) = D(2,:) * currentDifference;
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
            
            % Reset the Y component of the tie point to take care of
            % any translation that is also occurring.
            R = shiftTiePointWorldY(R, yWorldLimits);
        end
        
        
        function R = set.ColumnsStartFrom(R, edge)
            edge = validatestring(edge, {'south','north'});
            
            reverseRasterColumns = xor( ...
                R.columnsRunSouthToNorth(), strcmp(edge, 'south'));
            if reverseRasterColumns
                % The current (end,1) corner will become the new tie point
                % in the world coordinates.
                [newTiePointX, newTiePointY] ...
                    = R.Transformation.intrinsicToWorld( ...
                    R.XIntrinsicLimits(1), R.YIntrinsicLimits(2));
                
                R.Transformation.TiePointWorld...
                    = [newTiePointX; newTiePointY];
                
                % Change the sign of the second column of the
                % Jacobian matrix.
                J = R.Transformation.Jacobian;
                J.Numerator(:,2) = -J.Numerator(:,2);
                R.Transformation.Jacobian = J;
            end
        end
        
        
        function R = set.RowsStartFrom(R, edge)
            edge = validatestring(edge, {'east','west'});
            
            reverseRasterRows = xor( ...
                R.rowsRunWestToEast(), strcmp(edge, 'west'));
            if reverseRasterRows
                % The current (1,end) corner will become the new tie point
                % in the world coordinates.
                [newTiePointX, newTiePointY] ...
                    = R.Transformation.intrinsicToWorld( ...
                    R.XIntrinsicLimits(2), R.YIntrinsicLimits(1));
                
                R.Transformation.TiePointWorld...
                    = [newTiePointX; newTiePointY];
                % Change the sign of the first column of the
                % Jacobian matrix.
                J = R.Transformation.Jacobian;
                J.Numerator(:,1) = -J.Numerator(:,1);
                R.Transformation.Jacobian = J;
            end
        end
        
        function R = set.ProjectedCRS(R, crs)
            if ~isempty(crs)
                validateattributes(crs, ...
                    {'projcrs'}, {'scalar'}, ...
                    [class(R) '.set.ProjectedCRS'], 'crs')
                R.pProjectedCRS = crs;
            else
                R.pProjectedCRS = [];
            end
        end
    end
    
    %----------------- Get methods for public properties ------------------
    
    methods
        function rasterSize = get.RasterSize(R)
            I = R.Intrinsic;
            rasterSize = [I.NumRows I.NumColumns];
        end
        
        
        function limits = get.XWorldLimits(R)
            limits = R.getXWorldLimits();
        end
        
        
        function limits = get.YWorldLimits(R)
            limits = R.getYWorldLimits();
        end
        
        
        function edge = get.ColumnsStartFrom(R)
            if R.columnsRunSouthToNorth()
                edge = 'south';
            else
                edge = 'north';
            end
        end
        
        
        function edge = get.RowsStartFrom(R)
            if R.rowsRunWestToEast()
                edge = 'west';
            else
                edge = 'east';
            end
        end
        
        
        function width = get.RasterExtentInWorldX(R)
            width = abs(R.DeltaX) * diff(R.XIntrinsicLimits);
        end
        
        
        function height = get.RasterExtentInWorldY(R)
            height = abs(R.DeltaY) * diff(R.YIntrinsicLimits);
        end
        
        
        function type = get.TransformationType(R)
            type =  R.Transformation.TransformationType;
        end
        
        
        function crs = get.ProjectedCRS(R)
            crs = R.pProjectedCRS;
        end
    end

    %------------------- Private/protected methods ------------------------
    
    methods (Access = protected)
        function S = encodeInStructure(R)
            % Encode the state of the map raster reference object R into
            % structure S.
            
            T = R.Transformation;
            
            S = struct( ...
                'RasterSize',          R.RasterSize, ...
                'TransformationType',  R.TransformationType, ...
                'TiePointIntrinsic',   T.TiePointIntrinsic, ...
                'TiePointWorld',       T.TiePointWorld);
            
            % The presence/absence of several fields depends on the
            % geometric transformation type.
            if strcmp(S.TransformationType,'rectilinear')
                S.DeltaNumerator   = T.DeltaNumerator;
                S.DeltaDenominator = T.DeltaDenominator;
            else
                % TransformationType is 'affine'
                S.Jacobian = T.Jacobian;
            end
            
            % Store CRS
            S.ProjectedCRS = R.ProjectedCRS;
        end
        
        
        function R = restoreFromStructure(R, S)
            % Restore map raster reference object R to the state defined by
            % the scalar structure S.
            
            % Update the intrinsic properties on which RasterSize depends,
            % without using its set method.
            R = setIntrinsicRasterSize(R, S.RasterSize);

            % Construct a transformation object
            if strcmp(S.TransformationType,'rectilinear')
                % TransformationType is 'rectilinear'; avoid setting
                % the Jacobian property, because that invokes
                % map.rasterref.internal.simplifyRatio, which could
                % change behavior in a future release.
                T = map.rasterref.internal.RectilinearTransformation;
                T.DeltaNumerator   = S.DeltaNumerator;
                T.DeltaDenominator = S.DeltaDenominator;
            else
                % TransformationType is 'affine'; OK to use the
                % set.Jacobian method.
                T = map.rasterref.internal.AffineTransformation;
                T.Jacobian = S.Jacobian;
            end
            T.TiePointIntrinsic = S.TiePointIntrinsic;
            T.TiePointWorld     = S.TiePointWorld;
            
            % Assign the transformation object to R
            R.Transformation = T;
            
            % Restore CRS
            if isfield(S,'ProjectedCRS')
                R.ProjectedCRS = S.ProjectedCRS;
            end
        end
        
        
        function R = setAbsoluteDeltaX(R, absoluteDeltaX)
            % Set the absolute value of deltaX, preserving its sign.
            %
            % Set the protected, defining properties directly, without
            % triggering any additional set methods.
            
            rasterSize = R.RasterSize;
            N = (rasterSize(2) - R.ElementsMinusIntervals) ...
                    * currentAbsoluteDeltaX(R) / absoluteDeltaX;
                
            exactFit = (N == round(N));
            if exactFit
                % Adjust number of columns but keep tie point fixed.
                rasterSize(2) = N + R.ElementsMinusIntervals;
                R = setIntrinsicRasterSize(R, rasterSize);
                R = rescaleJacobianColumn(R, 1, absoluteDeltaX);
            else
                % Shift tie point and adjust number of columns.
                if strcmp(R.TransformationType,'rectilinear')
                    R = snapXRectilinear(R, absoluteDeltaX);
                else
                    R = snapXAffine(R, absoluteDeltaX);
                end
            end
        end
        
        
        function R = setAbsoluteDeltaY(R, absoluteDeltaY)
            % Set the absolute value of deltaY, preserving its sign.
            %
            % Set the protected, defining properties directly, without
            % triggering any additional set methods.
            
            rasterSize = R.RasterSize;
            N = (rasterSize(1) - R.ElementsMinusIntervals) ...
                    * currentAbsoluteDeltaY(R) / absoluteDeltaY;
                
            exactFit = (N == round(N));
            if exactFit
                % Adjust number of rows but keep tie point fixed.
                rasterSize(1) = N + R.ElementsMinusIntervals;
                R = setIntrinsicRasterSize(R, rasterSize);
                R = rescaleJacobianColumn(R, 2, absoluteDeltaY);
            else
                % Shift tie point and adjust number of rows.
                if strcmp(R.TransformationType,'rectilinear')
                    R = snapYRectilinear(R, absoluteDeltaY);
                else
                    R = snapYAffine(R, absoluteDeltaY);
                end
            end
            
        end
    end
    
    
    methods (Access = private)
        function R = setIntrinsicRasterSize(R, rasterSize)
            % Update the intrinsic properties on which RasterSize depends.
            I = R.Intrinsic;
            I = setRasterSize(I, rasterSize);
            R.Intrinsic = I;
            
            % Update transient properties.
            [xlimits, ylimits] = limits(I);
            R.XIntrinsicLimits = xlimits;
            R.YIntrinsicLimits = ylimits;
        end
        
        
        function R = shiftTiePointWorldX(R, xWorldLimits)
            % Shift the tie point in world X to match new limits in world X.
            T = R.Transformation;
            currentXWorldLimits = getXWorldLimits(R);
            difference = diff(xWorldLimits);
            currentDifference = diff(currentXWorldLimits);
            currentTiePointX = T.TiePointWorld(1);
            newTiePointX = xWorldLimits(1) ...
                + (currentTiePointX - currentXWorldLimits(1)) ...
                    * difference / currentDifference;
            T.TiePointWorld(1) = newTiePointX;
            R.Transformation = T;
        end
        
        
        function R = shiftTiePointWorldY(R, yWorldLimits)
            % Shift the tie point in world Y to match new limits in world Y.
            T = R.Transformation;
            currentYWorldLimits = getYWorldLimits(R);
            difference = diff(yWorldLimits);
            currentDifference = diff(currentYWorldLimits);
            currentTiePointY = T.TiePointWorld(2);
            newTiePointY = yWorldLimits(1) ...
                + (currentTiePointY - currentYWorldLimits(1)) ...
                    * difference / currentDifference;
            T.TiePointWorld(2) = newTiePointY;
            R.Transformation = T;
        end
        
        
        function R = rescaleJacobian(R, ...
                previousIntrinsicWidth, previousIntrinsicHeight)
            % Update the Jacobian matrix in response to a change in the
            % intrinsic dimensions of the raster (which could be due to a
            % change in RasterSize or in RasterInterpretation).
            
            % New dimensions in intrinsic system.
            [xlimits, ylimits] = limits(R.Intrinsic);
            newIntrinsicWidth  = diff(xlimits);
            newIntrinsicHeight = diff(ylimits);
            
            % Rescale the columns of the Jacobian matrix, as appropriate.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            
            if previousIntrinsicWidth > 0 && newIntrinsicWidth > 0
                % This is the typical case. Scale the first column of the
                % Jacobian matrix such that the raster continues to fit
                % exactly within the current limits. In all other cases
                % simply leave the Jacobian matrix as-is.
                N(:,1) = N(:,1) * previousIntrinsicWidth;
                D(:,1) = D(:,1) * newIntrinsicWidth;
            end
            
            if previousIntrinsicHeight > 0 && newIntrinsicHeight > 0
                % This is the typical case. Scale the second column of the
                % Jacobian matrix such that the raster continues to fit
                % exactly within the current limits. In all other cases
                % simply leave the Jacobian matrix as-is.
                N(:,2) = N(:,2) * previousIntrinsicHeight;
                D(:,2) = D(:,2) * newIntrinsicHeight;
            end
            
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
        end
        
        
        function limits = getXWorldLimits(R)
            % X-limits of bounding rectangle in world system
            xi = R.XIntrinsicLimits([1 1 2 2]);
            yi = R.YIntrinsicLimits([1 2 1 2]);
            [xw, ~] = R.Transformation.intrinsicToWorld(xi, yi);
            limits = [min(xw), max(xw)];
        end
        
        
        function limits = getYWorldLimits(R)
            % Y-limits of bounding rectangle in world system
            xi = R.XIntrinsicLimits([1 1 2 2]);
            yi = R.YIntrinsicLimits([1 2 1 2]);
            [~, yw] = R.intrinsicToWorld(xi, yi);
            limits = [min(yw), max(yw)];
        end
        
        
        function tf = rowsRunWestToEast(R)
            % True if and only if rows start from due west,
            % +/- an angle of pi/2.
            
            % Angle between intrinsic X axis and world X axis
            J = R.Transformation.jacobianMatrix();
            alpha = atan2(J(2,1), J(1,1));
            
            tf = (-pi/2 < alpha && alpha <= pi/2);
        end
        
        
        function tf = columnsRunSouthToNorth(R)
            % True if and only if columns start from due south,
            % +/- an angle of pi/2.
            
            % Angle between intrinsic Y axis and world Y axis
            J = R.Transformation.jacobianMatrix();
            beta = atan2(J(1,2), J(2,2));
            
            tf = -pi/2 < beta && beta <= pi/2;
        end
        
        
        function R = snapXRectilinear(R, absoluteDeltaX)
            [num, den] = map.rasterref.internal.simplifyRatio(absoluteDeltaX, 1);
            xWorldLimits = map.internal.snapLimits(R.getXWorldLimits(), num, den);
            R = shiftTiePointWorldX(R, xWorldLimits);
            rasterSize = R.RasterSize;
            rasterSize(2) = round(den * diff(xWorldLimits) / num) ...
                + R.ElementsMinusIntervals;
            R = setIntrinsicRasterSize(R, rasterSize);
            R = rescaleJacobianColumn(R, 1, absoluteDeltaX);
        end
        
        
        function R = snapYRectilinear(R, absoluteDeltaY)
            [num, den] = map.rasterref.internal.simplifyRatio(absoluteDeltaY, 1);
            yWorldLimits = map.internal.snapLimits(R.getYWorldLimits(), num, den);
            R = shiftTiePointWorldY(R, yWorldLimits);
            rasterSize = R.RasterSize;
            rasterSize(1) = round(den * diff(yWorldLimits) / num) ...
                + R.ElementsMinusIntervals;
            R = setIntrinsicRasterSize(R, rasterSize);
            R = rescaleJacobianColumn(R, 2, absoluteDeltaY);
        end
        
        
        function R = snapXAffine(R, absoluteDeltaX)
            rasterSize = R.RasterSize;
            N = (rasterSize(2) - R.ElementsMinusIntervals) ...
                * currentAbsoluteDeltaX(R) / absoluteDeltaX;
            C = ceil(N);
            offset = absoluteDeltaX * (C - N) / 2;
            R = offsetTiePointWorld(R, offset, 1);
            rasterSize(2) = C + R.ElementsMinusIntervals;
            R = setIntrinsicRasterSize(R, rasterSize);
            R = rescaleJacobianColumn(R, 1, absoluteDeltaX);
        end
        
        
        function R = snapYAffine(R, absoluteDeltaY)
            rasterSize = R.RasterSize;
            N = (rasterSize(1) - R.ElementsMinusIntervals) ...
                * currentAbsoluteDeltaY(R) / absoluteDeltaY;
            C = ceil(N);
            offset = absoluteDeltaY * (C - N) / 2;
            R = offsetTiePointWorld(R, offset, 2);
            rasterSize(1) = C + R.ElementsMinusIntervals;
            R = setIntrinsicRasterSize(R, rasterSize);
            R = rescaleJacobianColumn(R, 2, absoluteDeltaY);
        end
        
        
        function R = offsetTiePointWorld(R, offset, k)
            % Offset the world tie point in the direction opposite from the
            % k-th column of the Jacobian matrix.
            T = R.Transformation;
            J = T.Jacobian;
            v = J.Numerator(:,k) ./ J.Denominator(:,k);
            shift = offset * (v / norm(v));
            T.TiePointWorld = T.TiePointWorld - shift;
            R.Transformation = T;
        end
        
        
        function absoluteDeltaX = currentAbsoluteDeltaX(R)
            absoluteDeltaX = abs(deltaX(R.Transformation));
        end
        
        
        function absoluteDeltaY = currentAbsoluteDeltaY(R)
            absoluteDeltaY = abs(deltaY(R.Transformation));
        end
        
        
        function R = rescaleJacobianColumn(R, n, absoluteDelta)
            % Rescale column n of the Jacobian matrix of the transformation
            % according to the change in absoluteDelta.
            
            T = R.Transformation;
            J = T.Jacobian;
            
            if n == 1
                currentAbsoluteDelta = abs(deltaX(T));
            else
                currentAbsoluteDelta = abs(deltaY(T));
            end
            
            [num, den] = map.rasterref.internal.simplifyRatio( ...
                absoluteDelta, currentAbsoluteDelta);
            
            J.Numerator(:,n) = num * J.Numerator(:,n);
            J.Denominator(:,n) = den * J.Denominator(:,n);
            
            T.Jacobian = J;
            R.Transformation = T;
        end
    end
end

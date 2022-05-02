classdef (Sealed = true) MapCellsReference ...
    < map.rasterref.MapRasterReference & matlab.mixin.CustomDisplay
%MapCellsReference Reference raster cells to map coordinates
%
%   To construct a map.rasterref.MapCellsReference object, use
%   the maprefcells function or the maprasterref function.
%
%   Class Description
%   -----------------
%   map.rasterref.MapCellsReference properties:
%      XWorldLimits - Limits of raster in world X [xMin xMax]
%      YWorldLimits - Limits of raster in world Y [yMin yMax]
%      RasterSize - Number of cells or samples in each spatial dimension
%      ColumnsStartFrom - Edge where column indexing starts: 'south' or 'north'
%      RowsStartFrom - Edge where row indexing starts: 'west' or 'east'
%      CellExtentInWorldX - Extent in world X of individual cells
%      CellExtentInWorldY - Extent in world Y of individual cells
%
%   map.rasterref.MapCellsReference properties (read-only):
%      RasterExtentInWorldX - Extent in world X of the full raster
%      RasterExtentInWorldY - Extent in world Y of the full raster
%      XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
%      YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
%      RasterInterpretation - Geometric nature of raster (constant: 'cells')
%      TransformationType - Transformation type: 'rectilinear' or 'affine'
%      CoordinateSystemType - Type of external system (constant: 'planar')
%
%   map.rasterref.MapCellsReference methods:
%      sizesMatch - True if object and raster or image are size-compatible
%      intrinsicToWorld - Convert from intrinsic to world coordinates
%      worldToIntrinsic - Convert from world to intrinsic coordinates
%      worldToDiscrete - Transform map to discrete coordinates
%      contains - True if raster contains points in world coordinate system
%      worldGrid - World coordinates of raster elements
%      firstCornerX - World X coordinate of the (1,1) corner of the raster
%      firstCornerY - World Y coordinate of the (1,1) corner of the raster
%      worldFileMatrix - World file parameters for transformation
%
%   See also maprefcells, maprasterref

 % Copyright 2013-2020 The MathWorks, Inc.

    %---- Constant property that helps make the class self-descriptive ----
    
    properties (Constant)
        % RasterInterpretation Geometric nature of raster
        % 
        %   RasterInterpretation, which controls handling of raster edges,
        %   among other things, has the constant value 'cells'. This
        %   indicates that the raster comprises a grid of quadrangular
        %   cells, and is bounded on all sides by cell edges. For an M-by-N
        %   raster, points with an intrinsic X-coordinate of 1 or N or an
        %   intrinsic Y-coordinate of 1 or M fall within the raster, not on
        %   its edges.
        RasterInterpretation = 'cells';
    end

    %-------- Concrete declarations of abstract superclass properties ------
    
    properties (SetAccess = protected, Transient = true)
        % XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
        %
        %    XIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [0.5, N + 0.5].
        XIntrinsicLimits;
        
        % YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
        %
        %    YIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [0.5, M + 0.5].
        YIntrinsicLimits;
    end
    
    properties (Access = protected)
        Intrinsic = map.rasterref.internal.IntrinsicCellsReference;
    end
    
    properties (Constant, Access = protected)
        % Number of columns or rows ("elements") minus number of intervals
        % of width CellExtentInWorldX or CellExtentInWorldY. Equal to
        % both:
        %
        %   R.RasterSize(2) - intervalsInX
        %   R.RasterSize(1) - intervalsInY
        %
        % where:
        %
        %   intervalsInX = R.RasterExtentInWorldX / R.CellExtentInWorldX
        %   intervalsInY = R.RasterExtentInWorldY / R.CellExtentInWorldY
        ElementsMinusIntervals = 0;
    end

    %------------------ Add in CellExtent properties ----------------------
    
    properties (Dependent)
        % CellExtentInWorldX Extent in world X of individual cells
        %
        %     Distance between the eastern and western limits of a single
        %     raster cell. The value is aways positive, and is the same for
        %     all cells in the raster.
        CellExtentInWorldX
        
        % CellExtentInWorldY Extent in world Y of individual cells
        %
        %     Distance between the northern and southern limits of a single
        %     raster cell. The value is aways positive, and is the same for
        %     all cells in the raster.
        CellExtentInWorldY
    end
    
    methods
        function extent = get.CellExtentInWorldX(R)
            extent = abs(R.Transformation.deltaX());
        end
        
        
        function extent = get.CellExtentInWorldY(R)
            extent = abs(R.Transformation.deltaY());
        end
        
        
        function R = set.CellExtentInWorldX(R, extent)
            fname = 'map.rasterref.MapCellsReference.set.CellExtentInWorldX';
            validateattributes(extent, {'double'}, ...
                {'real','scalar','finite','positive'}, fname, 'CellExtentInWorldX')
            R = setAbsoluteDeltaX(R, extent);
        end
        
        
        function R = set.CellExtentInWorldY(R, extent)
            fname = 'map.rasterref.MapCellsReference.set.CellExtentInWorldY';
            validateattributes(extent, {'double'}, ...
                {'real','scalar','finite','positive'}, fname, 'CellExtentInWorldY')
            R = setAbsoluteDeltaY(R, extent);
        end
    end
    
    %------------------------- save/load object ---------------------------
    
    methods (Hidden)
        function S = saveobj(R)
            % Use a protected superclass method to encode the defining
            % properties of the object R into structure S.  The fields
            % present in S depend on the geometric transformation type.
            S = encodeInStructure(R);
        end
    end
    
    
    methods (Static, Hidden)
        function R = loadobj(S)
            % The saveobj method ensures that S is a structure in which
            % the fields related to the geometric transformation depend on
            % the transformation type. Construct a default
            % map.rasterref.MapCellsReference object and use a protected
            % superclass method to reset its defining properties.
            R = map.rasterref.MapCellsReference;
            R = restoreFromStructure(R,S);
        end
        
    end
    
    %--------------------------- Construction -----------------------------
    
    methods
        
        function R = MapCellsReference(rasterSize, firstCornerX, ...
                firstCornerY, jacobianNumerator, jacobianDenominator)
            %   R = map.rasterref.MapCellsReference(rasterSize, ...
            %     lengthUnits, firstCornerX, firstCornerY, ...
            %     jacobianNumerator, jacobianDenominator)
            %   constructs a map raster referencing object from the
            %   following inputs (all 5 must be provided):
            %
            %     rasterSize -- A valid MATLAB size vector (as returned
            %        by SIZE) corresponding to the size of a raster or
            %        image to be used in conjunction with the referencing
            %        rasterSize must have at least two elements, but may
            %        have more. In this case only the first two
            %        (corresponding to the "spatial dimensions") are used
            %        and the others are ignored. For example, if rasterSize
            %        = size(RGB) where RGB is an RGB image, the rasterSize
            %        will have the form [M N 3] and the RasterSize property
            %        will be set to [M N].  M and N must be strictly
            %        positive.
            %
            %     firstCornerX, firstCornerY -- Scalar values
            %        defining the world X and world Y position of the
            %        outermost corner of the first cell (1,1) of the
            %        raster.
            %
            %     jacobianNumerator -- Real, non-singular 2-by-2 matrix
            %     jacobianDenominator -- Real, positive 2-by-2 matrix
            %
            %         The ratio J = jacobianNumerator./jacobianDenominator
            %         determines the Jacobian matrix indicating how
            %         the world coordinates of a point change with
            %         respect to changes in its intrinsic coordinates:
            %
            %         J(1,1) = change in world X wrt intrinsic X
            %         J(1,2) = change in world X wrt intrinsic Y
            %         J(2,1) = change in world Y wrt intrinsic X
            %         J(2,2) = change in world Y wrt intrinsic Y
            %
            %        All 4 elements of jacobianDenominator must be
            %        strictly positive. Because both rectilinear and
            %        affine mappings are both linear, J is invariant
            %        with respect to point location. In the rectilinear
            %        case, J is a diagonal matrix.
            
            % Use the superclass to initialize intrinsic and transient
            % properties. Avoid calling the superclass constructor inside
            % a conditional block.
            if nargin == 0
                superclassInputs = {};
            else
                superclassInputs = {rasterSize};
            end
            R = R@map.rasterref.MapRasterReference(superclassInputs{:});
            
            if nargin == 0
                % Construct rectilinear transformation object.
                R.Transformation = map.rasterref.internal.RectilinearTransformation;
                
                % Set default tie points to be consistent with a
                % single cell, 1-by-1 in world units, centered at
                % xWorld = 1, yWorld = 1, and maintain an identity
                % transformation between the two systems.
                R.Transformation.TiePointIntrinsic = [0.5; 0.5];
                R.Transformation.TiePointWorld     = [0.5; 0.5];
                
                % Set Jacobian matrix to be the 2-by-2 identity matrix.
                R.Transformation.Jacobian = struct( ...
                    'Numerator', [1 0; 0 1], 'Denominator', [1 1; 1 1]);
            elseif nargin == 5
                validateattributes(firstCornerX, {'double'}, ...
                    {'real','scalar','finite'}, class(R), 'firstCornerX')
                
                validateattributes(firstCornerY, {'double'}, ...
                    {'real','scalar','finite'}, class(R), 'firstCornerY')
                
                % Construct transformation object (rectilinear or affine).
                tiePointIntrinsic ...
                    = [R.XIntrinsicLimits(1); R.YIntrinsicLimits(1)];
                
                tiePointWorld = [firstCornerX; firstCornerY];
                
                R.Transformation ...
                    = map.rasterref.internal.makeGeometricTransformation( ...
                    tiePointIntrinsic, tiePointWorld, ...
                    jacobianNumerator, jacobianDenominator);
            else
                % There must be exactly 5 inputs, or none.
                error(message('map:validate:invalidArgCount'))
            end
        end
        
    end
    
    %-------------------------- Custom display ----------------------------
    
    methods (Access = 'protected')
        
        function displayScalarObject(R)
            % Provide a custom display for the case in which the
            % referencing object R is scalar. Override the default property
            % order, and display the cell extent values as ratios if
            % appropriate.
            
            % The default header is fine.
            header = getHeader(R);
            disp(header)
            
            % Customize the property order.
            props = {
                'XWorldLimits'
                'YWorldLimits'
                'RasterSize'
                'RasterInterpretation'
                'ColumnsStartFrom'
                'RowsStartFrom'
                'CellExtentInWorldX'
                'CellExtentInWorldY'
                'RasterExtentInWorldX'
                'RasterExtentInWorldY'
                'XIntrinsicLimits'
                'YIntrinsicLimits'
                'TransformationType'
                'CoordinateSystemType'
                'ProjectedCRS'
                };
            
            % Always use format longG; restore current format when done.
            fmt = get(0,'format');
            clean = onCleanup(@() format(fmt));
            format('longG')

            % Construct a ready-to-display string listing the scalar
            % property names and their values.
            values = cellfun(@(propertyName) R.(propertyName), ...
                props, 'UniformOutput', false);
            s = cell2struct(values, props, 1); %#ok<NASGU>
            str = evalc('builtin(''disp'', s)');
            
            [deltaNumerator, deltaDenominator] ...
                = rationalDelta(R.Transformation);
            
            % Override the format for the CellExtentInWorldX property,
            % if it would be more informative to display a ratio than a
            % decimal number.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    deltaNumerator(1), deltaDenominator(1))
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'CellExtentInWorldX', ...
                    abs(deltaNumerator(1)), deltaDenominator(1));
            end
            
            % Likewise for the CellExtentInWorldY property.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    deltaNumerator(2), deltaDenominator(2))
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'CellExtentInWorldY', ...
                    abs(deltaNumerator(2)), deltaDenominator(2));
            end
            
            % Display the modified string.
            disp(str)
            
            % Allow for the possibility of a footer.
            footer = getFooter(R);
            if ~isempty(footer)
                disp(footer);
            end
        end
        
    end
    
end

classdef (Sealed = true) MapPostingsReference ...
    < map.rasterref.MapRasterReference & matlab.mixin.CustomDisplay
%MapPostingsReference Reference raster postings to map coordinates
%
%   To construct a map.rasterref.MapPostingsReference object, use
%   the maprefpostings function or the maprasterref function.
%
%   Class Description
%   -----------------
%   map.rasterref.MapPostingsReference properties:
%      XWorldLimits - Limits of raster in world X [xMin xMax]
%      YWorldLimits - Limits of raster in world Y [yMin yMax]
%      RasterSize - Number of cells or samples in each spatial dimension
%      ColumnsStartFrom - Edge where column indexing starts: 'south' or 'north'
%      RowsStartFrom - Edge where row indexing starts: 'west' or 'east'
%      SampleSpacingInWorldX - Distance in world X between adjacent samples
%      SampleSpacingInWorldY - Distance in world Y between adjacent samples
%
%   map.rasterref.MapPostingsReference properties (read-only):
%      RasterExtentInWorldX - Extent in world X of the full raster
%      RasterExtentInWorldY - Extent in world Y of the full raster
%      XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
%      YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
%      RasterInterpretation - Geometric nature of raster (constant: 'postings')
%      TransformationType - Transformation type: 'rectilinear' or 'affine'
%      CoordinateSystemType - Type of external system (constant: 'planar')
%
%   map.rasterref.MapPostingsReference methods:
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
%   See also maprefpostings, maprasterref

 % Copyright 2013-2020 The MathWorks, Inc.

    %---- Constant property that helps make the class self-descriptive ----
    
    properties (Constant)
        % RasterInterpretation Geometric nature of raster
        % 
        %   RasterInterpretation, which controls handling of raster edges,
        %      among other things, has the constant value 'postings'. This
        %      indicates that the raster comprises a grid of sample points,
        %      where rows or columns of samples run along the edge of the
        %      grid. For an M-by-N raster, points with an intrinsic
        %      X-coordinate of 1 or N and/or an intrinsic Y-coordinate of
        %      1 or M fall right on an edge (or corner) of the raster.
        RasterInterpretation = 'postings';
    end

    %-------- Concrete declarations of abstract superclass properties ------
    
    properties (SetAccess = protected, Transient = true)
        % XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
        %
        %    XIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [1 N].
        XIntrinsicLimits;
        
        % YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
        %
        %    YIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [1 M].
        YIntrinsicLimits;
    end
    
    properties (Access = protected)
        Intrinsic = map.rasterref.internal.IntrinsicPostingsReference;
    end
    
    properties (Constant, Access = protected)
        % Number of columns or rows ("elements") minus number of intervals
        % of width SampleSpacingInWorldX or SampleSpacingInWorldY. Equal to
        % both:
        %
        %   R.RasterSize(2) - intervalsInX
        %   R.RasterSize(1) - intervalsInY
        %
        % where:
        %
        %   intervalsInX = R.RasterExtentInWorldX / R.SampleSpacingInWorldX
        %   intervalsInY = R.RasterExtentInWorldY / R.SampleSpacingInWorldY
        ElementsMinusIntervals = 1;
    end
    
    %------------------ Add in SampleSpacing properties -------------------
    
    properties (Dependent)
        % SampleSpacingInWorldX Extent in world X of individual cells
        %
        %     Distance between the eastern and western limits of a single
        %     raster cell. The value is aways positive, and is the same for
        %     all cells in the raster.
        SampleSpacingInWorldX
        
        % SampleSpacingInWorldY Extent in world Y of individual cells
        %
        %     Distance between the northern and southern limits of a single
        %     raster cell. The value is aways positive, and is the same for
        %     all cells in the raster.
        SampleSpacingInWorldY
    end
    
    methods
        function spacing = get.SampleSpacingInWorldX(R)
            spacing = abs(R.Transformation.deltaX());
        end
        
        
        function spacing = get.SampleSpacingInWorldY(R)
            spacing = abs(R.Transformation.deltaY());
        end
        
        
        function R = set.SampleSpacingInWorldX(R, spacing)
            fname = 'map.rasterref.MapCellsReference.set.SampleSpacingInWorldX';
            validateattributes(spacing, {'double'}, ...
                {'real','scalar','finite','positive'}, fname, 'SampleSpacingInWorldX')
            R = setAbsoluteDeltaX(R, spacing);
        end
        
        
        function R = set.SampleSpacingInWorldY(R, spacing)
            fname = 'map.rasterref.MapCellsReference.set.SampleSpacingInWorldY';
            validateattributes(spacing, {'double'}, ...
                {'real','scalar','finite','positive'}, fname, 'SampleSpacingInWorldY')
            R = setAbsoluteDeltaY(R, spacing);
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
            % map.rasterref.MapPostingsReference object and use a
            % protected superclass method to reset its defining properties.
            R = map.rasterref.MapPostingsReference;
            R = restoreFromStructure(R,S);
        end
        
    end

    %--------------------------- Construction -----------------------------
    
    methods
        
        function R = MapPostingsReference(rasterSize, firstCornerX, ...
                firstCornerY, jacobianNumerator, jacobianDenominator)
            %   R = map.rasterref.MapPostingsReference(rasterSize, ...
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
            %        = size(RGB) where RBG is an RGB image, the rasterSize
            %        will have the form [M N 3] and the RasterSize property
            %        will be set to [M N].  M and N must be strictly
            %        positive.
            %
            %     firstCornerX, firstCornerY -- Scalar values
            %        defining the world X and world Y position of the
            %        firs sample (1,1) in the raster.
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
            
            % Superclass constructor initializes intrinsic and transient
            % properties.
            if nargin == 0
                rasterSize = [2 2];
            end
            R = R@map.rasterref.MapRasterReference(rasterSize);

            if nargin == 0
                % Construct rectilinear transformation object.
                R.Transformation = map.rasterref.internal.RectilinearTransformation;
                
                % Set default tie points to be consistent with a 2-by-2
                % grid, 2-by-2 in world units, with its first corner at
                % xWorld = 0.5, yWorld = 0.5, and maintain an identity
                % transformation between the two systems.
                R.Transformation.TiePointIntrinsic = [  1;   1];
                R.Transformation.TiePointWorld     = [0.5; 0.5];
                
                % Set Jacobian matrix to be the 2-by-2 identity matrix.
                R.Transformation.Jacobian = struct( ...
                    'Numerator', [2 0; 0 2], 'Denominator', [1 1; 1 1]);
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
                'SampleSpacingInWorldX'
                'SampleSpacingInWorldY'
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
            
            % Override the format for the SampleSpacingInWorldX property,
            % if it would be more informative to display a ratio than a
            % decimal number.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    deltaNumerator(1), deltaDenominator(1))
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'SampleSpacingInWorldX', ...
                    abs(deltaNumerator(1)), deltaDenominator(1));
            end
            
            % Likewise for the SampleSpacingInWorldY property.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    deltaNumerator(2), deltaDenominator(2))
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'SampleSpacingInWorldY', ...
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

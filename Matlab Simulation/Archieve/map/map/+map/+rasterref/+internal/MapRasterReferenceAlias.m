classdef MapRasterReferenceAlias
% Abstract class with aliases to give the map raster reference classes
% backward compatibility with respect to spatialref.MapRasterReference
% class in R2011a-R2013a. This class allows us to keep the extra code
% needed for compatibility out of the main class definition files.  All
% that is needed is for the map raster raster reference classes to inherit
% from this class, and for the maprasterref function to allow use of
% XLimWorld and YLimWorld in name-value pairs.

% Copyright 2013 The MathWorks, Inc.
    
    
    %-------------------- Intrinsic Limit Properties ----------------------
    
    properties (Abstract, SetAccess = protected, Transient)
        % Public properties in R2013b and later
        XIntrinsicLimits
        YIntrinsicLimits
    end
    
    properties (Dependent, SetAccess = private, Hidden)
        XLimIntrinsic  % Alias for XIntrinsicLimits
        YLimIntrinsic  % Alias for YIntrinsicLimits
    end
    
    methods
        function limits = get.XLimIntrinsic(R)
            limits = R.XIntrinsicLimits;
        end
        
        function limits = get.YLimIntrinsic(R)
            limits = R.YIntrinsicLimits;
        end
    end
    
    %---------------------- World Limit Properties ------------------------
    
    properties (Abstract, Dependent)
        % Public properties in R2013b and later
        XWorldLimits
        YWorldLimits
    end
    
    properties (Dependent, Hidden)
        XLimWorld  % Alias for XWorldLimits
        YLimWorld  % Alias for YWorldLimits
    end
    
    methods
        function limits = get.XLimWorld(R)
            limits = R.XWorldLimits;
        end
        
        function limits = get.YLimWorld(R)
            limits = R.YWorldLimits;
        end
        
        function R = set.XLimWorld(R,limits)
            R.XWorldLimits = limits;
        end
        
        function R = set.YLimWorld(R,limits)
            R.YWorldLimits = limits;
        end
    end
    
    %--------------------- Raster Extent Properties -----------------------
    
    properties (Abstract, Dependent, SetAccess = private)
        % Public properties in R2013b and later
        RasterExtentInWorldX
        RasterExtentInWorldY
    end
    
    properties (Dependent, SetAccess = private, Hidden)
        RasterWidthInWorld  % Alias for RasterExtentInWorldX
        RasterHeightInWorld % Alias for RasterExtentInWorldY
    end
    
    methods
        function width = get.RasterWidthInWorld(R)
            width = R.RasterExtentInWorldX;
        end
        
        function height = get.RasterHeightInWorld(R)
            height = R.RasterExtentInWorldY;
        end
    end
    
    %------------------------ Delta Properties ----------------------------
    
    properties (Abstract, Access = protected, Hidden)
        Transformation
    end
    
    properties (Dependent, SetAccess = private, Hidden = true)
        DeltaX
        DeltaY
    end
    
    methods
        function dx = get.DeltaX(R)
            dx = deltaX(R.Transformation);
        end
        
        function dy = get.DeltaY(R)
            dy = deltaY(R.Transformation);
        end
    end
    
    %------------ Transformation to Discrete Rows and Columns -------------
    
    methods (Abstract)
        [row, col] = worldToDiscrete(R, xWorld, yWorld)
    end
    
    methods (Hidden)
        function [row, col] = worldToSub(R, xWorld, yWorld)
            [row, col] = worldToDiscrete(R, xWorld, yWorld);
        end
    end
    
end

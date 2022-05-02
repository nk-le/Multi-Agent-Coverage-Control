classdef GeographicRasterReferenceAlias
% Abstract class with aliases to give the geographic raster reference
% classes backward compatibility with respect to the
% spatialref.GeoRasterReference class in R2011a-R2013a. This class allows
% us to keep the extra code needed for compatibility out of the new class
% definition files.  All that is needed is to inherit from this class, and
% for the georasterref function to continue to allow use of Latlim and
% Lonlim in name-value pairs.

% Copyright 2013 The MathWorks, Inc.
        
    %-------------------- Intrinsic Limit Properties ----------------------
    
    properties (Abstract, SetAccess = protected, Transient = true)
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

    %------------------- Geographic Limit Properties ----------------------
 
    properties (Abstract, Dependent)
        % Public properties in R2013b and later
        LatitudeLimits
        LongitudeLimits
    end
    
    properties (Dependent, Hidden)
        Latlim   % Alias for LatitudeLimits
        Lonlim   % Alias for LongitudeLimits
    end
    
    methods
        function limits = get.Latlim(R)
            limits = R.LatitudeLimits;
        end
        
        function limits = get.Lonlim(R)
            limits = R.LongitudeLimits;
        end
        
        function R = set.Latlim(R,latlim)
            R.LatitudeLimits = latlim;
        end
        
        function R = set.Lonlim(R,lonlim)
            R.LongitudeLimits = lonlim;
        end
    end
    
    %------------------------ Delta Properties ----------------------------

    properties (Abstract, Access = protected)
        DeltaLatitudeNumerator
        DeltaLatitudeDenominator
        DeltaLongitudeNumerator
        DeltaLongitudeDenominator
    end
    
    properties (Dependent, SetAccess = private, Hidden = true)
        DeltaLat
        DeltaLon
    end
    
    methods
        function delta = get.DeltaLat(R)
            delta = R.DeltaLatitudeNumerator / R.DeltaLatitudeDenominator;
        end
                
        function delta = get.DeltaLon(R)
            delta = R.DeltaLongitudeNumerator / R.DeltaLongitudeDenominator;
        end
    end
    
    %----------------------- AngleUnits Property --------------------------

    properties (Constant)
        AngleUnits = 'degrees';
    end
    
    %------------ Transformation to Discrete Rows and Columns -------------
    
    methods (Abstract)
        [row, col] = geographicToDiscrete(R, lat, lon)
    end
    
    methods (Hidden)        
        function [row, col] = geographicToSub(R, lat, lon)
           [row, col] = geographicToDiscrete(R, lat, lon);
        end        
    end
        
end

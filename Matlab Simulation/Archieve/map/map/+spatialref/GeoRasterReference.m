classdef (Sealed = true) GeoRasterReference
%spatialref.GeoRasterReference Reference raster to geographic coordinates 
%
%   The spatialref.GeoRasterReference class is no longer available. Use the
%   georasterref function instead, unless you need the 9-argument syntax
%   that spatialref.GeoRasterReference supported. In that case, invoke one
%   of the following directly:
%
%   map.rasterref.GeographicCellsReference/GeographicCellsReference
%   map.rasterref.GeographicPostingsReference/GeographicPostingsReference
%
%   but omit the rasterInterpretation and angleUnit inputs.

% Copyright 2010-2013 The MathWorks, Inc.

    methods (Static, Hidden)
        
        function R = loadobj(S)
            % Enable objects saved in R2013a and earlier releases to be
            % loaded as map.rasterref.GeographicRasterReference objects.
            if isfield(S,'Intrinsic')
                % The object was saved from R2012b or earlier:
                %   Convert S to a struct that matches the R2013a
                %   spatialref.GeoRasterReference saveobj output.
                S = struct( ...
                    'RasterSize', S.Intrinsic.RasterSize, ...
                    'RasterInterpretation',  S.Intrinsic.RasterInterpretation, ...
                    'FirstCornerLatitude',   S.FirstCornerLat, ...
                    'FirstCornerLongitude',   S.FirstCornerLon, ...
                    'DeltaLatitudeNumerator',    S.DeltaLatNumerator, ...
                    'DeltaLatitudeDenominator' , S.DeltaLatDenominator, ...
                    'DeltaLongitudeNumerator',   S.DeltaLonNumerator, ...
                    'DeltaLongitudeDenominator', S.DeltaLonDenominator);
            end
            
            % Use the fact that the R2013a spatialref.GeoRasterReference
            % saveobj method returns a structure that is accepted by the
            % R2013b geographic raster reference loadobj methods.
            if strcmp(S.RasterInterpretation,'cells')
                R = map.rasterref.GeographicCellsReference.loadobj(S);
            elseif strcmp(S.RasterInterpretation,'postings')
                R = map.rasterref.GeographicPostingsReference.loadobj(S);
            else
                validatestring(S.RasterInterpretation, {'cells','postings'})
            end
        end
        
    end
    
    methods
        
        function R = GeoRasterReference(varargin)
            % Disable the spatialref.GeoRasterReference constructor, and
            % give a message that directs users to georasterref.
            error(message('map:removed:spatialrefGeoRasterReference', ...
                'spatialref.GeoRasterReference', 'georasterref'))
        end
        
    end
end

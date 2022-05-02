classdef (Sealed = true) MapRasterReference
%spatialref.MapRasterReference Reference raster to map coordinates 
%
%   The spatialref.MapRasterReference class is no longer available. Use the
%   maprasterref function instead, unless you need the 7-argument syntax
%   that spatialref.MapRasterReference supported. In that case, invoke one
%   of the following directly:
%
%      map.rasterref.MapCellsReference/MapCellsReference
%      map.rasterref.MapPostingsReference/MapPostingsReference
%
%   but omit the rasterInterpretation and lengthUnit inputs.

% Copyright 2010-2013 The MathWorks, Inc.
    
    methods (Static, Hidden)
        
        function R = loadobj(S)
            % Enable objects saved in R2013a and earlier releases to be
            % loaded as map raster reference objects.
            if isfield(S,'Intrinsic')
                % The object was saved from R2012b or earlier:
                %   Convert S to a struct that matches the R2013a
                %   spatialref.MapRasterReference saveobj output.
                T = S.Transformation;
                
                S = struct( ...
                    'RasterSize',           S.Intrinsic.RasterSize, ...
                    'RasterInterpretation', S.Intrinsic.RasterInterpretation, ...
                    'TransformationType',   T.TransformationType, ...
                    'TiePointIntrinsic',    T.TiePointIntrinsic, ...
                    'TiePointWorld',        T.TiePointWorld);
                
                if strcmp(S.TransformationType,'rectilinear')
                    S.DeltaNumerator   = T.DeltaNumerator;
                    S.DeltaDenominator = T.DeltaDenominator;
                else
                    % TransformationType is 'affine'
                    S.Jacobian = struct( ...
                        'Numerator',T.pJacobian,'Denominator',[1 1; 1 1]);
                end
            end
            
            % Use the fact that the R2013a spatialref.MapRasterReference
            % saveobj method returns a structure that is accepted by the
            % R2013b map raster reference loadobj methods.
            if strcmp(S.RasterInterpretation,'cells')
                R = map.rasterref.MapCellsReference.loadobj(S);
            elseif strcmp(S.RasterInterpretation,'postings')
                R = map.rasterref.MapPostingsReference.loadobj(S);
            else
                validatestring(S.RasterInterpretation, {'cells','postings'})
            end
        end
        
    end
    
    methods
        
        function R = MapRasterReference(varargin)
            % Disable the spatialref.MapRasterReference constructor, and
            % give a message that directs users to maprasterref.
            error(message('map:removed:spatialrefMapRasterReference', ...
                'spatialref.MapRasterReference', 'maprasterref'))
        end
        
    end
end

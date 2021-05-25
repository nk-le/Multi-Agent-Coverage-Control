classdef RectilinearTransformation
% Stub class that enables load for spatialref.MapRasterReference objects
% saved in R2012b and earlier releases.

% Copyright 2010-2013 The MathWorks, Inc.

    properties (Constant)
        TransformationType = 'rectilinear';
    end
    
    properties
        TiePointIntrinsic
        TiePointWorld
        DeltaNumerator
        DeltaDenominator
    end
    
    methods (Static)
        function T = loadobj(T)
        end
    end
    
    methods (Access = private)
        function self = RectilinearTransformation(~,~)
            % Ensure that instances of this class cannot be constructed.
        end
    end
end

classdef AffineTransformation
% Stub class that enables load for spatialref.MapRasterReference objects
% saved in R2012b and earlier releases.

% Copyright 2010-2013 The MathWorks, Inc.

    properties (Constant)
        TransformationType = 'affine';
    end
    
    properties
        TiePointIntrinsic
        TiePointWorld
        pJacobian
        invJacobian
    end
    
    methods (Static)
        function T = loadobj(T)
        end
    end
    
    methods (Access = private)
        function self = AffineTransformation(~,~)
            % Ensure that instances of this class cannot be constructed.
        end
    end
end

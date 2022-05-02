%Affine Transformation Intrinsic-world affine transformation
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   Encapsulate all transformation-specific spatial referencing
%   computations for the case of a affine transformation. This class
%   has the same signature (properties and methods) as the
%   map.rasterref.internal.RectilinearTransformation class.

% Copyright 2010-2013 The MathWorks, Inc.

classdef (Sealed = true) AffineTransformation
    
    %----------------------- Public properties -------------------------
    
    properties
        TiePointIntrinsic = [0; 0];
        TiePointWorld = [0; 0];
    end
    
    properties (Dependent)
        %Jacobian  Rational representation of Jacobian matrix
        %
        %   Jacobian is a scalar structure with fields Numerator and
        %   Denominator, which hold 2-by-2 matrices. When
        %   Jacobian.Numerator is divided element-wise by
        %   Jacobian.Denominator, the result is a 2-by-2 Jacobian matrix
        %   with a non-zero determinant.
        Jacobian
    end
    
    properties (Constant)
        TransformationType = 'affine';
    end
    
    %----------------------- Private properties -------------------------
    
    properties (Access = private)
        % Jacobian matrix
        pJacobian = [1 0; 0 1];
        
        % Inverse of Jacobian matrix -- We'd make this property transient,
        % but because map raster reference objects don't save their
        % internal objects, we don't expect to have to ever load an
        % instance of this class. (Hence ,if we did make invJacobian
        % transient, best practice would indicate adding a loadobj method,
        % but that method would never be invoked.)
        invJacobian = [1 1; 1 1];
    end
    
    %-------------------------- Set methods ----------------------------
    
    methods
        
        function self = set.Jacobian(self, J)
            jacobian = J.Numerator ./ J.Denominator;
            self.pJacobian = jacobian;
            self.invJacobian = inv(jacobian);
        end
        
    end
    
    %-------------------------- Get methods ----------------------------
    
    methods
        
        function J = get.Jacobian(self)
            J.Numerator = self.pJacobian;
            J.Denominator = [1 1; 1 1];
        end
    end
    
    %----------------------- Ordinary methods --------------------------
    
    methods
        
        function [xw, yw] = intrinsicToWorld(self, xi, yi)
            %intrinsicToWorld Convert from intrinsic to world coordinates
            
            % The following operations combine xi and yi with scalar
            % values only; the input coordinate arrays can have any shape.
            
            xi = xi - self.TiePointIntrinsic(1);
            yi = yi - self.TiePointIntrinsic(2);
            
            J = self.pJacobian;
            xw = J(1,1) * xi + J(1,2) * yi;
            yw = J(2,1) * xi + J(2,2) * yi;
            
            xw = xw + self.TiePointWorld(1);
            yw = yw + self.TiePointWorld(2);
        end
        
        
        function [xi, yi] = worldToIntrinsic(self, xw, yw)
            %worldToIntrinsic Convert from world to intrinsic coordinates
            
            % The following operations combine xw and yw with scalar
            % values only; the input coordinate arrays can have any shape.
            
            xw = xw - self.TiePointWorld(1);
            yw = yw - self.TiePointWorld(2);
            
            invJ = self.invJacobian;
            xi = invJ(1,1) * xw + invJ(1,2) * yw;
            yi = invJ(2,1) * xw + invJ(2,2) * yw;
            
            xi = xi + self.TiePointIntrinsic(1);
            yi = yi + self.TiePointIntrinsic(2);
        end
        
        
        function J = jacobianMatrix(self)
            % Jacobian matrix of the transformation
            J = self.pJacobian;
        end
        
        
        function dx = deltaX(self)
            % Length of the offset vector J(:,1).
            % This vector indicates the change in position, in the
            % world system, associated with a move from the point
            % (xi, yi) to the point (xi + 1, yi) in the intrinsic system
            % (moving over by one column).
            J = self.pJacobian;
            dx = hypot(J(1,1), J(2,1));
        end
        
        
        function dy = deltaY(self)
            % Length of the offset vector J(:,2).
            % This vector indicates the change in position, in the
            % world system, associated with a move from the point
            % (xi, yi) to the point (xi, yi + 1) in the intrinsic system
            % (moving over by one column).
            J = self.pJacobian;
            dy = hypot(J(1,2), J(2,2));
        end
        
        
        function [deltaNumerator, deltaDenominator] = rationalDelta(self)
            deltaNumerator = [self.deltaX(); self.deltaY()];
            deltaDenominator = [1; 1];
        end
        
    end
    
end

%RectilinearTransformation Intrinsic-world rectilinear transformation
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   Encapsulate all transformation-specific spatial referencing
%   computations for the case of a rectilinear transformation. This
%   class has the same signature (properties and methods) as the
%   map.rasterref.internal.AffineTransformation class.

% Copyright 2010-2013 The MathWorks, Inc.

classdef (Sealed = true) RectilinearTransformation
    
    %----------------------- Public properties -------------------------
    
    properties
        TiePointIntrinsic = [0; 0];
        TiePointWorld     = [0; 0];
    end
    
    properties (Dependent)
        % Jacobian  Rational representation of Jacobian matrix
        %
        %   Jacobian is a scalar structure with fields Numerator and
        %   Denominator, which hold 2-by-2 matrices. When
        %   Jacobian.Numerator is divided element-wise by
        %   Jacobian.Denominator, the result is a 2-by-2 Jacobian matrix
        %   with a non-zero determinant.
        Jacobian
    end
    
    properties (Constant)
        TransformationType = 'rectilinear';
    end
    
    %-------------------- Internal use properties ----------------------
    
    % The following properties would be private, except that we need to be
    % able to get them at save time and set them at load time, in order to
    % bypass simplifyRatio, which could change behavior in a future
    % release. These should be used only in saveobj and loadobj methods.
    
    properties (Hidden)
        % Numerator of rational representation of diagonal Jacobian matrix
        DeltaNumerator   = [1; 1]
        
        % Denominator of rational representation of diagonal Jacobian matrix
        DeltaDenominator = [1; 1]
    end
    
    %-------------------------- Set methods ----------------------------
    
    methods
        
        function self = set.Jacobian(self, J)
            N = J.Numerator;
            D = J.Denominator;
            [N,D] = arrayfun(@map.rasterref.internal.simplifyRatio, N, D);
            self.DeltaNumerator = diag(N);
            self.DeltaDenominator = diag(D);
        end
        
    end
    
    %-------------------------- Get methods ----------------------------
    
    methods
        
        function J = get.Jacobian(self)
            J.Numerator = diag(self.DeltaNumerator);
            J.Denominator ...
                = [self.DeltaDenominator(1) 1; 1 self.DeltaDenominator(2)];
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
            
            xw = xi .* self.DeltaNumerator(1) ./ self.DeltaDenominator(1);
            yw = yi .* self.DeltaNumerator(2) ./ self.DeltaDenominator(2);
            
            xw = xw + self.TiePointWorld(1);
            yw = yw + self.TiePointWorld(2);
        end
        
        
        function [xi, yi] = worldToIntrinsic(self, xw, yw)
            %worldToIntrinsic Convert from world to intrinsic coordinates
            
            % The following operations combine xw and yw with scalar
            % values only; the input coordinate arrays can have any shape.
            
            xw = xw - self.TiePointWorld(1);
            yw = yw - self.TiePointWorld(2);
            
            xi = xw .* self.DeltaDenominator(1) ./ self.DeltaNumerator(1);
            yi = yw .* self.DeltaDenominator(2) ./ self.DeltaNumerator(2);
            
            xi = xi + self.TiePointIntrinsic(1);
            yi = yi + self.TiePointIntrinsic(2);
        end
        
        
        function J = jacobianMatrix(self)
            % Jacobian matrix of the transformation
            J = diag(self.DeltaNumerator ./ self.DeltaDenominator);
        end
        
        
        function dx = deltaX(self)
            % Change in X world with respect to X intrinsic
            dx = self.DeltaNumerator(1) / self.DeltaDenominator(1);
        end
        
        
        function dy = deltaY(self)
            % Change in Y world with respect to Y intrinsic
            dy = self.DeltaNumerator(2) / self.DeltaDenominator(2);
        end
        
        
        function [deltaNumerator, deltaDenominator] = rationalDelta(self)
            deltaNumerator = self.DeltaNumerator;
            deltaDenominator = self.DeltaDenominator;
        end
        
    end
end

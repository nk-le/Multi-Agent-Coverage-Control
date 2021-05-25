function R = referencingMatrix(W)
%Construct referencing matrix from world file maxtrix
%
%   R = referencingMatrix(W) returns the 3x2 referencing matrix
%   corresponding to the 2x3 world file matrix, W.

% Copyright 2020 The MathWorks, Inc.

% World File Matrix to Referencing Matrix Conversion
% --------------------------------------------------
% An affine transformation that is expressed like this in terms of a world
% file matrix:
%
%               [xw yw]' = W * [(xi - 1) (yi - 1) 1]' 
%
% is expressed as:
%
%                     [xw yw] = [yi xi 1] * R
%
% in terms of a referencing matrix R, To obtain R from W, note that
%
%                   [xi-1 yi-1 1]' = C * [yi xi 1]',
%
% where
% 
%                         C = [0  1  -1
%                              1  0  -1
%                              0  0   1].
% 
% Therefore [xw yw]' = W * C * [yi xi 1]'.  Transposing both sides gives
% 
%                     [xw yw] = [yi xi 1] * R
% with
%                           R = (W * C)'.

% Referencing Matrix to World File Matrix Conversion
% --------------------------------------------------
% To reverse the conversion and create a world file from R, use
% 
%                          W = R' * inv(C)
% 
% and
% 
%                     inv(C) = [0  1  1
%                               1  0  1
%                               0  0  1].

    arguments
        W (2,3) {mustBeNumeric, mustBeReal}
    end
    
    W = double(W);
    
    C = [0  1  -1;...
         1  0  -1;...
         0  0   1];
    
    R = (W * C)';
end

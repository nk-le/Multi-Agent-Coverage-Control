function RGB = ind2rgb8(X, CMAP)
%IND2RGB8 Convert indexed image to uint8 RGB image
%
%   RGB = IND2RGB8(X,CMAP) creates a truecolor RGB image of class uint8.
%   X must be uint8, uint16, uint32, or double, and CMAP must be a valid
%   MATLAB colormap.
%
%   Example 
%   -------
%   % Convert the 'concord_ortho_e.tif' image to RGB.
%   [X,cmap] = imread('concord_ortho_e.tif');
%   R = worldfileread('concord_ortho_e.tfw','planar',size(X));
%   RGB = ind2rgb8(X, cmap);
%   mapshow(RGB, R);
%
%   See also IND2RGB.

% Copyright 1996-2020 The MathWorks, Inc.

RGB = matlab.images.internal.ind2rgb8(X, CMAP);

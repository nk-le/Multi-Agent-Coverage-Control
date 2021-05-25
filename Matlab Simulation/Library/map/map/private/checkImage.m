function RGB = checkImage(mapfilename, A, cmap, imagePos, cmapPos, R)
%CHECKIMAGE Check image inputs
%
%   RGB = checkImage(MAPFILENAME, A, CMAP, imagePos, cmapPos) validates the
%   image input, A. If A is not an RGB image, then A is converted to a an
%   RGB image of type uint8, if CMAP is nonempty, or by replicating the
%   matrix. If A is logical it is converted to uint8. imagePos and cmapPos
%   are the position numbers in the command line for the arguments.
%
%   RGB = checkImage(__, R) validates R.RasterSize with the size of A.

% Copyright 2010-2018 The MathWorks, Inc.

if islogical(A)
   u = uint8(A);
   u(A) = 255;
   A = u;
end

if nargin == 6 && (isobject(R) && isprop(R,'RasterSize'))
    expectedSize = [R.RasterSize, NaN];
else
    expectedSize = size(A);
end

varname = 'I or X or RGB';
if ~isempty(cmap)
    internal.map.checkcmap(cmap, mapfilename, 'CMAP', cmapPos);
    attributes = {'2d', 'real', 'nonsparse', 'nonempty', 'size', expectedSize};
    validateattributes(A, {'numeric'}, attributes, mapfilename, varname, ...
        imagePos);
    A =  matlab.images.internal.ind2rgb8(A, cmap);
else
    attributes = {'real', 'nonsparse', 'nonempty', 'size', expectedSize};
    validateattributes(A, {'numeric'}, attributes, mapfilename, varname, ...
        imagePos);
    
    if ismatrix(A)
        A = repmat(A,[1 1 3]);
    elseif ndims(A) ~= 3
        error(sprintf('map:%s:invalidImageDimension', mapfilename), ...
            'Image dimension must be 2 or 3.')
    end   
end
RGB = checkRGBImage(A);

%--------------------------------------------------------------------------

function RGB = checkRGBImage(RGB)

% RGB images can be only uint8, uint16, or double
if ~isa(RGB, 'double') && ...
      ~isa(RGB, 'uint8')  && ...
      ~isa(RGB, 'uint16')
   error(sprintf('map:%s:invalidRGBClass', mfilename), ...
       'RGB images must be uint8, uint16, or double.')
end

if size(RGB,3) ~= 3
   error(sprintf('map:%s:invalidRGBSize', mfilename), ...
       'RGB images must be size M-by-N-by-3.')
end

% Clip double RGB images to [0 1] range
if isa(RGB, 'double')
   RGB(RGB < 0) = 0;
   RGB(RGB > 1) = 1;
end

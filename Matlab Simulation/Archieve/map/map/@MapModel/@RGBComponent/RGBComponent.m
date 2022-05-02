function this = RGBComponent(R,I,attributes)
%RGBCOMPONENT Constructor for a RGB component.
%
%   RGBCOMPONENT(R,I) constructs an RGBComponent from the referencing matrix R
%   and the RGB image I.  I must be an m-by-n-by-3 data array that defines red,
%   green, and blue color components for each individual pixel.

%   Copyright 1996-2020 The MathWorks, Inc.

this = MapModel.RGBComponent;

if (ndims(I) ~= 3) || ~isnumeric(I)
   error('map:RGBComponent:invalidImage', ...
      'The RGB image must be an m-by-n-3 numeric data array.');
end

if ~all(size(R) == [3 2]) || ~isnumeric(R)
   error('map:RGBComponent:invalidRefMat', ...
      'The referencing matrix must be a 3-by-2 numeric array.');
end

if isa(I,'double') && (min(I(:)) <0 || max(I(:)) > 1)
   error('map:RGBComponent:imageElementsOutsideRange', ...
      'The RGB image contains elements outside the range 0.0 <= value <= 1.0.')
end

this.ReferenceMatrix = R;
this.ImageData = I;
this.BoundingBox = MapModel.BoundingBox(R,size(I));
this.Attributes = attributes;

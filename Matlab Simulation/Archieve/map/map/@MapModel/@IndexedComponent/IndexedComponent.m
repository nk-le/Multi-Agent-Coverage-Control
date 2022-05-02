function h = IndexedComponent(R,I,varargin)
%INDEXEDCOMPONENT Constructor for a RGB component.
%
%   INDEXEDCOMPONENT(R,I,MAP) constructs an object to store a spatially
%   referenced Indexed Image from the referencing matrix R, the image I, and the
%   colormap MAP.  An indexed image is a data matrix, I, whose values represent
%   indices into a colormap.

% Copyright 1996-2020 The MathWorks, Inc.

h = MapModel.IndexedComponent;

if ~ismatrix(I)
  error(['map:' mfilename ':mapError'], 'I must be a M-by-N data array.')
end

h.ReferenceMatrix = R;
h.ImageData = I;
if nargin == 3
  h.Colormap = varargin{3};
else
  h.Colormap = jet(64);
end
  
h.BoundingBox = MapModel.BoundingBox(R,size(I));

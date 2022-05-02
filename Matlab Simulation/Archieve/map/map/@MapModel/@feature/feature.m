function h = feature(xdata,ydata,boundingBox,attributes)
% FEATURE Construct a feature object.
%
%   FEATURE(XDATA,YDATA,BOUNDINGBOX,ATTRIBUTES) constructs a feature object
%   with coordinates XDATA, YDATA and attributes ATTRIBUTES. Bounding box
%   must be a position vector [x y width height].

% Copyright 1996-2007 The MathWorks, Inc.

h = MapModel.feature;

if length(xdata) ~= length(ydata)
  error(['map:' mfilename ':mapError'], ...
      'XDATA and YDATA must be the same length')
end

h.XData = xdata;
h.YData = ydata;

h.BoundingBox = MapModel.BoundingBox(boundingBox);

if ~isempty(attributes)
  h.Attributes = attributes;
else
  h.Attributes = struct([]);
end

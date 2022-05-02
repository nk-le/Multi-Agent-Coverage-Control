function checkboundingbox(...
               bbox, function_name, variable_name, argument_position)
%CHECKBOUNDINGBOX Check validity of bounding box array.
%   CHECKBOUNDINGBOX(...
%              BBOX, FUNCTION_NAME, VARIABLE_NAME, ARGUMENT_POSITION)
%   ensures that the bounding box array is a 2-by-2 array of double with
%   real, finite values, and that in each column the second value always
%   exceeds the first.

% Copyright 1996-2011 The MathWorks, Inc.

validateattributes(bbox, {'double'}, {'2d', 'real','nonnan', 'size', [2,2]},...
   function_name,variable_name,argument_position);

if ~all(bbox(1,:) <= bbox(2,:))
    error(message('map:shapefile:invalidBBoxOrder',  ...
        upper(function_name), num2str(argument_position), variable_name));
end

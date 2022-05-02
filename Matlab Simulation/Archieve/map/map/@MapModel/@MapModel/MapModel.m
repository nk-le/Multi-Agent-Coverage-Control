function h = MapModel(id)
%MAPMODEL Construct a mapmodel object.
%
%   H = MAPMODEL constructs a MapModel object.
%

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.MapModel;
h.Configuration = {};
h.ViewerCount = [];
if nargin == 0
    h.ModelId = 0;
else
    h.ModelId = id;
end






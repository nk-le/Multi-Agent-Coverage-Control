function makemapped(h)
%MAKEMAPPED Convert ordinary graphics object to mapped object
%
% MAKEMAPPED will be removed in a future release.
%
% MAKEMAPPED(h) adds a Mapping Toolbox structure to the displayed objects 
% associated with h. h can be a handle, vector of handles, or any name string
% recognized by HANDLEM. The objects are then considered to be geographic 
% data. Objects extending outside the map frame should first be trimmed to the 
% map frame using TRIMCART.

% Copyright 1996-2013 The MathWorks, Inc.

narginchk(1,1)
if ischar(h) 
    h = handlem(h);
end

if ~ishghandle(h)
   error(message('map:validate:expectedHGHandles','H'))
end

% ensure vectors
h = h(:);

% Remove objects from the list that are already mapped
lengthin = length(h);
for i=length(h):-1:1
	if ismapped(h(i)); h(i) = []; end 
end

% Warn about them
if ~isequal(length(h), lengthin)
	warning(message('map:makemapped:objectAlreadyMapped'))
end

% Add a mapping toolbox object structure
set(h,'UserData',struct('trimmed',[],'clipped',[]), ...
    'ButtonDownFcn',@uimaptbx);

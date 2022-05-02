function schema
% Define the LayerOrderChangedEvent

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('LayerEvent');
cEventData = findclass(findpackage('handle'),'EventData');

c = schema.class(pkg,'LayerOrderChanged',cEventData);

p = schema.prop(c,'layerorder','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

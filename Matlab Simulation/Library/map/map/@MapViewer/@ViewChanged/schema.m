function schema
% Define the ViewChanged class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapViewer');
cEventData = findclass(findpackage('handle'),'EventData');

c = schema.class(pkg,'ViewChanged',cEventData);

p = schema.prop(c,'prevXLim','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

p = schema.prop(c,'prevYLim','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

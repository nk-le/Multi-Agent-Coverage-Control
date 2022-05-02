function schema

%SCHEMA Schema for DataTipState class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapViewer');
c = schema.class(pkg,'InfoToolState');

p = schema.prop(c,'InfoBoxHandles','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'on';

p = schema.prop(c,'Viewer','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

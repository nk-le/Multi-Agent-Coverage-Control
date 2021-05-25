function schema
%

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapViewer');
c = schema.class(pkg,'InsertTextState');

p = schema.prop(c,'MapViewer','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

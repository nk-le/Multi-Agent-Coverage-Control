function schema
%SCHEMA Define BoundingBox class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');

c = schema.class(pkg,'BoundingBox');

p = schema.prop(c,'Corners','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

p = schema.prop(c,'PositionVector','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';


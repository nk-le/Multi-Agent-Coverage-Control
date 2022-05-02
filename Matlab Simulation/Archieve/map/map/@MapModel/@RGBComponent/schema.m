function schema
%SCHEMA Define the RGBComponent class.

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');
c = schema.class(pkg,'RGBComponent',findclass(pkg,'RasterComponent'));

p = schema.prop(c,'Attributes','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

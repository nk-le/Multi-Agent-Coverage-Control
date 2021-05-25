function schema
% Define the mapmodel class

%   Copyright 1996-2009 The MathWorks, Inc.

% The mapmodel class is in the mapmodel package
pk = findpackage('MapModel');

% Create the class
c = schema.class(pk,'MapModel');

p = schema.prop(c,'Layers','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';
p.FactoryValue = [];

p = schema.prop(c,'Configuration','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'on';

p = schema.prop(c,'ModelId','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'off';

p = schema.prop(c,'ViewerCount','MATLAB array');
p.AccessFlags.PrivateGet = 'on';
p.AccessFlags.PrivateSet = 'on';
p.AccessFlags.PublicGet  = 'on';
p.AccessFlags.PublicSet  = 'on';

e = schema.event(c,'LayerAdded');
e = schema.event(c,'LayerRemoved');
e = schema.event(c,'LayerOrderChanged');
e = schema.event(c,'ShowBoundingBox');
e = schema.event(c,'Visible');

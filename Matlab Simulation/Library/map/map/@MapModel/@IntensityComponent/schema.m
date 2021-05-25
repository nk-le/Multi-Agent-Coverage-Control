function schema
%SCHEMA Define the IntensityComponent class.

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');
c = schema.class(pkg,'IntensityComponent',findclass(pkg,'RasterComponent'));

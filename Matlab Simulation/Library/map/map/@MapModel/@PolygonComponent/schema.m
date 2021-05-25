function schema
%SCHEMA Define the PolygonComponent class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');
c = schema.class(pkg,'PolygonComponent',findclass(pkg,'VectorComponent'));


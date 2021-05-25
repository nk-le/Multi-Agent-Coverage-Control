function schema
%SCHEMA Define the PointComponent class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');
c = schema.class(pkg,'PointComponent',findclass(pkg,'VectorComponent'));

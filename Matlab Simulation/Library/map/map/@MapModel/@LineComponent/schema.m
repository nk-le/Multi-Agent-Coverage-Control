function schema
%SCHEMA Define the LineComponent class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');
c = schema.class(pkg,'LineComponent',findclass(pkg,'VectorComponent'));


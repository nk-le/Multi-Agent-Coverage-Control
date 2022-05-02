function schema
%SCHEMA Define the LineLayer class

%   Copyright 1996-2003 The MathWorks, Inc.

pkg = findpackage('MapModel');

% Extend the layer class
c = schema.class(pkg,'LineLayer',findclass(pkg,'layer'));


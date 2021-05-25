function h = Visible(hSrc,name,val)
%VISIBLE Event for setting Visible property.
%
%   VISIBLE(NAME,VAL) 

%   Copyright 1996-2003 The MathWorks, Inc.

h = LayerEvent.Visible(hSrc,'Visible');

h.Name = name;
h.val = val;
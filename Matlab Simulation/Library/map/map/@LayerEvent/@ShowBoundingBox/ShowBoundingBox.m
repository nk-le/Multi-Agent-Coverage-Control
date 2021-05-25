function h = ShowBoundingBox(hSrc,name,val)
%SHOWBOUNDINGBOX 
%
%   SHOWBOUNDINGBOX(NAME,VAL) 

%   Copyright 1996-2003 The MathWorks, Inc.

h = LayerEvent.ShowBoundingBox(hSrc,'ShowBoundingBox');

h.Name = name;
h.val = val;
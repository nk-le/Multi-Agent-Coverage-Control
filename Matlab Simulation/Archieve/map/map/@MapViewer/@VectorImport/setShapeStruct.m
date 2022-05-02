function setShapeStruct(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

set(this.Topology,'Enable','off');
set([this.Lat{:},this.Lon{:}],'Enable','off');
set([this.X{:},this.Y{:}],'Enable','off');
set(this.VectorTopologyText,'Enable','off');
set([this.X{2},this.Y{2}],...
    'BackgroundColor',[0.7 0.7 0.7]);
set([this.Lat{2},this.Lon{2}],...
    'BackgroundColor',[0.7 0.7 0.7]);

set([this.ShapeStruct{:}],'Enable','on');
set([this.ShapeStruct{2}],'BackgroundColor','w');

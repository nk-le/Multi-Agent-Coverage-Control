function setCartesian(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

set([this.Lat{:},this.Lon{:},this.ShapeStruct{:}],'Enable','off');
set([this.Lat{2},this.Lon{2},this.ShapeStruct{2}],...
    'BackgroundColor',[0.7 0.7 0.7]);

set([this.Topology, this.X{:},this.Y{:}],'Enable','On');
set([this.X{2},this.Y{2}],'BackgroundColor','w');
set(this.VectorTopologyText,'Enable','on');
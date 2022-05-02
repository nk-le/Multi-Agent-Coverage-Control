function [map, R] = getrmm
% Get ZData or CData and referencing object from a regular grid in the
% current map axes.

% Copyright 2010-2016 The MathWorks, Inc.

hfig = get(0,'CurrentFigure');

if isempty(hfig)
    error('map:getgrid:expectedRegularGridInAxes', ...
        'This calling form requires a map axes displaying a regular grid.')
end

haxes = get(hfig,'CurrentAxes');
if isempty(haxes)
    error('map:getgrid:expectedRegularGridInAxes', ...
        'This calling form requires a map axes displaying a regular grid.')
end

if ~ismap(haxes)
    error('map:getgrid:expectedRegularGridInAxes', ...
        'This calling form requires a map axes displaying a regular grid.')
end

mobjstruct = get(gco,'UserData');

if isfield(mobjstruct,'maplegend')
    hobj = gco;
else
    hobj = findall(haxes,'type','surface');

    if isempty(hobj)
        error('map:getgrid:expectedRegularGridInAxes', ...
            'This calling form requires a map axes displaying a regular grid.')
    end

    for i = length(hobj):-1:1
        mobjstruct = get(hobj(i),'UserData');
        if ~isfield(mobjstruct,'maplegend')
            hobj(i) = [];
        end
    end

    if isempty(hobj)
        error('map:getgrid:expectedRegularGridInAxes', ...
            'This calling form requires a map axes displaying a regular grid.')
    end

    if length(hobj) > 1
        warning('map:getgrid:multipleGridsInAxes', ...
            'More than one regular grid in map axes. Using the first one.')
        hobj = hobj(1);
    end
end

mobjstruct = get(hobj,'UserData');
R = mobjstruct.maplegend;

zdata = get(hobj,'ZData');
if max(zdata(:)) ~= min(zdata(:))
    map = zdata;
else
    map = get(hobj,'CData');
end

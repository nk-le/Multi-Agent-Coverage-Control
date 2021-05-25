function importFromFile(this,filename)
%IMPORTFROMFILE
%
%   importFromFile(FILENAME)

%   Copyright 1996-2020 The MathWorks, Inc.

data = this.getMap;
[~, name, ext] = fileparts(filename);
this.setCurrentPath(filename);

[dataArgs, ~, info] = map.graphics.internal.readMapData([],filename);

switch lower(ext)
    
    case {'.tif','.tiff','.jpg','.jpeg','.png'}
        if numel(dataArgs) == 2
            % CMAP is not in dataArgs because readMapData removes it when
            % it is empty. We need to explicitly pass it to the createLayer
            % subfunction.
            cmap = [];
            R = dataArgs{2};
        else      
            cmap = dataArgs{2};
            R = dataArgs{3};
        end
        if isobject(R)
            R = map.internal.referencingMatrix(R.worldFileMatrix());
        end
        layer = createLayer(data, name, dataArgs{1}, cmap, R, info);

    case {'.shp','.shx','.dbf'}
        shapeData = dataArgs{1};
        % Project the data if needed
        if isfield(shapeData,'Lat') && isfield(shapeData,'Lon')
            %shape = projectGeoStruct([], shape);
            [shapeData.X] = deal(shapeData.Lon);
            [shapeData.Y] = deal(shapeData.Lat);
        end
        layer = map.graphics.internal.createVectorLayer(shapeData, name);
        
    case {'.grd','.ddf'}
        layer = createGridLayer([],dataArgs{2},dataArgs{1},name,'surf');
end
this.addLayer(layer);

% Refresh pointer so that proper pointer displays. The pointer is set to
% 'arrow' when the user leaves the map axes. Without this manual refresh,
% the cursor won't update until the user moves the mouse. We want the
% cursor to be correct immediately.
iptPointerManager(this.Figure,'enable');

function layer = createLayer(map,name,I, cmap, R, Iinfo)
if isempty(cmap) && ismatrix(I) 
    % Intensity Image
    layer = createIntensityLayer(map,R,I,name);
elseif ndims(I) == 3                
    % RGB Image
    layer = createRGBLayer(map,R,I,name,Iinfo);
else
    % Indexed Image
    rgb =  matlab.images.internal.ind2rgb8(I,cmap);
    layer = createRGBLayer(map,R,rgb,name,Iinfo);
end

function newLayer = createIntensityLayer(~,R,I,name) 
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.IntensityComponent(R,I);
newLayer.addComponent(newComponent);

function newLayer = createRGBLayer(~,R,I,name,Iinfo) 
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.RGBComponent(R,I,Iinfo);
newLayer.addComponent(newComponent);

function newLayer = createGridLayer(~,R,Z,name,dispType) 
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.GriddedComponent(R,Z,dispType);
newLayer.addComponent(newComponent);

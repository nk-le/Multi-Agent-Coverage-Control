function setMapUnits(this,mapUnitsTag)
% SETMAPUNITS Set viewer's map units and adjust scale display properties.

% Copyright 2008-2013 The MathWorks, Inc.

switch mapUnitsTag
 case 'none'
  this.Axis.setMapUnitInCM(0);
  set(this.ScaleDisplay,'Enable','inactive', ...
      'String','Units Not Set', 'BackgroundColor', [0.7020 0.7020 0.7020])
 case 'km'
  this.Axis.setMapUnitInCM(100000);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'm'
  this.Axis.setMapUnitInCM(100);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'cm'
  this.Axis.setMapUnitInCM(1);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'mm'
  this.Axis.setMapUnitInCM(0.1);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'u'
  this.Axis.setMapUnitInCM(0.0001);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'nm'
  this.Axis.setMapUnitInCM(185200);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'ft'
  this.Axis.setMapUnitInCM(30.48);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'in'
  this.Axis.setMapUnitInCM(2.54);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'yd'
  this.Axis.setMapUnitInCM(91.44);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'mi'
  this.Axis.setMapUnitInCM(160934.4);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'sf'
  this.Axis.setMapUnitInCM(30.4801);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
 case 'sm'
  this.Axis.setMapUnitInCM(160934.7218694437);
  set(this.ScaleDisplay,'Enable','on','BackgroundColor','w')
end

if (this.Axis.MapUnitInCM == 0)
    set(this.ScaleDisplay,'String','Units Not Set');
else
    s = ['1:' num2str(floor(1/this.Axis.getScale))];
    set(this.ScaleDisplay,'String',s)
end

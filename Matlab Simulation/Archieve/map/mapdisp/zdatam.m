function zdatam(hndl,zdata)
%ZDATAM Adjust z-plane of displayed map objects
%
%  ZDATAM(HNDL, ZDATA) will alter the z-plane position of displayed map
%  objects designated by the MATLAB graphics handle HNDL. The z-plane
%  position may be the Z position in the case of text objects, or the ZData
%  property in the case of other graphic objects. If HNDL is an hggroup
%  handle, the ZData property of the children in the hggroup are altered.
%
%  If a scalar handle is supplied, then ZDATA can be either a scalar
%  (z-plane definition), or a matrix of appropriate dimension for the
%  displayed object.  If HNDL is a vector, then ZDATA can be a scalar or a
%  vector of the same dimension as HNDL.  If ZDATA is a scalar, then all
%  objects in HNDL are drawn on the ZDATA z-plane.  If ZDATA is a vector,
%  then each object in HNDL is drawn on the plane defined by the
%  corresponding ZDATA element. If ZDATA is omitted, then a modal dialog
%  box prompts for the ZDATA entry.
%
%  ZDATAM('str',ZDATA) identifies the objects by the input 'str', where
%  'str' is any text option recognized by HANDLEM.
%
%  ZDATAM(HNDL) and ZDATAM('str') displays a Graphical User Interface to
%  modify the ZData of the object(s) specified by the input.
%
%  ZDATAM displays a Graphical User Interface for selecting an object from
%  the current axes and modifying its ZData.
%
%  See also SETM, SET, HANDLEM.

% Copyright 1996-2017 The MathWorks, Inc.

if nargin == 0
   hndl = handlem('taglist');
   if isempty(hndl)
      return
   end
   zdataui(hndl);
   return

elseif nargin == 1
   if ischar(hndl) || isStringScalar(hndl)
      hndl = handlem(hndl);
   end
   zdataui(hndl);
   return

elseif nargin == 2
   if ischar(hndl) || isStringScalar(hndl)
      hndl = handlem(hndl);
   end
   if length(zdata) == 1
      zdata = zdata(ones(size(hndl)));
   end
end

% Input dimension tests
if min(size(hndl)) ~= 1  || ~ismatrix(hndl)  || any(~ishghandle(hndl))
    error('map:zdatam:invalidHandle', 'Vector of handles required.')
elseif max(size(hndl)) ~= 1 && ~isequal(size(hndl),size(zdata))
    error('map:zdatam:inconsistentSize', 'Inconsistent handles and zdata.')
end

% Test for an hggroup handle. If hndl is an hggroup handle, then it is
% either a contourgroup handle containing lines from contourm, or an
% hggroup handle containing lines or patches from mapshow or geoshow.
if ishghandle(hndl(1),'hggroup')
   % hndl is an hggroup handle.
   adjustZPlaneHggroupData(hndl, zdata);
else
   % hndl is not an hggroup handle.
   adjustZPlaneData(hndl, zdata);
end

%--------------------------------------------------------------------------
function adjustZPlaneHggroupData(hndl, zdata)
% Adjust the z-plane data in the children of the hggroup handle array, HNDL
% to ZDATA. The z-plane data is adjusted by setting either the ZData or
% Vertices property. 

% Get and process the children of the hggroup.
children = get(hndl, 'Children');

% Reset the size of the zdata, if necessary.
if length(zdata) == 1
   zdata = zdata(ones(size(children)));
end

if numel(children) ~= numel(zdata)
    error('map:zdatam:vectorFeaturesAndZDataMismatch', ...
        'The number of elements in ZDATA does not match the number of vector features.')
end

% Adjust the ZData or Vertices of each child.
adjustZPlaneData(children, zdata);

%--------------------------------------------------------------------------
function adjustZPlaneData(hndl, zdata)
% Adjust the z-plane data in the handle array, HNDL to ZDATA. The z-plane
% data is adjusted by setting either the ZData, Vertices, or Position
% parameters, depending on the type of handle.

if iscell(hndl)
   hndl = [hndl{:}];
end

for i = 1:length(hndl)
   hndlType = get(hndl(i),'Type');

   switch hndlType
      case 'patch'
         vertices = get(hndl(i),'Vertices');
         if size(vertices,2) == 3
            oldzdata = vertices(:,3);
         else
            oldzdata = [];
         end

      case 'text'
         position = get(hndl(i),'Position');
         oldzdata = position(:,3);

      otherwise
         % Original zdata
         oldzdata = get(hndl(i),'Zdata');
   end

   if max(size(hndl)) == 1 && max(size(zdata)) ~= 1
      % ZDATA matrix specified
      if all(size(zdata) == size(oldzdata))
         newzdata = zdata;
      else
          error('map:zdatam:inconsistentZDataSize', ...
              'New zdata matrix different size from displayed zdata.')
      end

   elseif isempty(oldzdata)
      % No zdata to begin with
      xdata = get(hndl(i),'Xdata');
      newzdata = zdata(i);

      if isequal(hndlType,'patch') && size(xdata,2) ~= 1
         % handle is from MapGraphics.Polygon
         newzdata = newzdata(ones(size(vertices,1),1));
      else
         newzdata = newzdata(ones(size(xdata)));
      end

   else
      % Line object.  New z level
      newzdata = zdata(i);
      newzdata = newzdata(ones(size(oldzdata)));
   end

   switch hndlType
      case 'patch'
         if ~isempty(vertices)
            vertices(:,3) = newzdata;
            set(hndl(i),'Vertices',vertices)
         end

      case 'text'
         position(:,3) = newzdata;
         set(hndl(i),'Position',position)

      otherwise
         % Update zdata property
         set(hndl(i),'Zdata',newzdata)
   end
end

%--------------------------------------------------------------------------
function zdataui(hndl)
% ZDATAUI creates the dialog box to allow the user to enter in the variable
% names for a zdata command.  It is called when ZDATAM is executed with no
% input arguments.

% Display the variable prompt dialog box
% Ensure that the input is a valid scalar handle
if any(~ishghandle(hndl(:)))
   uiwait(errordlg('Valid handle(s) required', ...
      'Object Specification','modal'))
   return
end

% Initialize the entries of the dialog box
str1 = '';

% Loop until no error break or cancel break
while 1

   h = ZdataBox(hndl,str1);
   uiwait(h.fig)

   if ~ishghandle(h.fig)
      return
   end

   % If the accept button is pushed, build up a window change function
   % which will delete the modal dialog and then execute the plotting
   % commands. The change function is used instead of the delete function
   % since the delete function property processes the callback before
   % destroying the window.  Thus, all plotting commands would be directed
   % to the current axes (non-existent) in the modal UI dialog box.  We
   % want to destroy the window first,then process the callback so that the
   % proper axes are used.
   if get(h.fig,'CurrentObject') == h.apply

      % Get the dialog entries
      str1 = get(h.zedit,'String');
      
      try
          new_zd = evalin('base', str1);
          zdatam(hndl(:), new_zd);
          close(h.fig);
          break;
      catch dialog_exception
          uiwait(errordlg(dialog_exception.message, 'Map Plane Specification', ...
              'modal'));
          delete(h.fig);
      end
          
   else
      % Close the modal dialog box
      % Exit the loop
      delete(h.fig)
      break
   end

end

%--------------------------------------------------------------------------
function h = ZdataBox(hndl,zlevel0)
% ZDATABOX will produce a modal dialog box which allows the user to edit
% the zdata property

% Names of current object.
objname = namem(hndl);

% Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Specify Zdata',...
   'Units','points',  ...
   'Position',72*[2 1 3.5 1.7],...
   'Visible','off');
colordef(h.fig,'white')
figclr = get(h.fig,'Color');

% Object Name and Tag (objname is a string matrix if hndl is a vector)
if size(objname,1) == 1
   objstr = ['Object:  ',deblank(objname(1,:))];
else
   objstr = ['Objects:  ',deblank(objname(1,:)),' ...'];
end

h.txtlabel = uicontrol(h.fig, ...
   'Style','Text','String',objstr, ...
   'Units','Normalized', 'Position', [0.05  0.83  0.90  0.13], ...
   'FontWeight','bold',  'FontSize',10, ...
   'HorizontalAlignment','left', ...
   'ForegroundColor','black', 'BackgroundColor',figclr);

% Zdata Variable and Edit Box
h.zlabel = uicontrol(h.fig, ...
   'Style','Text','String', 'Zdata Variable:', ...
   'Units','Normalized', 'Position', [0.05  0.66  0.90  0.13], ...
   'FontWeight','bold',  'FontSize',10, ...
   'HorizontalAlignment','left', ...
   'ForegroundColor','black', 'BackgroundColor',figclr);

h.zedit = uicontrol(h.fig, ...
   'Style','Edit','String', zlevel0, ...
   'Units','Normalized', 'Position', [0.05  0.46  0.70  0.17], ...
   'FontWeight','bold',  'FontSize',10, ...
   'HorizontalAlignment','left', ...
   'ForegroundColor','black', 'BackgroundColor',figclr);

h.zlist = uicontrol(h.fig, ...
   'Style','Push','String', 'List', ...
   'Units','Normalized','Position', [0.77  0.46  0.18  0.17], ...
   'FontWeight','bold',  'FontSize',9, ...
   'ForegroundColor', 'black','BackgroundColor', figclr,...
   'Interruptible','on', 'UserData',h.zedit,...
   'CallBack','varpick(who,get(gco,''UserData''))');

% Buttons to exit the modal dialog
% Accept Button
h.apply = uicontrol(h.fig, ...
   'Style','Push', 'String','Apply', ...
   'Units','points',  ...
   'Position', 72*[0.30  0.10  1.05  0.40], ...
   'FontWeight', 'bold', 'FontSize',10,...
   'HorizontalAlignment','center',...
   'ForegroundColor','black', 'BackgroundColor',figclr,...
   'Interruptible','on', 'CallBack','uiresume');

% Accept Button
h.cancel = uicontrol(h.fig, ...
   'Style','Push', 'String','Cancel', ...
   'Units','points',  ...
   'Position',72*[1.65  0.10  1.05  0.40], ...
   'FontWeight','bold',  'FontSize',10, ...
   'HorizontalAlignment','center', ...
   'ForegroundColor','black', 'BackgroundColor',figclr,...
   'CallBack','uiresume');

set(h.fig,'Visible','on','UserData',hndl(:))

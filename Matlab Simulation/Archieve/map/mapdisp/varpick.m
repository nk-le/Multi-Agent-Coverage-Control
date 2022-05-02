function varpick(varlist,hndl)
%VARPICK  Modal pick list to select variable from workspace
%
%  VARPICK(list,h) displays a list box allowing the selection of
%  a variable name from the cell array list and assigns this name
%  to the edit box specified by the handle h.  This function is
%  used by several GUIs in the Mapping Toolbox to select variables
%  from the workspace.  The typical callback to activate this
%  function is varpick(who,h).

% Copyright 1996-2006 The MathWorks, Inc.

% Make the variable list into a string matrix.
if isempty(varlist)
    varlist = {' '};
end

% Make the list dialog for the variable list
indx = listdlg(...
    'ListString', varlist,...
    'SelectionMode',' single',...
	'ListSize', [160 170],...
	 'Name', 'Select a Variable');

if ~isempty(indx)
    set(hndl,'String',varlist{indx(1)});
end

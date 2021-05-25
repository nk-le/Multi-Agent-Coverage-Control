function restack(hobj,action)
%RESTACK Restack objects within map axes
%
%   RESTACK will be removed in a future release. Use UISTACK instead.
%
%   RESTACK(h,position) changes the stacking order of the object h within
%   the axes.  h can be a handle or vector of handles to graphics objects,
%   or h can be a name string recognized by HANDLEM. Recognized position
%   strings are 'top','bottom','up' or 'down'. RESTACK permutes the order
%   of the children of the axes.
%
%   See also UISTACK

% Copyright 1996-2017 The MathWorks, Inc.

warning(message('map:removing:restack','RESTACK','UISTACK'))

if nargin > 1
    action = convertStringsToChars(action);
end

% UISTACK does not support the option 'bot'
if strcmpi(action, 'bot')
    action = 'bottom';
end

% Get the handle of the target object
if ~ishghandle(hobj)
	hobj = handlem(hobj);
end

uistack(hobj, action)

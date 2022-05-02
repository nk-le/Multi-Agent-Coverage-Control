function [tf,msg] = ismap(varargin)
%ISMAP  True for axes with map projection
%
%  TF = ISMAP returns 1 if the current axes (gca) is a map axes.
%  Otherwise, it returns 0.
%
%  TF = ISMAP(H) checks the axes specified by the handle H.
%
%  [TF, MSG] = ISMAP(...) returns a character vector, MSG, explaining why a
%  map axes was not found.
%
%  See also GCM, ISMAPPED.

% Copyright 1996-2017 The MathWorks, Inc.

try
    gcm(varargin{:});
    tf = true;
    msg = '';
catch e
    if strcmp(e.identifier, 'map:gcm:noAxesInFigure')
        throw(e)
    end
    tf = false;
    msg = e.message;
end
    
% Preserve original behavior
tf = double(tf);

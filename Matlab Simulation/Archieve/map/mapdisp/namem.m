function [names,msg] = namem(h)
%NAMEM Names of graphics objects
%
%   NAMES = NAMEM returns the object names of all graphics objects on the
%   current axes.  The name of an object is defined to be the value of its
%   Tag, if non-empty, and the value of its Type otherwise. The output
%   NAMES is a character matrix with duplicate object names removed.
%
%   NAMES = NAMEM(H) returns the names of the objects specified by
%   an array of Handle Graphics objects handles in H.
%
%   Note: Use cellstr(NAMES) to convert NAMES to a cell array of character
%   vectors or string(NAMES) to convert NAMES to a string array.
%
%   See also CLMO, HANDLEM, HIDEM, SHOWM, TAGM

% Copyright 1996-2017 The MathWorks, Inc.

% Obsolete syntax
% ---------------
%  [obj,msg] = NAMEM(...)  returns a string msg indicating any error
%  encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

% Determine/validate handle array, h.
if nargin == 0
    if isempty(findobj(0,'Type','axes'))
        h = [];
    else
        h = get(gca,'Children');
    end
elseif ~isempty(h)
    classes = {'handle','double'};
    validateattributes(h,classes,{'vector'})
    if ~ishghandle(h)
        error('map:validate:expectedGraphicsHandles', ...
            'Expected input %s to be a vector of Handle Graphics object handles.','H')
    end
    h = h(:);
end

% Construct array of unique names from Tag and Type values of object in h.
if isempty(h)
    names = [];
elseif isscalar(h)
    tag = get(h,'Tag');
    if ~isempty(tag)
        names = tag;
    else
        names = get(h,'Type');
    end
else
    % Two or more objects
    tag  = get(h,'Tag');
    type = get(h,'Type');
    noTag = cellfun(@isempty,tag);
    tag(noTag) = type(noTag);
    
    % Remove duplicate elements while maintaining order.
    tag = unique(tag,'stable');
    
    % Convert cell string vector to character matrix because that's what
    % the function has always returned.
    names = char(tag);
end

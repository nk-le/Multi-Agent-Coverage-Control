function [mstruct,msg] = gcm(varargin)
%GCM Current map projection structure
%
%  MSTRUCT = GCM returns the map projection structure from the current axes
%  (gca).  If the current axes is not a map axes, then an error results.
%
%  MSTRUCT = GCM(H) returns the map projection structure from the axes
%  specified by the input H.
%
%  See also AXESM, GETM.

% Copyright 1996-2008 The MathWorks, Inc.

% Obsolete syntax
% ---------------
%  [MSTRUCT, MSG] = GCM(...) returns an optional second argument which is a
%  string indicating any error state.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

h = checkaxes(varargin{:});
mstruct = get(h,'UserData');
assert(isstruct(mstruct), ...
    ['map:' mfilename ':expectedStruct'], ...
    'Not a map axes.')

names = fieldnames(mstruct);
assert(strcmp(names{1},'mapprojection'), ...
    ['map:' mfilename ':expectedMStruct'], ...
    'Not a map axes.')

mstruct = checkmstruct(mstruct);

%------------------------------------------------------
function h = checkaxes(h)
if nargin == 0
    h = get(get(0,'CurrentFigure'),'CurrentAxes');
    assert(~isempty(h), ...
        ['map:' mfilename ':noAxesInFigure'], ...
        ['No axes in current figure.\n' ...
        'Select a figure with map axes or use AXESM to define one.'])
else
    assert(isscalar(h), ...
        ['map:' mfilename ':expectedScalarHandle'], ...
        'Input handle must be a scalar.')

    assert(ishghandle(h), ...
        ['map:' mfilename ':expectedGraphicsHandle'], ...
        'Input data is not a graphics handle.')

    assert(ishghandle(h,'axes'), ...
        ['map:' mfilename ':expectedAxesHandle'], ...
        'Input is not an axes handle.')
 end

%-------------------------------------------------------
function mstruct = checkmstruct(mstruct)
% check that new false easting, northing, scalefactor and zone properties
% are present. If needed, add them with the default values.
fielddefaults = struct(...
    'zone', [], ...
    'falseeasting', 0, ...
    'falsenorthing', 0, ...
    'scalefactor', 1, ...
    'labelrotation', 'off');

fieldlist = fieldnames(fielddefaults);
fieldlist(isfield(mstruct, fieldlist)) = [];
for k = 1 : numel(fieldlist)
    mstruct.(fieldlist{k}) = fielddefaults.(fieldlist{k});
end
	 
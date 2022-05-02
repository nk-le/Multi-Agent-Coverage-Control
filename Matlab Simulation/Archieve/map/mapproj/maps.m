function [mapIdentifier,msg] = maps(str)
%MAPS  List map projections for map axes and map projection structures
%
%   MAPS lists the map projections available for use with map axes and map
%   projection structures.
%
%   MAPS IDLIST returns a character array containing the identifier strings
%   for all map projections available for use with map axes and map
%   projection structures.
%
%   MAPS NAMELIST returns a character array containing the list of names
%   for all map projections available for use with map axes and map
%   projection structures.
%
%   MAPS CLASSCODES returns a character array containing the list of class
%   codes for all map projections available for use with map axes and map
%   projection structures.
%
%   str = MAPS(str) verifies and standardizes a map projection identifier
%   STR.
%
%   See also AXESM.

% Copyright 1996-2020 The MathWorks, Inc.

% Obsolete Syntax
% ---------------
%   [str,msg] = MAPS(...) returns the character vector indicating any error
%   condition encountered.
if nargout > 1
    warning(message('map:removed:messageStringOutput', ...
        'MAPS','MSG','MSG','MAPS','MAPS'))
    msg = '';
end

%  Get the map list structure
%  The map list structure is of the form:
%        list.Name
%        list.IdString
%        list.Classification
%        list.ClassCode
list = maplist;

if nargin == 0
    %  Display available projections and return empty.
    formatstr = '%-20s  %-32s    %-15s  \n';
    fprintf('\n%-20s \n\n','MapTools Projections')
    fprintf(formatstr,'CLASS','NAME','ID STRING');
    for i = 1:length(list)
        fprintf(formatstr,list(i).Classification,...
            list(i).Name,...
            list(i).IdString);
    end
    fprintf('\n%s\n','* Denotes availability for sphere only')
    fprintf('\n\n');
    idstr = [];
else
    % Ensure that str is a character string.
    str = convertStringsToChars(str);
    validateattributes(str, {'char', 'string'}, {'scalartext'}, 'MAPS', 'ID_STRING', 1)
    str = str(:)';
    
    switch str
        case 'namelist'
            %  Return the list of available map names,
            %  converting asterisks to space characters.
            idstr = char({list(:).Name});
            idstr(idstr == '*') = ' ';
            
        case 'idlist'
            %  Return the list of available projection identifiers.
            idstr = char({list(:).IdString});
            
        case 'classcodes'
            %  Return the list of projection class codes.
            idstr = char({list(:).ClassCode});
            
        otherwise
            %  Return a standard projection identifier.
            idstr = validatestring(str, {list(:).IdString}, ...
                'MAPS', 'ID_STRING', 1);
    end
end

if nargout > 0
    mapIdentifier = idstr;
end

function mat = getm(hndl,propname)
%GETM Map object properties
%
%  mat = GETM(h,'MapPropertyName') returns the value of the specified
%  map property for the map graphics object with handle h.  The
%  graphics object h must be a map axis or one of its children.
%
%  mat = GETM(h) returns all map property values for the map object with
%  handle h.  
%
%  GETM MAPPROJECTION lists the available map projections.
%  GETM AXES lists the map axes properties.
%  GETM UNITS lists the recognized unit strings.
%
%  See also AXESM, SETM, GET, SET, validateLengthUnit

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Programmers Note:  GETM is a time consuming call because of
%  the strmatch and getfield functions.  It is advised that when
%  programming, direct access is made to the map structure and
%  do not use calls to GETM.  For an example of this, see GRIDM
%  and FRAMEM.

narginchk(1,2)

hndl = convertStringsToChars(hndl);
if nargin == 1
    %  Handle provided.  Get all properties
    if ~ischar(hndl)
	     propname = [];
    else
        %  No handle.  Test for special string
        done = false;
        str = validatestring(hndl,{'mapprojection','units','axes'});
        switch  str
            case 'mapprojection'
                maps;
                done = true;
            case 'units'
                fprintf('    %-20s %s\n', validUnitNames')
                done = true;
            case 'axes'
                setm(gca);
                done = true;
        end
        if done
            nargoutchk(0,0)
            return
        end
    end
else
    propname = convertStringsToChars(propname);
end

%  Valid handle test
if isempty(hndl)
    error(['map:' mfilename ':emptyHandle'], 'Handle is not valid.')
end
if ~isscalar(hndl)
    error(['map:' mfilename ':multipleHandles'], ...
        'Multiple handles not allowed.')
end
if ~ishghandle(hndl)
    error(['map:' mfilename ':invalidHandle'], 'Handle is not valid.')
end

%  Get the corresponding axis handle
if ishghandle(hndl,'axes')
     maphndl = hndl;
elseif ishghandle(get(hndl,'Parent'),'axes')
     maphndl = get(hndl,'Parent');
else
     error(['map:' mfilename ':handleNotAxis'], ...
         'GETM only works with a Map Axis and its children.')
end

%  Test for a valid map axes and get the corresponding map structure
gcm(maphndl);

%  Get the user data structure from this object
userstruct = get(hndl,'UserData');
if ~isstruct(userstruct)
    error(['map:' mfilename ':expectedStruct'], ...
        'Map structure not found in object')
end

%  Return the entire structure if propname is empty
if isempty(propname)
    mat = userstruct;
    return
end

%  Otherwise, get the fields of the structure and test for a match
structfields = fieldnames(userstruct);
indx = strmatch(lower(propname),lower(structfields)); %#ok<MATCH2>
if isempty(indx)
    error(['map:' mfilename ':invalidProperty'], ...
        'Incorrect property for object.')
elseif length(indx) == 1
    propname = structfields{indx};
else
	indx = strmatch(lower(propname),lower(structfields),'exact');	   %#ok<MATCH3>
	if length(indx) == 1
    	propname = structfields{indx};
	else
	    error(['map:' mfilename ':nonUniqueProperty'], ...
       'Property %s name not unique - supply more characters.', propname)
	end
end

%  If match is found, then return the corresponding property
mat = userstruct.(propname);
end


function unitNames = validUnitNames()
% Return a two-column string matrix that matches the help for
% validateLengthUnit.
    unitNames = [ ...
        ""                     ""
        "Standard Name"        "Supported Names"
        "-------------"        "---------------"
        "meter"                "'m', 'meter(s)', 'metre(s)'"
        ""                     ""
        "centimeter"           "'cm', 'centimeter(s)', 'centimetre(s)'"
        ""                     ""
        "millimeter"           "'mm', 'millimeter(s)', 'millimetre(s)'"
        ""                     ""
        "micron"               "'micron(s)'"
        ""                     ""
        "kilometer"            "'km', 'kilometer(s)', 'kilometre(s)'"
        ""                     ""
        "nautical mile"        "'nm', 'naut mi', 'nautical mile(s)'"
        ""                     ""
        "foot"                 "'ft',   'international ft'"
        ""                     "'foot', 'international foot'"
        ""                     "'feet', 'international feet'"
        ""                     ""
        "inch"                 "'in', 'inch', 'inches'"
        ""                     ""
        "yard"                 "'yd', 'yds', 'yard(s)'"
        ""                     ""
        "mile"                 "'mi', 'mile(s)', 'international mile(s)'"
        ""                     ""
        "U.S. survey foot"     "'sf',"
        ""                     "'survey ft',   'US survey ft', 'U.S. survey ft',"
        ""                     "'survey foot', 'US survey foot', 'U.S. survey foot',"
        ""                     "'survey feet', 'US survey feet', 'U.S. survey feet',"
        ""                     ""
        "U.S. survey mile"     "'sm', 'survey mile(s)', 'statute mile(s)',"
        "(statute mile)"       "'US survey mile(s)', 'U.S. survey mile(s)'"
        ""                     ""
        "Clarke's foot"        "'Clarke''s foot', 'Clarkes foot'"
        ""                     ""
        "German legal metre"   "'German legal metre', 'German legal meter'"
        ""                     ""
        "Indian foot"          "'Indian foot'"
        ""                     ""
        ];
end

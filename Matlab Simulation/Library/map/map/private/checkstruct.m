function checkstruct(S, function_name, variable_name, argument_position)
%CHECKSTRUCT Verifies that the input is a structure
%
%   CHECKSTRUCT(S, FUNCTION_NAME, VARIABLE_NAME, ARGUMENT_POSITION)
%   verifies that S is a structure.  If it isn't, CHECKSTRUCT issues an
%   error message using FUNCTION_NAME, VARIABLE_NAME, and
%   ARGUMENT_POSITION.  FUNCTION_NAME is the name of the user-level
%   function that is checking the struct, VARIABLE_NAME is the name of the
%   struct variable in the documentation for that function, and
%   ARGUMENT_POSITION is the position of the input argument to that
%   function.

%   Copyright 1996-2011 The MathWorks, Inc.

if ~isstruct(S)
    error(['map:' function_name, ':invalidGeoStruct'], ...
        'Function %s expected input number %d, %s, to be a structure.', ...
        upper(function_name), argument_position, upper(variable_name))
end

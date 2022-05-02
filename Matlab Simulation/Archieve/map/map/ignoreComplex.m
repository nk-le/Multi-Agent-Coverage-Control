function A = ignoreComplex(A, func_name, var_name) 
%IGNORECOMPLEX Convert complex input to real and issue warning
%
%   IGNORECOMPLEX(A, FUNC_NAME, VAR_NAME) replaces complex A with its real
%   part and issues a warning.

% Copyright 1996-2017 The MathWorks, Inc.

if ~isnumeric(A)
    error(message('map:validate:nonNumericInput', func_name, var_name))
end

if ~isreal(A)
    id = "map:" + func_name + ":ignoringComplexArg";
    warning(id,'%s',getString(message('map:removing:complexInput', ...
        upper(var_name), upper(func_name))))
	A = real(A);
end

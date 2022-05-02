function warnObsoleteMSGSyntax(func_name)

% Copyright 2007-2011 The MathWorks, Inc.

id = ['map:' func_name ':obsoleteMSGSyntax'];
func_name = upper(func_name);
warning(id,'%s',getString(message('map:removed:messageStringOutput',...
    func_name, 'MSG', 'MSG', func_name, func_name)))

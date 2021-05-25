function setCurrentPath(this,filename)
%

%   Copyright 1996-2003 The MathWorks, Inc.

pathstr = fileparts(filename);
if isempty(pathstr)
  f = which(filename);
  pathstr = fileparts(f);
end
this.CurrentPath = [pathstr filesep];


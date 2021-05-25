function closeAll(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

if ~isempty(this.InfoBoxHandles)
  delete([this.InfoBoxHandles{:,2}]);
  this.InfoBoxHandles = [];
end

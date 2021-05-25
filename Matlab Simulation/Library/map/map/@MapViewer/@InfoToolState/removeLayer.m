function removeLayer(this,layername)
%

%   Copyright 1996-2003 The MathWorks, Inc.

if ~isempty(this.InfoBoxHandles)
  ind = strmatch(layername, this.InfoBoxHandles(:,1), 'exact');
  if ~isempty(ind)
    delete(this.InfoBoxHandles{ind,2});
    this.InfoBoxHandles(ind,:) = [];  
  end
end


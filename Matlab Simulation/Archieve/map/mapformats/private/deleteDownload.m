function deleteDownload(filename)
%DELETEDOWNLOAD Delete a temporary filename from the system.

% Copyright 1996-2011 The MathWorks, Inc.

try
    delete(filename);
catch %#ok<CTCH>
    warning(message('map:fileManagement:unableToDeleteTempFile',filename))
end

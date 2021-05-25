function closeFiles(fileIds)
%CLOSEFILES Close multiple files.
%   Close any files in the list of file IDs that are actually open.

%   Copyright 1996-2003 The MathWorks, Inc.

for k = 1:length(fileIds)
    if ~isempty(fopen(fileIds(k)))
        fclose(fileIds(k));
    end
end

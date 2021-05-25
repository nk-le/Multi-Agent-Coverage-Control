function tagValue = readRPCCoefficientTag(filename)
%readRPCCoefficientTag Read RPCCoefficient TIFF tag
%
%   tagValue = readRPCCoefficientTag(FILENAME) reads the TIFF file
%   specified by FILENAME and returns a cell array the same length as the
%   number of TIFF directories. If a TIFF directory contains the
%   RPCCoefficient tag, the tag value is returned in the corresponding
%   position in tagValue. The tag value is a 92 element row vector of
%   doubles. If the tag is not found, empty is returned. If there are no
%   RPCCoefficient tags in the file, then a cell array of empty values is
%   returned. If a file contains multiple TIFF directories, one or more
%   directories may contain the RPCCoefficient tag.

% Copyright 2015 The MathWorks, Inc.

% Obtain all the tags of the file by using imfinfo. UnknownTags are not
% reported by the Tiff class. Turn off all warnings until warnObj is
% deleted.
warnObj = turnOffAllWarnings;
tinfo = imfinfo(filename);

% Obtain RPCCoefficient tag value and return it in the cell array tagValue.
tagValue = cell(1,length(tinfo));
unknownTagFieldName = 'UnknownTags';
if isfield(tinfo, unknownTagFieldName)
    % Loop through the structure array to find RPCCoefficient tags,
    % determined by the ID (50844). Expect length of tinfo to match number
    % of TIFF directories. There may be more than one unknown tag in each
    % directory. If the tag is in a directory, then we expect only one tag
    % with ID 50844. No warning is thrown if multiple tags with the same ID
    % are present in the same directory, only the first one is accepted.
    % (It is unlikely the TIFF specification supports multiple tags with
    % the same ID in a directory). If multiple TIFF directories are
    % present, one or more may contain a single RPCCoefficient tag. For
    % those directories that do not contain the tag, set to [].
    rpcCoeffientTagID = 50844;
    for k = 1:length(tinfo)
        unknownTags = [tinfo(k).(unknownTagFieldName)];
        ID = [unknownTags.ID];
        unknownTags(ID ~= rpcCoeffientTagID) = [];
        if ~isempty(unknownTags)
           tagValue{k} = [unknownTags(1).Value];
        end
    end
end
   
% Return the warning state to initial condition.
delete(warnObj);

%--------------------------------------------------------------------------

function warnObj = turnOffAllWarnings
% Turn off all warnings until warnObj is deleted.

warnState = warning('query', 'all');
warnObj = onCleanup(@() warning(warnState));
warning('off', 'all')

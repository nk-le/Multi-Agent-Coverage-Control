function writeRPCCoefficientTag(filename,tagValue)
%writeRPCCoefficientTag Write RPCCoefficient TIFF tag
%
%   writeRPCCoefficientTag(FILENAME,TAGVALUE) sets the value of the
%   RPCCoefficientTag to TAGVALUE in the TIFF file specified by FILENAME.
%   TAGVALUE is a 92 element row vector of doubles. The TIFF file should
%   exist and be writable (have "r+" permissions). If the TIFF file does
%   not exist, a new file is created.

% Copyright 2015-2019 The MathWorks, Inc.

    validateattributes(filename,{'char'},{'vector','nonempty'}, ...
        mfilename,'FILENAME',1);

    lengthOfTag = 92;
    validateattributes(tagValue,{'double'},{'real','vector','numel',lengthOfTag}, ...
        mfilename,'TAGVALUE',2);

    validateTiffFile(filename);
    try
        tObj = Tiff(filename,'r+');
        setTag(tObj,'RPCCoefficientTag',tagValue);
        close(tObj);
    catch
        error(message('MATLAB:imagesci:Tiff:unableToWriteTag',"RPCCoefficientTag"));
    end
    %mexWriteRPCCoefficientTag(filename,tagValue)
end

function validateTiffFile(filename)
% Ensure file is a TIFF file and can be opened "r+"

    wstate = warning('off','imageio:tiffmexutils:libtiffWarning');
    try
        t = Tiff(filename, 'r+');
        close(t)
        warning(wstate)
    catch e
        warning(wstate)
        throwAsCaller(e)
    end
end

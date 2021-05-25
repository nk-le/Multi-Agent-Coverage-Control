function rgb = colorSpecToRGB(colorSpec)
%map.internal.colorSpecToRGB Convert ColorSpec to RGB
%
%   RGB = map.internal.colorSpecToRGB(ColorSpec) converts a
%   character-valued color specification to an RGB color vector, or
%   validates a numeric color specification (which must be class double).
%
%   Input Argument
%   --------------
%   ColorSpec    1-by-3 RGB color vector, (partial) color string, or single
%                letter abbreviation
%
%   Output Argument
%   ---------------
%   RGB         1-by-3 RGB color vector of class double with values 
%               between 0 and 1

% Copyright 2012 The MathWorks, Inc.

if ischar(colorSpec)
    % Convert the colorSpec string to an RGB value.
    validateattributes(colorSpec, {'char'}, {'nonempty', 'vector'}, '', 'ColorSpec')
    rgb = colorSpecStringToRGB(colorSpec);
else
    % colorSpec is expected to be a double vector with values between 0 and
    % 1 and with size 1-by-3.
    validateattributes(colorSpec, {'double'}, ...
        {'nonempty', '>=', 0, '<=', 1, 'size', [1 3]}, '', 'ColorSpec');
    rgb = colorSpec;
end

%--------------------------------------------------------------------------

function rgb = colorSpecStringToRGB(colorSpec)
% Convert the string colorSpec to an RGB value. Allow the string to be a
% partial match of any valid color.

% Remove any blank spaces around colorSpec
colorSpec = strtrim(colorSpec);

% Process special characters: 'k' (black) or 'b' (blue)
index = strcmp(colorSpec, {'k', 'b'});
if any(index)
    % 'k' matches black
    % 'b' matches 'blue' or 'black' for partial string matching but is
    % defined as 'blue'.
    blackOrBlue = [0 0 0; 0 0 1];
    rgb = blackOrBlue(index, :);
else
    % Valid single color characters are: 'rgbwcmyk';
    colorSpecStrings = { ...
        'red', 'green', 'blue', 'white', 'cyan', 'magenta', 'yellow', 'black'};
    rgbSpec = [1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 1 1; 1 0 1; 1 1 0; 0 0 0];
    
    % Validate the string against the valid colorSpecStrings. The index of
    % each colorSpecStrings is associated with the corresponding value in
    % rgbSpec. Partial string matching is permitted.
    colorString = validatestring(colorSpec, colorSpecStrings, '', 'ColorSpec');   
    index = strcmp(colorString, colorSpecStrings);
    rgb = rgbSpec(index,:);
end

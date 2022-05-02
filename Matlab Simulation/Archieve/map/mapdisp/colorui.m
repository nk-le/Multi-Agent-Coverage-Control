function C = colorui(InitClr, FigTitle)
%COLORUI Interactively define RGB color
%
%  COLORUI is obsolete. Use UISETCOLOR instead.
%
%  C = COLORUI will create an interface for the definition of an RGB
%  color triplet.  COLORUI will produce the same interface as UISETCOLOR.  
%
%  C = COLORUI(InitClr) will initialize the color value to the
%  RGB triple given in INITCLR.
%
%  C = COLORUI(InitClr, FigTitle) will use the string in FigTitle as
%  the window label.
%
%  The output value C is the selected RGB triple.

% Copyright 1996-2012 The MathWorks, Inc.

warning(message('map:removing:colorui','COLORUI','UISETCOLOR'))

narginchk(0, 2)

if nargin == 0
    C = uisetcolor();
elseif nargin == 1
    C = uisetcolor(InitClr);
else 
    C = uisetcolor(InitClr, FigTitle);
end

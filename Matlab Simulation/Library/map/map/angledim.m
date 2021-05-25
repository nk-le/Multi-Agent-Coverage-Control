function angmat = angledim(angmat,from,to)
%ANGLEDIM Convert angle units
%
%   ANGLEDIM has been replaced by four more specific functions:
%
%        fromRadians
%        fromDegrees
%        toRadians
%        toDegrees
%
%   but ANGLEDIM will be maintained for backward compatibility.  The
%   functions DEG2RAD, RAD2DEG, and UNITSRATIO provide additional
%   alternatives.
%
%   angleOut = ANGLEDIM(angleIn, FROM, TO) converts angleIn from angle
%   units FROM to angle units TO.  FROM and TO may be either 'degrees'
%   or 'radians'.  They are case-insensitive and may be abbreviated.
%   angleIn and angleOut are arrays of class double, and size(angleOut)
%   matches size(angleIn).
%
%   Alternatives to ANGLEDIM
%   ------------------------
%   Because it must resolve both the input and output units, ANGLEDIM is
%   excessive for most applications.  In addition, it works only for
%   class double and it quietly discards the imaginary part of any
%   complex input.  Consider one of the following alternatives for
%   improved efficiency and generality:
%
%   If you are working from the command line, you can often replace
%   ANGLEDIM with DEG2RAD or RAD2DEG.
%
%   If you are converting angle units within a script or function and you
%   know the values of both FROM and TO at the time of coding, then you can
%   also replace ANGLEDIM with DEG2RAD or RAD2DEG.
%
%   If you know either FROM or TO at the time of coding, then you can
%   use fromRadians, fromDegrees, toRadians, or toDegrees.  Apply one of
%   the following transformations to your code:
%
%     angledim(angleIn,'radians',TO) --> fromRadians(TO,angleIn)
%
%     angledim(angleIn,'degrees',TO) --> fromDegrees(TO,angleIn)
%
%     angledim(angleIn,FROM,'radians') --> toRadians(FROM,angleIn)
%
%     angledim(angleIn,FROM,'degrees') --> toDegrees(FROM,angleIn)
%
%   Also note that the functions in the fromRadians family can convert
%   multiple variables in a single function call.  For example, you can
%   replace:
%
%     angle1 = angledim(angle1InRadians,'radians',TO);
%     angle2 = angledim(angle2InRadians,'radians',TO);
%
%   with:
%
%     [angle1,angle2] = fromRadians(TO,angle1InRadians,angle2InRadians);
%
%   If you do not know either FROM or TO at the time of coding, then you
%   can call UNITSRATIO to obtain the correct conversion factor, then
%   multiply the values of one or more variables.  For example, you can
%   replace:
%
%     angle1Out = angledim(angle1In, FROM, TO);
%     angle2Out = angledim(angle2In, FROM, TO);
%
%   with:
%
%     r = unitsratio(TO, FROM);
%     angle1Out = r * angle1In;
%     angle2Out = r * angle2In;
%
%   See also DEG2RAD, fromDegrees, fromRadians, RAD2DEG, toDegrees,
%            toRadians, UNITSRATIO.

% Copyright 1996-2015 The MathWorks, Inc.

validateattributes(angmat, {'double'}, {})

from = checkangleunits(from);
to   = checkangleunits(to);

% Convert complex input.
if ~isreal(angmat)
    angmat = real(angmat);
end

if ~strcmp(from,to)
    if strcmp(from,'degrees')
        angmat = angmat*pi/180;
    else
        angmat = angmat*180/pi;
    end
end

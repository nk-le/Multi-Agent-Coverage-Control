function mstruct = setAngleUnits(mstruct, newunits)
% Reset the angle units of a map projection structure (mstruct).

% Copyright 2009-2015 The MathWorks, Inc.

newunits = checkangleunits(newunits);
oldunits = checkangleunits(mstruct.angleunits);

if ~strcmp(newunits,oldunits)
    if strcmp(oldunits,'degrees')
        f = @deg2rad;
    else
        f = @rad2deg;
    end
    
    mstruct.angleunits = newunits;
    
    mstruct.fixedorient    = f(mstruct.fixedorient);
    mstruct.maplatlimit    = f(mstruct.maplatlimit);
    mstruct.maplonlimit    = f(mstruct.maplonlimit);
    mstruct.mapparallels   = f(mstruct.mapparallels);
    mstruct.origin         = f(mstruct.origin);
    mstruct.flatlimit      = f(mstruct.flatlimit);
    mstruct.flonlimit      = f(mstruct.flonlimit);
    mstruct.mlineexception = f(mstruct.mlineexception);
    mstruct.mlinelimit     = f(mstruct.mlinelimit);
    mstruct.mlinelocation  = f(mstruct.mlinelocation);
    mstruct.plineexception = f(mstruct.plineexception);
    mstruct.plinelimit     = f(mstruct.plinelimit);
    mstruct.plinelocation  = f(mstruct.plinelocation);
    mstruct.mlabellocation = f(mstruct.mlabellocation);
    mstruct.mlabelparallel = f(mstruct.mlabelparallel);
    mstruct.plabellocation = f(mstruct.plabellocation);
    mstruct.plabelmeridian = f(mstruct.plabelmeridian);
    mstruct.trimlat        = f(mstruct.trimlat);
    mstruct.trimlon        = f(mstruct.trimlon);
end

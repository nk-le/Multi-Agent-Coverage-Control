function checkmapnargin(low, high, numInputs, function_name, displayType)
%CHECKMAPNARGIN Check number of data arguments
%
%   CHECKMAPNARGIN(LOW, HIGH, NUMINPUTS, FUNCTION_NAME, DISPLAYTYPE) checks
%   whether NUM_INPUTS is in the range indicated by LOW, a scalar
%   nonnegative integer, and HIGH, a scalar nonnegative integer or Inf. If
%   not, a formatted error message is issued using the string in
%   FUNCTION_NAME and DISPLAYTYPE. 

% Copyright 2010-2011 The MathWorks, Inc.

if numInputs < low
   msgId = sprintf('map:%s:tooFewInputs', function_name);
   msgDisp = sprintf('%s%s','with DisplayType set to ',displayType);
   if low == 1
      msg1 = sprintf('Function %s expected at least 1 input data argument', ...
         upper(function_name));
   else
      msg1 = sprintf('Function %s expected at least %d input data arguments', ...
         upper(function_name), low);
   end

   if numInputs == 1
      msg2 = 'Instead it was called with 1 input data argument.';
   else
      msg2 = sprintf('Instead it was called with %d input data arguments.', ...
         numInputs);
   end
   error(msgId, '%s %s. %s', msg1, msgDisp, msg2);

elseif numInputs > high
   msgId = sprintf('map:%s:tooManyInputs', function_name);
   msgDisp = sprintf('%s%s','with DisplayType set to ',displayType);

   if high == 1
      msg1 = sprintf('Function %s expected at most 1 input data argument', ...
         upper(function_name));
   else
      msg1 = sprintf('Function %s expected at most %d input data arguments', ...
         upper(function_name), high);
   end

   if numInputs == 1
      msg2 = 'but was called instead with 1 input data argument.';
   else
      msg2 = sprintf('but was called instead with %d input data arguments.', ...
         numInputs);
   end
   error(msgId, '%s, %s, %s', msg1, msgDisp, msg2);
end
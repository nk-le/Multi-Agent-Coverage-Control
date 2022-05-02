function assert(condition, msgID, varargin)
%map.internal.ASSERT Throw exception if condition is false
%
%   map.internal.assert(CONDITION, MSGID, VARARGIN) throws an exception,
%   with the message ID specified by MSGID string, if the logical (or
%   numeric) scalar CONDITION is false.  MSGID must correspond to an entry
%   in a message catalog.  Any extra arguments are passed to the message
%   object constructor.
%
%   This function provides an alternative to the following pattern based on
%   the MATLAB ASSERT function:
%
%      assert(CONDITION, message(MSGID, VARARGIN{:}))
%
%   map.internal.assert provides the same functionality with better
%   performance, mainly because it constructs a message object only if
%   CONDITION is false.
%
%   Examples
%   --------
%   % In the following the condition is satisfied, and map.internal.assert
%   % does nothing.
%   X = [1 2 3];
%   Y = [4 5 6];
%   map.internal.assert(isequal(size(X),size(Y)), ...
%       'map:validate:inconsistentSizes','X','Y')
%
%   % In the following the condition is not satisfied, and an exception is
%   % thrown with the identifier: 'map:validate:inconsistentSizes' and
%   % message: 'X and Y must have the same size.'
%   X = [1 2 3];
%   Y = [4 5 6 7];
%   map.internal.assert(isequal(size(X),size(Y)), ...
%       'map:validate:inconsistentSizes','X','Y')
%
%   % In both cases, we have a replacement for:
%   assert(isequal(size(X),size(Y)), message( ...
%       'map:validate:inconsistentSizes','X','Y'))
%
%   See also ASSERT, MException

% Copyright 2012-2020 The MathWorks, Inc.

if isscalar(condition) && (islogical(condition) || isnumeric(condition))
    if ~condition
        validateattributes(msgID,{'char'},{'row'}, ...
            'map.internal.assert','MSGID',2)
        msg = message(msgID, varargin{:});
        exception = MException(msg.Identifier, '%s', msg.getString());
        throwAsCaller(exception);
    end
else
    % We know that CONDITION is invalid. Invoke ASSERT to leverage its
    % argument checking and message construction.
    try
        assert(condition, message(msgID, varargin{:}))
    catch e
        msg = sprintf('Error using map.internal.assert\n%s', e.message);
        throwAsCaller(MException(e.identifier, '%s', msg))
    end
end

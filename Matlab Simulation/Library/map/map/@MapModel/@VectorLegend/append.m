function append(this,newproperties)
%

% Copyright 1996-2007 The MathWorks, Inc.

% User defined properties
fldnames = fieldnames(newproperties);
for i=1:length(fldnames)
  if isprop(this,fldnames{i})
    % Always replace the default with the new property's default, 
    % if there is one.
    if isAnyDefault(newproperties.(fldnames{i})) 
      legendDefault = strcmpi('default',this.(fldnames{i})(:,1));
      ruleDefault = strcmpi('default',newproperties.(fldnames{i})(:,1)); 
      if any(ruleDefault)
        % Replace the default and cat the rest.
        this.(fldnames{i})(legendDefault,:) = newproperties.(fldnames{i})(ruleDefault,:); 
        newproperties.(fldnames{i})(ruleDefault,:) = [];
        this.(fldnames{i}) = cat(1,this.(fldnames{i}), ...          
                                 newproperties.(fldnames{i}));
      else
        this.(fldnames{i}) = cat(1,this.(fldnames{i}), ...
                                 newproperties.(fldnames{i}));
      end
    else
      this.(fldnames{i}) = cat(1,this.(fldnames{i}), ...
                               newproperties.(fldnames{i}));
    end
  else
    error(['map:' mfilename ':mapError'], ...
        '%s is not a property that can be set for a %s shape.', ...
        fldnames{i},getShapeType(class(this)))
  end
end

function b = isAnyDefault(rule)
% True if any of the rules for the property are a default rule.
b = false;
if  any(strcmpi({rule{:,1}},'default')) &&...
      isempty(rule{strcmpi({rule{:,1}},'default'),2})
  b = true;
end

function type = getShapeType(classname)
s = regexp(classname,'\.');
f = regexp(classname,'Legend');
type = classname(s+1:f-1);

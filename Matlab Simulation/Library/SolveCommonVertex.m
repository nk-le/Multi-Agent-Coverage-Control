function [IsNeighbour, CommonVertex1, CommonVertex2] = SolveCommonVertex(thisVertex, AdjVertex, CompareTol)

Aplus = thisVertex(:,1) + thisVertex(:,2);
Bplus = AdjVertex(:,1) + AdjVertex(:,2);
Aminus = thisVertex(:,1) - thisVertex(:,2);
Bminus = AdjVertex(:,1) - AdjVertex(:,2);

idn = ismembertol(Aplus, Bplus,CompareTol) & ismembertol(Aminus, Bminus,CompareTol);
CommonVertex = thisVertex(idn,:);
if sum(idn)==2
    IsNeighbour = true;
    CommonVertex1 = CommonVertex(1,:);
    CommonVertex2 = CommonVertex(2,:);
elseif sum(idn)==1
    disp("Error: only 1 common vertex detected!");
elseif sum(idn)>2
    disp("Error: more than 2 vertexes detected!");
else
%     disp("Warning: common vertex error!");
    IsNeighbour = false;
    CommonVertex1 = zeros(1,2);
    CommonVertex2 = zeros(1,2);
end

end


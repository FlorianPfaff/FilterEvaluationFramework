function boxplotFromCell(datacell, labelcell, varargin)
% Varargin can be used to pass on additional arguments
% V1.0 by Florian Pfaff pfaff@kit.edu
numelLargest = max(cellfun(@numel, datacell));
boxplotMat = NaN(numelLargest, numel(datacell));
for i = 1:numel(datacell)
    assert(~isempty(datacell{i}));
    assert(ismatrix(datacell{i}) && any(size(datacell{i})==1), 'Each cell must contain a vector.');
    boxplotMat(1:numel(datacell{i}), i) = datacell{i};
end
if nargin >= 2
    boxplot(boxplotMat, labelcell, varargin{:});
else
    boxplot(boxplotMat);
end
end
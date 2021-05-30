function allDeviationsLast = plotResultsBoxplot(filenames)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
arguments
    filenames {mustBeA(filenames, {'cell', 'char'})} = ''
end
warning on
meanCalculationSymm = 'Bingham'; % For hemispherical scenarios. Options: meanShift, Bingham, meanDiection
plotRandomFilter = true;
% Output is performance on a per filter basis.
% Can provide a cell array of filenames as input
% If no argument is given, test if results exists in base workspace
if ~isempty(filenames)
    % Load all files of cell array
    if ~iscell(filenames)
        load(filenames, 'groundtruths', 'results', 'scenarioParam');
    else
        [results, groundtruths, scenarioParam] = combineMats(filenames);
    end
elseif evalin('base', 'exist(''results'',''var'')')
    % If no argument is given, use results from base (this is very
    % convenient)
    results = evalin('base', 'results');
    groundtruths = evalin('base', 'groundtruths');
    scenarioParam = evalin('base', 'scenarioParam');
else % No argument given and no results exist, prompt to load file
    filename = uigetfile;
    load(filename, 'groundtruths', 'results', 'scenarioParam');
end

groundtruths = groundtruths(:);
if ~plotRandomFilter
    results(contains({results.filterName}, 'random')) = [];
end

if numel(groundtruths) < 1000
    warning('Using less than 1000 runs. This may lead to unreliable results');
end

%%
if ~isfield(scenarioParam, 'manifoldType')
    warning('Need to try to detect domain type automatically');
end
if isfield(scenarioParam, 'manifoldType')
    mode = scenarioParam.manifoldType;
elseif size(groundtruths{1}, 1) == 1 || ismember('htpf', {results.filterName}) || ismember('ffsqrt', {results.filterName}) || ismember('ffid', {results.filterName}) || ismember('twn', {results.filterName})
    mode = 'hypertorus';
elseif ~any(contains({results.filterName}, {'symm', 'hhgf', 'bingham'}, 'IgnoreCase', true)) && (ismember('ishf', {results.filterName}) || ismember('sqshf', {results.filterName}) || ismember('sgf', {results.filterName}) || ismember('hgf', {results.filterName}) || ismember('vmf', {results.filterName}))
    mode = 'hypersphereGeneral';
elseif any(contains({results.filterName}, {'symm', 'hhgf', 'bingham'}, 'IgnoreCase', true))
    mode = 'hypersphereSymm';
else
    error('Could not detect if spherical or toroidal scenario');
end
% If mode hypersphereSymm, then a suitable filter should have been used
assert(~(strcmp(mode, 'hypersphereSymm') && ~any(contains({results.filterName}, {'symm', 'hhgf', 'bingham'}, 'IgnoreCase', true))));

fprintf('Using mode %s\n', mode);

[distanceFunction, extractMean] = getDistanceFunMeanCalcAndLabel(mode);
% If no filter states are there, overwrite extractMean to just give out
% the last estimate
if ~isfield(results, 'lastFilterStates')
    extractMean = @(x, config, run)x(config).lastEstimates{run};
end

if ~isfield(results, 'lastFilterStates') && ~isfield(results, 'lastEstimates')
    error('No filter states and estimates were found. Something is wrong here.');
elseif ~isfield(results, 'lastFilterStates')
    warning('Filter states not found. Use lastEstimates generated during run time');
end
allDeviationsLastMat = determineAllDeviations(results, extractMean, distanceFunction, meanCalculationSymm, groundtruths);


allDeviationsLast = cellfun(@(x)num2cell(x, 2), allDeviationsLastMat, 'UniformOutput', false);

%%
% To sort according to the desired order. Flip ffid and ffsqrt to
% ensure the dashed line for ffid is not overdrawn by the solid line
% for ffsqrt
allNames = {'grid', 'discrete', 'ffsqrt', 'sqshf', 'ffid', 'ishf', 'htgf', 'sgf', 'hgf', 'hhgf', ...
    'hgfSymm', 's3f', 'pf', 'htpf', 'kf', 'kf-maha', 'vm', 'bingham', 'wn', 'vmf', 'twn', 'dummy', ...
    'randomTorus', 'randomSphere', 'se2bf', 'se2iukf', 'fig', 'figResetOnPred'};
filterNames = allNames(ismember(allNames, {results.filterName}));
if numel(filterNames) < numel(unique({results.filterName}))
    warning('One of the filters is unknown');
end
%paramTimeAndErrorPerFilter=struct('filterName',filterNames,'allParams',[],'allTimes',[],'allErrors',[]);
% Iteriere über die Namen und nimm dann alle Einträge, bei denen der
% Filtername passt.
labels = cell(1, numel(results));
for i = 1:numel(results)
    labels(i) = {sprintf([results(i).filterName, '%d'], results(i).filterParams)};
end
boxplotFromCell(cellfun(@(cell){cell2mat(cell)}, allDeviationsLast), labels);
end
function allDeviationsLast = plotResultsBoxplot(filenames, linBoundedErrorMode)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
% V2.15
arguments (Input)
    filenames {mustBeA(filenames, {'cell', 'char'})} = ''
    % Specify if only linear or only periodic part should be considered if
    % state has both (e.g., for SE(2)).
    linBoundedErrorMode char {mustBeMember(linBoundedErrorMode,{'','linear','bounded'})} = ''
end
arguments (Output)
    allDeviationsLast (1,:) cell   
end
if ~isequal(warning(),struct('identifier','all','state','on'))
    notAllWarningsShown = true;
    disp('Not all warnings are enabled.')
else
    notAllWarningsShown = false;
end
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
    warning('PlotResults:FewRuns','Using less than 1000 runs. This may lead to unreliable results');
end

%%
if ~isfield(scenarioParam, 'manifoldType')
    warning('Need to try to detect domain type automatically');
end
if isfield(scenarioParam, 'manifoldType')
    mode = scenarioParam.manifoldType;
elseif size(groundtruths{1}, 1) == 1 || ismember('htpf', {results.filterName}) || ismember('sqff', {results.filterName}) || ismember('iff', {results.filterName}) || ismember('twn', {results.filterName})
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
% By clearing the figures instead of closing them, we can maintain position and size of the plots, which we may often like to preserve
figHandles = findobj('Type', 'figure');
if ~isempty(figHandles)&&any([figHandles.Number]==11)
    clf(11, 'reset');
end

fprintf('Using mode %s\n', [mode,linBoundedErrorMode]);

[distanceFunction, extractMean, errorLabel] = getDistanceFunMeanCalcAndLabel([mode,linBoundedErrorMode]);
% If no filter states are there, overwrite extractMean to just give out
% the last estimate
if ~isfield(results, 'lastFilterStates')
    extractMean = @(x, config, run)x(config).lastEstimates{run};
end

if ~isfield(results, 'lastFilterStates') && ~isfield(results, 'lastEstimates')
    error('No filter states and estimates were found. Something is wrong here.');
elseif ~isfield(results, 'lastFilterStates')
    % If no filter states are there, overwrite extractMean to just give out
    % the last estimate
    warning('FilterEvaluationFramework:FilterStatesNotFoundForPlotting', 'Filter states not found. Use lastEstimates generated during run time');
    extractMean = 'useStored';
end
if isfield(results, 'allEstimates')
    warning('All filter states were saved. It is highly likely that this negatively impacted the run times.');
end
allDeviationsLastMat = determineAllDeviations(results, extractMean, distanceFunction, meanCalculationSymm, groundtruths);
assert(all([allDeviationsLastMat{:}]>=0,[1,2]));
assert(isreal([allDeviationsLastMat{:}]));
allDeviationsLast = cellfun(@(x)num2cell(x, 2), allDeviationsLastMat, 'UniformOutput', false);

% To sort according to the desired order. Flip iff and sqff to
% ensure the dashed line for iff is not overdrawn by the solid line
% for sqff
supportedFiltersShortNames = {'se2ukfm', 'se2bf', 's3f', 'grid', 'iff', 'sqff', 'pf', 'htpf', 'vmf', 'bingham', 'wn', 'vm', 'twn', ...
    'kf', 'ishf', 'sqshf', 'htgf', 'sgf', 'hgf', 'hgfSymm', 'hhgf', 'randomTorus', 'randomSphere', 'fig', 'figResetOnPred'};

filterNames = supportedFiltersShortNames(ismember(supportedFiltersShortNames, {results.filterName}));
if numel(filterNames) < numel(unique({results.filterName}))
    warning('One of the filters is unknown');
end
labels = cell(1, numel(results));
for i = 1:numel(results)
    labels(i) = {sprintf([results(i).filterName, '%d'], results(i).filterParams)};
end
figure(10);
boxplotFromCell(cellfun(@(cell){cell2mat(cell)}, allDeviationsLast), labels);
ylabel(errorLabel);
if notAllWarningsShown
    disp('-----------Reminder: Not all warnings were enabled.-----------')
end
end
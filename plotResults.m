function paramTimeAndErrorPerFilter = plotResults(filenames, plotLog, plotStds, linBoundedErrorMode)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
% V2.15
arguments (Input)
    filenames {mustBeA(filenames, {'cell', 'char'})} = ''
    plotLog (2, :) logical = [true; true] % Specified per axis per default, can set individually for all plots
    plotStds (1, 1) logical = false
    % Specify if only linear or only periodic part should be considered if
    % state has both (e.g., for SE(2)).
    linBoundedErrorMode char {mustBeMember(linBoundedErrorMode,{'','linear','bounded'})} = ''
end
arguments (Output)
    paramTimeAndErrorPerFilter struct
end
if ~isequal(warning(),struct('identifier','all','state','on'))
    notAllWarningsShown = true;
    disp('Not all warnings are enabled.')
else
    notAllWarningsShown = false;
end
plotLog = false(2, 3) | plotLog; % Use implicit expansion to pad it
meanCalculationSymm = 'Bingham'; % For hemispherical scenarios. Options: meanShift, Bingham, meanDiection
plotRandomFilter = true;
omitSlow = false;
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
    warning('PlotResults:FewRuns', 'Using less than 1000 runs. This may lead to unreliable results');
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
if ~isempty(figHandles)
    for figNo = intersect([figHandles.Number], [1, 2, 3]) % Clear figures 1 to 3 (if they exist)
        clf(figNo, 'reset');
    end
end

fprintf('Using mode %s\n', [mode,linBoundedErrorMode]);

[distanceFunction, extractMean, errorLabel] = getDistanceFunMeanCalcAndLabel([mode,linBoundedErrorMode]);

plotFromZero = true;
timeLabel = 'Time taken in ms per time step';
% Divide by number of update steps (equal to number of time steps).
% Multiply with 1000 to get ms instead of seconds.
timesFactor = 1 / size(groundtruths{1}, 2) * 1000;

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
% Calculate mean (omit inf values of failed runs)
allErrors = arrayfun(@(i)mean([allDeviationsLast{i}{~isinf([allDeviationsLast{i}{:}])}]), 1:numel(allDeviationsLast));
allStds = arrayfun(@(i)std([allDeviationsLast{i}{:}]), 1:numel(allDeviationsLast));
allMeanTimes = cellfun(@(c)mean(c,'omitnan'), {results.timeTaken});

% If MTT: Output association quality
if size(groundtruths{1}, 3) > 1
    ass = NaN(numel(results), numel(results(1).associations));
    labelChange = NaN(numel(results), numel(results(1).associations));
    for config = 1:numel(results)
        for run = 1:numel(results(1).associations)
            ass(config, run) = sum(sum(reshape(1:size(results(config).associations{run}, 3), 1, 1, []) == results(config).associations{run}, 2));
            labelChange(config, run) = sum(sum(diff(results(config).associations{run}) ~= 0));
        end
        %fprintf('Correct: %s %d %5.5G\n',results(config).filterName,results(config).filterParams,mean(ass(config,:)));
        fprintf('Label switches: %s %d %5.5G\n', results(config).filterName, results(config).filterParams, mean(labelChange(config, :)));
    end
end

% To sort according to the desired order. Flip iff and sqff to
% ensure the dashed line for iff is not overdrawn by the solid line
% for sqff
supportedFiltersShortNames = {'se2ukfm', 'se2bf', 's3f', 'grid', 'iff', 'sqff', 'pf', 'htpf', 'vmf', 'bingham', 'wn', 'vm', 'twn', ...
    'kf', 'ishf', 'sqshf', 'htgf', 'sgf', 'hgf', 'hgfSymm', 'hhgf', 'randomTorus', 'randomSphere', 'fig', 'figResetOnPred'};
supportedFiltersLongNames = {'Unscented KF for Manifolds', '(Progressive) SE(2) Bingham filter', 'State space subdivision filter', 'Grid filter', 'Fourier identity filter', 'Fourier square root filter', 'Particle filter', 'Particle filter', ...
    'Von Mises--Fisher filter', 'Bingham filter', 'Wrapped normal filter', 'Von Mises filter', 'Bivariate WN filter', 'Kalman filter', ...
    'Spherical hamonics identity filter', 'Spherical hamonics square root filter', 'Hypertoroidal grid filter', ...
    'Spherical grid filter', 'Hyperspherical grid filter', ...
    'Symmetric hyperspherical grid filter', 'Hyperhemispherical grid filter', 'Random filter', 'Random filter',...
    'Fourier-interpreted grid filter', 'FIG-Filter with resetting on prediction'};

filterNames = supportedFiltersShortNames(ismember(supportedFiltersShortNames, {results.filterName}));
if numel(filterNames) < numel(unique({results.filterName}))
    warning('One of the filters is unknown');
end
paramTimeAndErrorPerFilter = struct('filterName', filterNames, 'allParams', [], 'meanTimesAllConfigs', [], 'meanErrorAllConfigs', []);
handlesErrorOverParam = [];
handlesTimeOverParam = [];
handlesErrorOverTime = [];
handlesAssociationErrorOverParam = [];

if sum(strcmp({results.filterName}, 'se2iukf')) == 1
    % Just one parameterization for the IUKF, we set it to NaN so it
    % works with all the other code
    results(strcmp({results.filterName}, 'se2iukf')).filterParams = NaN;
end
if plotFromZero && ~plotLog(1) % Plotting from zero for loglog is not possible
    minParam = 0;
else
    minParam = min([results.filterParams]);
end
maxParam = max([results.filterParams]);
for name = filterNames
	% Iterate over all possible names and plot the lines for those that were evaluated
    nameStr = [name{:}];
    switch nameStr
        case {'iff', 'ishf'}
            color = [0.4660, 0.6740, 0.1880];
            styleMarker = 'o';
            styleLine = '--';
        case {'discrete', 'bingham'}
            color = [0.8500, 0.3250, 0.0980];
        case {'sqff', 'sqshf'}
            color = [0, 0.4470, 0.7410];
            styleMarker = 'd';
            styleLine = '-';
        case {'pf', 'htpf'}
            color = [0.9290, 0.6940, 0.1250];
            styleMarker = 'p';
            styleLine = '-.';
        case {'wn', 'vm', 'vmf', 'hhgf', 'se2bf'}
            color = [0.4940, 0.1840, 0.5560];
            styleMarker = 'd';
            styleLine = '-';
        case {'random', 'dummy'}
            color = [0, 0, 0];
            styleMarker = 'x';
            styleLine = '-';
        case {'kf', 'se2iukf'}
            color = [0.3010, 0.7450, 0.9330];
            styleMarker = '*';
            styleLine = '-';
        case {'hgfSymm', 'figResetOnPred'}
            color = [0.3010, 0.7450, 0.9330];
            styleMarker = '';
            styleLine = '-';
        case {'sgf', 'hgf', 's3f', 'fig'}
            color = [0.6350, 0.0780, 0.1840];
            styleMarker = '*';
            styleLine = '-';
        case {'htgf'}
            color = [0.6350, 0.0780, 0.1840];
            styleMarker = '*';
            styleLine = '-.';
        otherwise
            color = 'k';
            styleMarker = '';
            styleLine = '-';
    end
    isCorrectFilter = strcmp({results.filterName}, nameStr);
    [paramsSorted, order] = sort([results(isCorrectFilter).filterParams]);
    if strncmp(nameStr, 'ff', 2) || strcmp(nameStr, 'htgf')
        paramsSorted = paramsSorted.^size(groundtruths{1}, 1);
    elseif contains(nameStr, 'shf')
        paramsSorted = (paramsSorted + 1).^2;
    end

    rmses = allErrors(isCorrectFilter);
    rmsesSorted = rmses(order);
    stds = allStds(isCorrectFilter);
    stdsSorted = stds(order);
    times = allMeanTimes(isCorrectFilter);
    timesSortedAndScaled = times(order) * timesFactor;
    figure(1)
    if ~any(isnan(paramsSorted)) && numel(paramsSorted) > 1
        if plotStds
            plot(paramsSorted, rmsesSorted-stdsSorted*0.05, 'color', color); hold on
            plot(paramsSorted, rmsesSorted+stdsSorted*0.05, 'color', color);
        end
        handlesErrorOverParam(end+1) = plot(paramsSorted, rmsesSorted, [styleMarker, styleLine], 'color', color); hold on %#ok<AGROW>
    else % If not parametric like wn or twn filter
        handlesErrorOverParam(end+1) = plot([minParam, maxParam], [rmsesSorted, rmsesSorted], styleLine, 'color', color); hold on %#ok<AGROW>
    end

    figure(2)
    if ~any(isnan(paramsSorted)) && numel(paramsSorted) > 1
        handlesTimeOverParam(end+1) = plot(paramsSorted, timesSortedAndScaled, [styleMarker, styleLine], 'color', color); hold on %#ok<AGROW>
    else
        if omitSlow && max(allMeanTimes(~isCorrectFilter)) < timesSortedAndScaled / 2
            handlesTimeOverParam(end+1) = missing; %#ok<AGROW>
            warning([nameStr, ' took very long (', num2str(timesSortedAndScaled), ' ms), not plotting it for additional clarity']);
        else
            handlesTimeOverParam(end+1) = plot([minParam, maxParam], [timesSortedAndScaled, timesSortedAndScaled], styleLine, 'color', color); hold on %#ok<AGROW>
        end
    end
    figure(3)
    if ~any(isnan(paramsSorted)) && numel(paramsSorted) > 1
        handlesErrorOverTime(end+1) = plot(timesSortedAndScaled, rmsesSorted, [styleMarker, styleLine], 'color', color); hold on %#ok<AGROW>
    else
        % If too far away, do not plot
        if omitSlow && max(allMeanTimes(~isCorrectFilter)) < timesSortedAndScaled / 1.5
            handlesErrorOverTime(end+1) = missing; %#ok<AGROW>
            warning([nameStr, ' took very long (', num2str(timesSortedAndScaled), ' ms), not plotting it for additional clarity']);
        else
            % Use symbol because no line for only one point
            handlesErrorOverTime(end+1) = plot(timesSortedAndScaled, rmsesSorted, styleMarker, 'color', color); hold on %#ok<AGROW>
        end
    end
    % Results for MTT
    if size(groundtruths{1}, 3) > 1
        figure(11)
        filterIndices = find(isCorrectFilter);
        if ~any(isnan(paramsSorted))
            handlesAssociationErrorOverParam(end+1) = plot(paramsSorted, mean(labelChange(filterIndices(order), :), 2), [styleMarker, styleLine], 'color', color); %#ok<AGROW>
        else
            handlesAssociationErrorOverParam(end+1) = plot([minParam, maxParam], ...
                mean(labelChange(filterIndices(order), :), 2)*ones(1, 2), [styleMarker, styleLine], 'color', color); %#ok<AGROW>
        end
        hold on
    end
    % Store results for filter
    [~, indexForStruct] = ismember(nameStr, {paramTimeAndErrorPerFilter.filterName});
    paramTimeAndErrorPerFilter(indexForStruct).allParams = paramsSorted;
    paramTimeAndErrorPerFilter(indexForStruct).meanTimesAllConfigs = timesSortedAndScaled;
    paramTimeAndErrorPerFilter(indexForStruct).meanErrorAllConfigs = rmsesSorted;
end

% Improve plots. Swap filter names to get iff to top
if (any(contains(filterNames, 'iff')) && any(contains(filterNames, 'sqff'))) || (any(contains(filterNames, 'ishf')) && any(contains(filterNames, 'sqshf')))
    filterNames([1, 2]) = filterNames([2, 1]);
    handlesErrorOverParam([1, 2]) = handlesErrorOverParam([2, 1]);
    handlesTimeOverParam([1, 2]) = handlesTimeOverParam([2, 1]);
    handlesErrorOverTime([1, 2]) = handlesErrorOverTime([2, 1]);
    if ~isempty(handlesAssociationErrorOverParam)
        handlesAssociationErrorOverParam([1, 2]) = handlesAssociationErrorOverParam([2, 1]);
    end
end
if (any(strcmp(filterNames, 'vm')) && any(strcmp(filterNames, 'kf')))
    vmIndex = find(strcmp(filterNames, 'vm'));
    kfIndex = find(strcmp(filterNames, 'kf'));
    if kfIndex < vmIndex
        filterNames([vmIndex, kfIndex]) = filterNames([kfIndex, vmIndex]);
        handlesErrorOverParam([vmIndex, kfIndex]) = handlesErrorOverParam([kfIndex, vmIndex]);
        handlesTimeOverParam([vmIndex, kfIndex]) = handlesTimeOverParam([kfIndex, vmIndex]);
        handlesErrorOverTime([vmIndex, kfIndex]) = handlesErrorOverTime([kfIndex, vmIndex]);
        if ~isempty(handlesAssociationErrorOverParam)
            handlesAssociationErrorOverParam([vmIndex, kfIndex]) = handlesAssociationErrorOverParam([kfIndex, vmIndex]);
        end
    end
end

filterFullNames = replace(filterNames, supportedFiltersShortNames, supportedFiltersLongNames);

figure(1);
ax(1) = gca;
if minParam == maxParam
    xlim([1, 1.1 * maxParam]);
elseif isnan(minParam)||isnan(maxParam)
    xlim([0,1]);
else
    xlim([minParam, maxParam]);
end
legend(handlesErrorOverParam, filterFullNames);
xlabel('Number of grid points/particles/coefficients');
ylabel(errorLabel);
title('Error over number of parameters');
figure(2);
ax(2) = gca;
if minParam == maxParam
    xlim([1, 1.1 * maxParam]);
elseif isnan(minParam)||isnan(maxParam)
    xlim([0,1]);
else
    xlim([minParam, maxParam]);
end
legend(handlesTimeOverParam(~isnan(handlesTimeOverParam)), filterFullNames(~isnan(handlesTimeOverParam)), 'Location', 'Northwest');
xlabel('Number of grid points/particles/coefficients');
ylabel(timeLabel);
title('Time over number of parameters')
figure(3);
ax(3) = gca;
if min(allMeanTimes) == max(allMeanTimes)
    xlim([0, max(allMeanTimes) * timesFactor]);
else
    xlim(minmax(allMeanTimes(~strcmp({results.filterName}, 'twn') & ~strcmp({results.filterName}, 'randomSphere') & ~strcmp({results.filterName}, 'randomTorus')))*timesFactor);
end
legend(handlesErrorOverTime(~isnan(handlesErrorOverTime)), filterFullNames(~isnan(handlesErrorOverTime)));
xlabel(timeLabel);
ylabel(errorLabel);
title('Error over time')
set([ax(plotLog(1, :)).XAxis], 'Scale', 'log')
for currAx = ax(plotLog(1, :))
    currAx.XLabel.String = [currAx.XLabel.String, ' (log scale)'];
end
set([ax(plotLog(2, :)).YAxis], 'Scale', 'log')
for currAx = ax(plotLog(2, :))
    currAx.YLabel.String = [currAx.YLabel.String, ' (log scale)'];
end
if notAllWarningsShown
    disp('-----------Reminder: Not all warnings were enabled.-----------')
end
end
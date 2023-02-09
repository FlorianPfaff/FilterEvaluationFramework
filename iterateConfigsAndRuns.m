function [results, groundtruths, measurements] = iterateConfigsAndRuns(scenarioParam, filters, noRuns, convertToPointEstimateDuringRuntime, extractAllPointEstimates, tolerateFailure, autoWarningOnOff)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
arguments (Input)
    scenarioParam (1,1) struct
    filters (1,:) struct
    noRuns (1,1) double {mustBeInteger, mustBePositive}
    convertToPointEstimateDuringRuntime (1,1) logical = false
    extractAllPointEstimates (1,1) logical = false
    tolerateFailure (1,1) logical = false
    autoWarningOnOff (1,1) logical = true
end
arguments (Output)
    results (1,:) struct
    groundtruths (:,1) cell
    measurements (:,:) cell
end
if extractAllPointEstimates
    warning('FilterEvaluationFramework:SlowdownExtractEstimates', 'Extracting all point estimates can have a massive impact on the run time. Use this for debugging only')
end

nConfigs = sum(cellfun(@numel, {filters.filterParams}));
t = NaN(nConfigs, noRuns);
groundtruths = cell(noRuns, 1);
measurements = cell(noRuns, scenarioParam.timesteps);
runFailed = false(nConfigs, noRuns);

if convertToPointEstimateDuringRuntime
    lastEstimates = cell(nConfigs, noRuns);
else
    lastFilterStates = cell(nConfigs, noRuns);
end
if extractAllPointEstimates
    lastEstimates = cell(nConfigs, noRuns); % Does not matter that we overwrite the above if convertToPointEstimateDuringRuntime is also true
    allEstimates = cell(nConfigs, noRuns);
end

currConfigIndex = 1;
for r = 1:noRuns
    % First generate groundtruth and measurements (create beforehand so we
    % can be sure they are identical even for filters that use the random
    % number generator)
    rng(scenarioParam.allSeeds(r));

    x0 = NaN(scenarioParam.initialPrior(1).dim, 1, scenarioParam.nTargets);
    for targetNo = 1:scenarioParam.nTargets
        x0(:, 1, targetNo) = scenarioParam.initialPrior(targetNo).sample(1);
    end
    % x0 is saved as well
    groundtruths{r} = generateGroundtruth(x0, scenarioParam);
    measurements(r, :) = generateMeasurements(groundtruths{r}, scenarioParam);
    assert(~scenarioParam.plot || all(size(measurements{r},1)==cellfun(@(measCell)size(measCell,1),measurements(r,:))),...
        'Plotting the states is currently only possible when measurements have the same dimensions.')
    assert(isequal(size(unique(reshape([measurements{r, :}], size([measurements{r, :}],1), [])', 'rows')),...
        size(reshape([measurements{r, :}], size([measurements{r, :}],1), [])')),...
        'Two identical measurements were generated. This should not happen, check your measurement generating function.');
end
rng('shuffle'); % We set the seed up there, so shuffle rng now to prevent deterministic behavior of the filters
for filterNo = 1:numel(filters)
    for config = 1:numel(filters(filterNo).filterParams)
        filterParam = struct('name', filters(filterNo).name, 'parameter', filters(filterNo).filterParams(config));
        % Clear global variables to prevent stuff from accumulating
        clear -global xyz2plm plm2xyz
        % Precalculate expensive stuff (do not initialize filters to
        % avoid, e.g., particle filter from becoming deterministic.
        fprintf('filter %i (%s) config %i (%i) performing precalculations\n', filterNo, filters(filterNo).name, config, filters(filterNo).filterParams(config));
        precalculatedParams = precalculateParams(scenarioParam, filterParam);
        % Do a run before to prevent variation in run times
        fprintf('filter %i (%s) config %i (%i) doing dry run\n', filterNo, filters(filterNo).name, config, filters(filterNo).filterParams(config));
        if autoWarningOnOff, warning('on'), end % Allow warnings in dry run to see if anything may be wrong.
        % Use last scenario to prevent gaining an advantage by having the same inputs in the next run
%         try
            timeForPreload = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, end}, measurements(end, :), precalculatedParams);
%         catch err
%             if ~tolerateFailure
%                 rethrow(err);
%             end
%             timeForPreload = 1;
%             warning('Precalculation run failed')
%         end
        if timeForPreload < 0.01, plotEvery = 1000;
        elseif timeForPreload < 0.1, plotEvery = 100;
        elseif timeForPreload < 1, plotEvery = 10;
        else, plotEvery = 1;
        end

        if autoWarningOnOff, warning('off'), end
        for r = 1:noRuns
            if mod(r-1, plotEvery) == 0
                fprintf('filter %i (%s) config %i (%i) run %i\n', filterNo, filters(filterNo).name, config, filters(filterNo).filterParams(config), r);
            end
            try
                if ~convertToPointEstimateDuringRuntime && ~extractAllPointEstimates
                    % Only save filter states, nothing else
                    [t(currConfigIndex, r), lastFilterStates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{r}, measurements(r, :), precalculatedParams);
                elseif ~convertToPointEstimateDuringRuntime && extractAllPointEstimates
                    % We still want to the save the filter states, but we
                    % get the last etimates for free since all point
                    % estimates should be extracted. Thus, we save them.
                    [t(currConfigIndex, r), lastFilterStates{currConfigIndex, r}, lastEstimates{currConfigIndex, r}, allEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{r}, measurements(r, :), precalculatedParams);
                elseif convertToPointEstimateDuringRuntime && ~extractAllPointEstimates
                    [t(currConfigIndex, r), ~, lastEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{r}, measurements(r, :), precalculatedParams);
                elseif convertToPointEstimateDuringRuntime && extractAllPointEstimates
                    [t(currConfigIndex, r), ~, lastEstimates{currConfigIndex, r}, allEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{r}, measurements(r, :), precalculatedParams);
                else
                    error('This should not happen.');
                end
            catch err
                if ~tolerateFailure
                    rethrow(err);
                end
                if autoWarningOnOff, warning('on'), end
                runFailed(currConfigIndex, r) = true;
                warning('filter %i config %i run %i FAILED: %s\n', filterNo, config, r, err.message);
                if autoWarningOnOff, warning('off'), end
            end
            if mod(r-1, plotEvery) == 0
                fprintf('Time taken for run %d: %5.5G\n', r, t(currConfigIndex, r))
            end
        end
        currConfigIndex = currConfigIndex + 1;
    end
end
assert(all(all(isnan(t) == runFailed)), 'Measured times should not be nan if the rund did not fail.');
% The line below prevents that we do not notice that some filter is broken.
assert(~any(all(runFailed,2)), 'All configs of a certain filter configuration failed. Check if this is plausible and disable the config if it is plausible that it always fails.');
% Repmat for ground truth and measurements to save identical ground truth to all configs
% in struct
% Create struct from info
namesRepeated = cellfun(@(fname, fparam){repmat({fname}, 1, numel(fparam))}, {filters.name}, {filters.filterParams});
allNames = [namesRepeated{:}];
results = struct('filterName', allNames, 'filterParams', num2cell(cell2mat({filters.filterParams})), ...
    'timeTaken', num2cell(t, 2)');
if ~convertToPointEstimateDuringRuntime
    if numel(lastFilterStates{1, 1})>1
        % Reshape to the size according to the convention we use
        assert(contains(scenarioParam.manifoldType, 'MTT'), 'Multiple states were returned in a single run for a single-target scenario. This is unexpected.');
        lastFilterStates = cellfun(@(state){reshape(state,1,1,[])},lastFilterStates);
    end
    assert(numel(results)==size(lastFilterStates,1));
    lastFilterStatesCellArranged = arrayfun(@(i)[lastFilterStates{i, :}], 1:size(lastFilterStates,1), 'UniformOutput', false);
    [results.lastFilterStates] = lastFilterStatesCellArranged{:};
end
if convertToPointEstimateDuringRuntime || extractAllPointEstimates
    % We have the last point estimates, save them
    lastEstCell = mat2cell(lastEstimates', noRuns, ones(1, nConfigs));
    [results.lastEstimates] = lastEstCell{:};
end
if extractAllPointEstimates
    % We have the last point estimates, save them
    allEstCell = mat2cell(allEstimates', noRuns, ones(1, nConfigs));
    [results.allEstimates] = allEstCell{:};
end
end

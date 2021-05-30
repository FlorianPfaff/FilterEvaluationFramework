function [results, groundtruths, measurements] = iterateConfigsAndRuns(scenarioParam, filters, noRuns, convertToPointEstimateDuringRuntime, extractAllPointEstimates, tolerateFailure)
arguments
    scenarioParam struct
    filters struct
    noRuns(1, 1) double {mustBeInteger, mustBePositive}
    convertToPointEstimateDuringRuntime(1, 1) logical = false
    extractAllPointEstimates(1, 1) logical = false
    tolerateFailure(1, 1) logical = false
end
if extractAllPointEstimates
    warning('Extracting all point estimates can have a massive impact on the run time. Use this for debugging only')
end

nConfigs = sum(cellfun(@numel, {filters.filterParams}));
t = NaN(nConfigs, noRuns);
groundtruths = cell(1, noRuns);
measurements = cell(1, noRuns);
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
    x0 = scenarioParam.initialPrior.sample(1);
    % x0 is saved as well
    groundtruths{1, r} = generateGroundtruth(x0, scenarioParam);
    measurements{1, r} = generateMeasurements(groundtruths{1, r}, scenarioParam);
end
rng('shuffle'); % We set the seed up there, so shuffle rng now to prevent deterministic behavior of the filters
for filterNo = 1:numel(filters)
    for config = 1:numel(filters(filterNo).filterParams)
        filterParam = struct('name', filters(filterNo).name, 'parameter', filters(filterNo).filterParams(config));
        % Clear global variables to prevent stuff from accumulating
        clear -global xyz2plm plm2xyz
        % Precalculate expensive stuff (do not initialize filters to
        % avoid, e.g., particle filter from becoming deterministic.
        fprintf('filter %i config %i performing precalculations\n', filterNo, config);
        precalculatedParams = precalculateParams(scenarioParam, filterParam);
        % Do a run before to prevent variation in run times
        fprintf('filter %i config %i doing dry run\n', filterNo, config);
        warning on % Allow warnings in dry run to see if anything may be wrong.
        % Use last scenario to prevent gaining an advantage by having the same inputs in the next run
        try
            timeForPreload = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, end}, measurements{1, end}, precalculatedParams);
        catch err
            if ~tolerateFailure
                rethrow(err);
            end
            timeForPreload = 1;
            warning('Precalculation run failed')
        end
        if timeForPreload < 0.01, plotEvery = 1000;
        elseif timeForPreload < 0.1, plotEvery = 100;
        elseif timeForPreload < 1, plotEvery = 10;
        else, plotEvery = 1;
        end

        warning off
        for r = 1:noRuns
            if mod(r-1, plotEvery) == 0
                fprintf('filter %i config %i run %i\n', filterNo, config, r);
            end
            try
                if ~convertToPointEstimateDuringRuntime && ~extractAllPointEstimates
                    % Only save filter states, nothing else
                    [t(currConfigIndex, r), lastFilterStates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, r}, measurements{1, r}, precalculatedParams);
                elseif ~convertToPointEstimateDuringRuntime && extractAllPointEstimates
                    % We still want to the save the filter states, but we
                    % get the last etimates for free since all point
                    % estimates should be extracted. Thus, we save them.
                    [t(currConfigIndex, r), lastFilterStates{currConfigIndex, r}, lastEstimates{currConfigIndex, r}, allEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, r}, measurements{1, r}, precalculatedParams);
                elseif convertToPointEstimateDuringRuntime && ~extractAllPointEstimates
                    [t(currConfigIndex, r), ~, lastEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, r}, measurements{1, r}, precalculatedParams);
                elseif convertToPointEstimateDuringRuntime && extractAllPointEstimates
                    [t(currConfigIndex, r), ~, lastEstimates{currConfigIndex, r}, allEstimates{currConfigIndex, r}] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruths{1, r}, measurements{1, r}, precalculatedParams);
                else
                    error('This should not happen.');
                end
            catch err
                if ~tolerateFailure
                    rethrow(err);
                end
                warning on
                runFailed(currConfigIndex, r) = true;
                warning('filter %i config %i run %i FAILED\n', filterNo, config, r);
                warning off
            end
            if mod(r-1, plotEvery) == 0
                fprintf('Time taken for run %d: %5.5G\n', r, t(currConfigIndex, r))
            end
        end
        currConfigIndex = currConfigIndex + 1;
    end
end
assert(all(all(isnan(t) == runFailed)), 'Measured times should not be nan if the rund id not fail.');
% Repmat for ground truth and measurements to save identical ground truth to all configs
% in struct
% Create struct from info
namesRepeated = cellfun(@(fname, fparam){repmat({fname}, 1, numel(fparam))}, {filters.name}, {filters.filterParams});
allNames = [namesRepeated{:}];
results = struct('filterName', allNames, 'filterParams', num2cell(cell2mat({filters.filterParams})), ...
    'timeTaken', num2cell(t, 2)');
if ~convertToPointEstimateDuringRuntime
    lastFilterStatesCellArranged = arrayfun(@(i)[lastFilterStates{i, :}]', 1:size(lastFilterStates, 1), 'UniformOutput', false);
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

function startEvaluation(scenario, filters, noRuns, opt)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
% V2.14
arguments
    scenario char
    % Struct with filternames and number of parameters. See
    % FilterEvaluationTest for examples
    filters (1,:) struct {mustBeNonempty}
    noRuns (1, 1) double
    opt.saveFolder char = '.'
    opt.plotEachStep (1, 1) logical = false % Useful for debugging
    % This allows generating the final estimate directly from the filter
    % state. For hyperhemispherical filters, this may not be a good idea
    % because different ways to extract the point estimate exist.
    % However, not storting the filter state saved a lot of RAM and file
    % size
    opt.convertToPointEstimateDuringRuntime (1, 1) logical = false
    opt.extractAllPointEstimates (1, 1) logical = false
    opt.scenarioCustomizationParams = [] % Optional scenario Parameters
    opt.tolerateFailure (1, 1) logical = false
    % Use unit32 to avoid the bad case seed=0, which can happen when uint32 is cast to double
    opt.initialSeed (1, 1) uint32 {mustBePositive} = RandStream.create('mrg32k3a', 'Seed', 'Shuffle').Seed
    % This can make sense if you want to guarantee there is no overlap by
    % setting numbers manually.
    opt.consecutiveSeed (1,1) logical = false
    % For real evaluations, warnings are turned off (except for the preload
    % run that is not considered). For debugging or for test cases, it can
    % be valuable to be able to control warnings manually.
    opt.autoWarningOnOff (1, 1) logical = false % Useful for debugging
end
[saveFolder, plotEachStep, convertToPointEstimateDuringRuntime, extractAllPointEstimates, scenarioCustomizationParams, tolerateFailure, initialSeed] = ...
    deal(opt.saveFolder, opt.plotEachStep, opt.convertToPointEstimateDuringRuntime, ...
    opt.extractAllPointEstimates, opt.scenarioCustomizationParams, opt.tolerateFailure, opt.initialSeed);
assert(numel(unique({filters.name}))==numel({filters.name}), 'One filter was chosen more than once. To use the filter with different configurations, pass an array of parameters instead.');
% Scenario: Name of scenario or entire parameterization
% filters: struct of cellstring with names and params.
if isstruct(scenario)
    scenarioParam = scenario;
    scenarioParam.name = 'custom';
else % Lookup information for scenario and set/overwrite parameters.
    scenarioParam = scenarioDatabase(scenario, scenarioCustomizationParams);
    scenarioParam.name = scenario;
end
scenarioParam.plot = plotEachStep;
scenarioParam = checkAndFixParams(scenarioParam);
if opt.consecutiveSeed
    scenarioParam.allSeeds = initialSeed:initialSeed + noRuns - 1;
else
    tmpStream = RandStream.create('mrg32k3a', 'Seed', initialSeed);
    scenarioParam.allSeeds = tmpStream.randi(intmax,[1,noRuns]);
end
% Generate all estimates by iterating over all filters and configurations.
[results, groundtruths, measurements] = iterateConfigsAndRuns(scenarioParam, ...
    filters, noRuns, convertToPointEstimateDuringRuntime,...
    extractAllPointEstimates, tolerateFailure, opt.autoWarningOnOff);

% Save results
dateAndTime = datetime;
filename = fullfile(saveFolder, sprintf([scenarioParam.name, '%5d-%02d-%02d--%02d-%02d-%02d.mat'], dateAndTime.Year, dateAndTime.Month, dateAndTime.Day, dateAndTime.Hour, dateAndTime.Minute, floor(dateAndTime.Second)));
[~, hostname] = system('hostname');
save(filename, 'groundtruths', 'measurements', 'results', 'scenarioParam', 'hostname', '-v7.3');
% Plot results
assignin('base', 'results', results);
assignin('base', 'groundtruths', groundtruths);
assignin('base', 'scenarioParam', scenarioParam);
end
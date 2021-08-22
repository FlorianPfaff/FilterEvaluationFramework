function [timeElapsed, lastFilterState, lastEstimate, allEstimates] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruth, measurements, precalculatedParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.1
arguments
    scenarioParam struct {mustBeNonempty}
    filterParam struct {mustBeNonempty}
    groundtruth double {mustBeNonempty}
    measurements double {mustBeNonempty}
    precalculatedParams struct = struct()
end
% Configure filter
[filter, predictionRoutine, likelihoodsForFilter, measNoiseForFilter] = configureForFilter(filterParam, scenarioParam, precalculatedParams);
cumulatedUpdatesPreferred = (contains(filterParam.name, 'shf')); % Currently this only provides an advantage for the shf

performCumulativeUpdates = cumulatedUpdatesPreferred && scenarioParam.measPerStep>1;
if cumulatedUpdatesPreferred && scenarioParam.measPerStep>1 && scenarioParam.plot % Disable when plotting
    warning('EvalFramework:FuseSquentiallyForPlot', 'When plotting, measurements are fused sequentially.');
    warning('off', 'EvalFramework:FuseSquentiallyForPlot');
    performCumulativeUpdates = false;
end

if scenarioParam.plot
    plotFilterState(filter, groundtruth, measurements, 1, 0);
end
allEstimates = NaN(size(groundtruth));
tic;
% Perform evaluation
for t = 1:scenarioParam.timesteps
    %% Update
    if performCumulativeUpdates
        nUpdates = 1;
        % Use all measurements
        currMeas = num2cell(measurements(:, (t - 1) * scenarioParam.measPerStep + 1:t * scenarioParam.measPerStep));
    else
        nUpdates = scenarioParam.measPerStep;
        currMeas = measurements(:, (t - 1)*scenarioParam.measPerStep+1);
    end
    for m = 1:nUpdates
        if ~scenarioParam.useLikelihood
            assert(~performCumulativeUpdates, 'Cumulative updates only supported when using likelihoods');
            filter.updateIdentity(measNoiseForFilter, currMeas);
        elseif performCumulativeUpdates
            % Only for filters that handle multiple update steps at
            % once better than consective steps. This can only be used if
            % the result should not be visualized. All update steps are
            % assumed to use the same likelihood.
            filter.updateNonlinear(likelihoodsForFilter((t - 1) * scenarioParam.measPerStep + 1:t * scenarioParam.measPerStep), currMeas);
        elseif isfield(scenarioParam, 'likelihoodGenerator')
            likelihood = scenarioParam.likelihoodGenerator(currMeas);
            filter.updateIdentity(likelihood);
        elseif strcmpi(filterParam.name, 's3f')
            filter.update([], GaussianDistribution(currMeas, scenarioParam.gaussianMeasNoise.C))
        elseif strcmpi(filterParam.name, 'se2iukf')
            filter.updatePositionMeasurement(scenarioParam.gaussianMeasNoise.C, currMeas)
        elseif ~strcmpi(filterParam.name, 'bingham')
            filter.updateNonlinear(likelihoodsForFilter{t}, currMeas);
        else
            error('Unsupported configuration.');
        end
        if scenarioParam.plot
            plotFilterState(filter, groundtruth, measurements, t, m);
        end
        if m~=nUpdates % If not last measurement, next one is current one.
            currMeas = measurements(:, (t - 1)*scenarioParam.measPerStep+m+1);
        end
    end

    %% Save results only when they are asked for because it takes time
    if nargout == 4 || scenarioParam.plot
        allEstimates(:, t) = filter.getPointEstimate();
    end

    %% Predict
    if scenarioParam.applySysNoiseTimes(t) % Per default, no prediction is performed in the last time step
        predictionRoutine();
        if scenarioParam.plot && t ~= scenarioParam.timesteps % No gt for timeesteps+1 so cannot plot then
            plotFilterState(filter, groundtruth, measurements, t+1, 0);
        end
    end
end
timeElapsed = toc;
lastFilterState = filter.getEstimate();
if nargout == 4
    % We have allEstimates, get this as last one
    lastEstimate = allEstimates(:, end);
elseif nargout == 3
    % We still need to extract it
    lastEstimate = filter.getPointEstimate();
end
end
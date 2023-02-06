function [timeElapsed, lastFilterState, lastEstimate, allEstimates] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruth, measurements, precalculatedParams, cumulatedUpdatesPreferred)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
arguments (Input)
    scenarioParam (1,1) struct {mustBeNonempty}
    filterParam (1,1) struct {mustBeNonempty}
    groundtruth double {mustBeNonempty}
    measurements (1,:) cell {mustBeNonempty}
    precalculatedParams struct = struct()
    cumulatedUpdatesPreferred (1,1) logical = (contains(filterParam.name, 'shf')); % Currently this only provides an advantage for the shf
end
arguments (Output)
    timeElapsed (1,1) double
    lastFilterState % Can be AbstractDistribution but need not be one if Filter is parametrized differently
    lastEstimate (:,1) double
    allEstimates % Only set if all should be extracted
end
% Configure filter
[filter, predictionRoutine, likelihoodsForFilter, measNoiseForFilter] = configureForFilter(filterParam, scenarioParam, precalculatedParams);

% Can only update cumulatively if multiple measurements are obtained 
performCumulativeUpdates = cumulatedUpdatesPreferred && any(scenarioParam.nMeasAtIndividualTimeStep>1);
if cumulatedUpdatesPreferred && any(scenarioParam.nMeasAtIndividualTimeStep>1) && scenarioParam.plot % Disable when plotting
    warning('EvalFramework:FuseSquentiallyForPlot', 'When plotting, measurements are fused sequentially.');
    warning('off', 'EvalFramework:FuseSquentiallyForPlot');
    performCumulativeUpdates = false;
end

if scenarioParam.plot
    plotFilterStateAndGt(filter, groundtruth, [measurements{:}], 1, 0);
end
allEstimates = NaN(size(groundtruth));
tic;
% Perform evaluation
for t = 1:scenarioParam.timesteps
    %% Update
    if performCumulativeUpdates
        % Only for filters that handle multiple update steps at
        % once better than consective steps. This can only be used if
        % the result should not be visualized. All update steps are
        % assumed to use the same likelihood.
        % Use all measurements
        assert(scenarioParam.useLikelihood, 'Cumulative updates only supported when using likelihoods');
        allMeasCurrTimeStepCell = num2cell(measurements{1, t});
        filter.updateNonlinear(likelihoodsForFilter{t}, allMeasCurrTimeStepCell);
    else
        nUpdates = scenarioParam.nMeasAtIndividualTimeStep(t);
        allMeasCurrTimeStep = measurements{t};
        for m = 1:nUpdates
            currMeas = allMeasCurrTimeStep(:, m);
            if ~scenarioParam.useLikelihood
				filter.updateIdentity(measNoiseForFilter, currMeas);
			elseif isfield(scenarioParam, 'likelihoodGenerator')
			    likelihood = scenarioParam.likelihoodGenerator(currMeas);
                filter.updateIdentity(likelihood);
            elseif strcmpi(filterParam.name, 's3f')
                filter.update([], GaussianDistribution(currMeas, scenarioParam.gaussianMeasNoise.C))
            elseif strcmpi(filterParam.name, 'se2ukfm')
                filter.updatePositionMeasurement(scenarioParam.gaussianMeasNoise.C, currMeas)
            elseif ~strcmpi(filterParam.name, 'bingham')
                filter.updateNonlinear(likelihoodsForFilter{t}{m}, currMeas);
            else
                error('Unsupported configuration.');
            end
        end
        if scenarioParam.plot
            plotFilterStateAndGt(filter, groundtruth, [measurements{:}], t, m);
        end
    end

    %% Save results only when they are asked for because it takes time
    if nargout == 4 || scenarioParam.plot
        allEstimates(:, t) = filter.getPointEstimate();
    end

    %% Predict
    if scenarioParam.applySysNoiseTimes(t) % Per default, no prediction is performed in the last time step
        if isempty(scenarioParam.inputs)
            predictionRoutine();
        else
            predictionRoutine(scenarioParam.inputs(:,t));
        end
        if scenarioParam.plot && t ~= scenarioParam.timesteps % No gt for timeesteps+1 so cannot plot then
            plotFilterStateAndGt(filter, groundtruth, [measurements{:}], t+1, 0);
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
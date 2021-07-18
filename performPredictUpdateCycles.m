function [timeElapsed, lastFilterState, lastEstimate, allEstimates] = performPredictUpdateCycles(scenarioParam, filterParam, groundtruth, measurements, precalculatedParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
arguments
    scenarioParam struct {mustBeNonempty}
    filterParam struct {mustBeNonempty}
    groundtruth double {mustBeNonempty}
    measurements double {mustBeNonempty}
    precalculatedParams struct = struct()
end
% Configure filter
[filter, predictionRoutine] = configureForFilter(filterParam, scenarioParam, precalculatedParams);
cumulatedUpdatesPreferred = (contains(filterParam.name, 'shf')); % Currently this only provides an advantage for the shf

if scenarioParam.useLikelihood && isfield(scenarioParam, 'likelihood') && ~iscell(scenarioParam.likelihood)
    scenarioParam.likelihood = repmat({scenarioParam.likelihood}, 1, scenarioParam.timesteps);
end

if scenarioParam.plot
    plotFilterState(filter, groundtruth, measurements, 1, 0);
end
allEstimates = NaN(size(groundtruth));
tic;
% Perform evaluation
for t = 1:scenarioParam.timesteps

    %% Update
    if contains(scenarioParam.name, 'rotate') && (contains(filterParam.name, 'sqff'))
        outputData = scenarioParam.likelihoodCoeffsGenerator(measurements(:, t));
        if contains(scenarioParam.netPath, 'Real')
            likelihood = FourierDistribution(outputData(1, 1:(size(outputData, 2) + 1) / 2), ...
                outputData(1, (size(outputData, 2) + 1) / 2 + 1:end), 'sqrt');
        elseif contains(scenarioParam.netPath, 'Complex')
            a = 2 * outputData(1, 1:(size(outputData, 2) + 1)/2);
            b = -2 * outputData(1, (size(outputData, 2) + 1)/2+1:end);
            likelihood = FourierDistribution(a, b, 'sqrt');
        else
            error('Unknown mode')
        end
        assert(isequal(size(likelihood.a), size(filter.getEstimate().a)));
        filter.updateIdentity(likelihood);
    elseif ~scenarioParam.plot && (contains(filterParam.name, 'shf')) && scenarioParam.measPerStep>1
        % Only for filters that handle multiple update steps at
        % once better than consective steps. This can only be used if
        % the result should not be visualized. All update steps are
        % assumed to use the same likelihood.
        filter.updateNonlinear(repmat(scenarioParam.likelihood(t), 1, scenarioParam.measPerStep), ...
            num2cell(measurements(:, (t - 1) * scenarioParam.measPerStep + 1:t * scenarioParam.measPerStep)));
    else
        if (contains(filterParam.name, 'shf')) && scenarioParam.measPerStep>1
            warning('EvalFramework:FuseSquentiallyForPlot', 'When plotting, fuse measurements sequentially');
            warning('off', 'EvalFramework:FuseSquentiallyForPlot');
        end
        for m = 1:scenarioParam.measPerStep
            currMeas = measurements(:, (t - 1)*scenarioParam.measPerStep+m);
            if strcmpi(filterParam.name, 's3f')
                filter.update([], GaussianDistribution(currMeas, scenarioParam.gaussianMeasNoise.C))
            elseif strcmpi(filterParam.name, 'se2iukf')
                filter.updatePositionMeasurement(scenarioParam.gaussianMeasNoise.C, currMeas)
            elseif scenarioParam.useLikelihood && ~strcmpi(filterParam.name, 'bingham')
                filter.updateNonlinear(scenarioParam.likelihood{t}, currMeas);
            end
            if scenarioParam.plot
                plotFilterState(filter, groundtruth, measurements, t, m);
            end
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
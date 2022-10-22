function measurements = generateMeasurements(groundtruth, scenarioParam)
% Generates measurements
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.9
if isfield(scenarioParam, 'measGenerator')
    if numel(scenarioParam.measGenerator) == 1 && scenarioParam.timesteps > 1 % If only one given, repeat in cell array
        measGenCell = repmat({scenarioParam.measGenerator}, 1, scenarioParam.timesteps);
    else
        assert(numel(scenarioParam.measGenerator) == scenarioParam.timesteps);
        measGenCell = scenarioParam.measGenerator;
    end
    measEqOutputSize = numel(measGenCell{1}(groundtruth(:, 1)));
    measurements = NaN(measEqOutputSize, scenarioParam.timesteps*scenarioParam.measPerStep);
    for t = 1:scenarioParam.timesteps % Apply measEq in every time step
        for m = 1:scenarioParam.measPerStep
            measurements(:, (t - 1)*scenarioParam.measPerStep+m) = measGenCell{t}(groundtruth(:, t));
        end
    end
else
    if isa(scenarioParam.measNoise, 'AbstractHypertoroidalDistribution')
        measurements = mod(groundtruth+scenarioParam.measNoise.sample(scenarioParam.timesteps * scenarioParam.measPerStep), 2*pi);
    elseif isa(scenarioParam.measNoise, 'VMFDistribution') || isa(scenarioParam.measNoise, 'WatsonDistribution')
        assert(isequal(scenarioParam.measNoise.mu, [0; 0; 1]));
        measurements = NaN(size(groundtruth, 1), scenarioParam.timesteps*scenarioParam.measPerStep);
        currDist = scenarioParam.measNoise;
        for t = 1:scenarioParam.timesteps % Apply measEq in every time step
            currDist.mu = groundtruth(:, t); % Currently only works for VMF
            measurements(:, ((t - 1) * scenarioParam.measPerStep + 1):(t * scenarioParam.measPerStep)) = currDist.sample(scenarioParam.measPerStep);
        end
    elseif isa(scenarioParam.measNoise, 'GaussianDistribution')
        measurements = groundtruth+scenarioParam.measNoise.sample(scenarioParam.timesteps * scenarioParam.measPerStep);
    end
end
end
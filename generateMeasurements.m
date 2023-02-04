function measurements = generateMeasurements(groundtruth, scenarioParam)
% Generates measurements
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
% V3.0
arguments (Input)
    groundtruth double
    scenarioParam (1,1) struct
end
arguments (Output)
    measurements (1,:) cell
end
measurements = cell(1,scenarioParam.timesteps);
if isfield(scenarioParam, 'measGenerator')
    % Measurement generator can differ for different time steps and
    % measurements in one time step. If fewer measurement generators are
    % given repeat them.
    nMeasUpUntilTimeStep = [0, cumsum(scenarioParam.nMeasAtIndividualTimeStep)]; 
    if numel(scenarioParam.measGenerator) == 1 % If only one given, repeat in cell array
        measGenCell = repmat({scenarioParam.measGenerator}, 1, nMeasUpUntilTimeStep(end));
    elseif numel(scenarioParam.measGenerator) == scenarioParam.timesteps
        % Repeat according to number of measurements in the respective time
        % step.
        measGenDobuleCell = arrayfun(@(i)repmat(scenarioParam.measGenerator(i),...
                [1,scenarioParam.nMeasAtIndividualTimeStep(i)]),...
            1:numel(scenarioParam.measGenerator),'UniformOutput',false);
        measGenCell = [measGenDobuleCell{:}];
    elseif all(scenarioParam.nMeasAtIndividualTimeStep(1) == scenarioParam.nMeasAtIndividualTimeStep)...
            && numel(scenarioParam.measGenerator) == scenarioParam.nMeasAtIndividualTimeStep(1)
        % If the number of measurement generators is equal to the number of
        % measurements in one time step (must be the same for all time
        % steps), repeat according to the number of time steps.
        measGenCell = repmat(scenarioParam.measGenerator, [1,scenarioParam.timesteps]);
    elseif numel(scenarioParam.measGenerator) == nMeasUpUntilTimeStep(end)
        measGenCell = scenarioParam.measGenerator;
    else
        error('Size of scenarioParam.measGenerator is incompatible with the number of time steps or measurements per time step.');
    end
    measEqOutputSize = numel(measGenCell{1}(groundtruth(:, 1)));
    measurements = cell(1, scenarioParam.timesteps);
    for t = 1:scenarioParam.timesteps % Apply measEq in every time step
        measurements{t} = NaN(measEqOutputSize, scenarioParam.nMeasAtIndividualTimeStep(t));
        for m = 1:scenarioParam.nMeasAtIndividualTimeStep(t)
            measurements{t}(:,m) = measGenCell{nMeasUpUntilTimeStep(t)+m}(groundtruth(:, t));
        end
    end
else
    for t = 1:scenarioParam.timesteps
        % When no measurement generator is given, only additive noise is
        % assumed, i.e., the dimension of the measurements is equal 
        if isa(scenarioParam.measNoise, 'AbstractHypertoroidalDistribution')
            measurements{t} = mod(repmat(groundtruth(:,t), [1, scenarioParam.nMeasAtIndividualTimeStep(t)])...
                + scenarioParam.measNoise.sample(scenarioParam.nMeasAtIndividualTimeStep(t)), 2*pi);
        elseif isa(scenarioParam.measNoise, 'VMFDistribution') || isa(scenarioParam.measNoise, 'WatsonDistribution')
            assert(isequal(scenarioParam.measNoise.mu, [0; 0; 1]));
            measurements{t} = NaN([size(groundtruth(1,:),1), scenarioParam.nMeasAtIndividualTimeStep(t)]);
            currDist = scenarioParam.measNoise;
            currDist.mu = groundtruth(:, t);
            measurements{t} = currDist.sample(scenarioParam.nMeasAtIndividualTimeStep(t));
        elseif isa(scenarioParam.measNoise, 'GaussianDistribution')
            measurements{t} = repmat(groundtruth(:,t), [1, scenarioParam.nMeasAtIndividualTimeStep(t)])...
                + scenarioParam.measNoise.sample(scenarioParam.nMeasAtIndividualTimeStep(t));
        end
    end
end
cellfun(@(measCell)mustBeNonNan(measCell), measurements);
end
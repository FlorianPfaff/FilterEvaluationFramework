function groundtruth = generateGroundtruth(x0, scenarioParam)
% x0 is startingpoint. SysNoiseOrGenNext is either the system noise or
% a function generating the next point (including the noise!).
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
arguments (Input)
    x0 (:,1,:) double
    scenarioParam (1,1) struct
end
arguments (Output)
    groundtruth (:,:,:) double
end
assert(size(x0,3) == scenarioParam.nTargets);
groundtruth = NaN([size(x0,1), scenarioParam.timesteps, scenarioParam.nTargets]);
for targetNo = 1:scenarioParam.nTargets
    groundtruth(:, 1, targetNo) = x0(:, :, targetNo);
    assert(isempty(scenarioParam.inputs) || size(scenarioParam.inputs,2)==scenarioParam.timesteps-1)
    if isfield(scenarioParam, 'genNextStateWithNoise')
        for t = 2:scenarioParam.timesteps
            if isempty(scenarioParam.inputs)
                groundtruth(:, t, targetNo) = scenarioParam.genNextStateWithNoise(groundtruth(:, t - 1, targetNo));
            else
                groundtruth(:, t, targetNo) = scenarioParam.genNextStateWithNoise(groundtruth(:, t - 1, targetNo), scenarioParam.inputs(:,t-1));
            end
        end
    elseif isfield(scenarioParam, 'sysNoise') % If sysnoise given, shift by prediction and then sample from sysnoise
        for t = 2:scenarioParam.timesteps
            if isfield(scenarioParam, 'genNextStateWithoutNoise')
                if isempty(scenarioParam.inputs)
                    stateToAddNoiseTo = scenarioParam.genNextStateWithoutNoise(groundtruth(:, t-1, targetNo));
                else
                    stateToAddNoiseTo = scenarioParam.genNextStateWithoutNoise(groundtruth(:, t-1, targetNo), scenarioParam.inputs(:,t-1));
                end
            else
                assert(isempty(scenarioParam.inputs), 'No inputs accepted for identity system model.')
                stateToAddNoiseTo  = groundtruth(:, t-1, targetNo);
            end
            if isa(scenarioParam.sysNoise, 'AbstractHypertoroidalDistribution')
                groundtruth(:, t, targetNo) = stateToAddNoiseTo + scenarioParam.sysNoise.sample(1);
            elseif isa(scenarioParam.sysNoise, 'VMFDistribution')
                assert(isequal(scenarioParam.sysNoise.mu, [0; 0; 1]));
                sysNoise = scenarioParam.sysNoise;
                sysNoise.mu = stateToAddNoiseTo;
                groundtruth(:, t, targetNo) = sysNoise.sample(1);
            elseif ismethod(scenarioParam.sysNoise, 'shift')
                sysNoise = scenarioParam.sysNoise;
                sysNoise = sysNoise.shift(stateToAddNoiseTo);
                groundtruth(:, t, targetNo) = sysNoise.sample(1);
            else
                error('SysNoise not supported')
            end
        end
    else
        error('Cannot generate groundtruth.');
    end
end
end
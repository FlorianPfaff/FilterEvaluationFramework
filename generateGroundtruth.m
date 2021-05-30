function groundtruth = generateGroundtruth(x0, scenarioParam)
% x0 is startingpoint. SysNoiseOrGenNext is either the system noise or
% a function generating the next point (including the noise!).
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
groundtruth(:, 1) = x0;
if isfield(scenarioParam, 'genNextStateWithNoise')
    for t = 2:scenarioParam.timesteps
        groundtruth(:, t) = scenarioParam.genNextStateWithNoise(groundtruth(:, t - 1));
    end
elseif isfield(scenarioParam, 'sysNoise') % If sysnoise given, shift by prediction and then sample from sysnoise
    for t = 2:scenarioParam.timesteps
        if isa(scenarioParam.sysNoise, 'AbstractHypertoroidalDistribution')
            groundtruth(:, t) = groundtruth(:, t-1) + scenarioParam.sysNoise.sample(1);
        elseif isa(scenarioParam.sysNoise, 'VMFDistribution')
            assert(isequal(scenarioParam.sysNoise.mu, [0; 0; 1]));
            sysNoise = scenarioParam.sysNoise;
            sysNoise.mu = groundtruth(:, t-1);
            groundtruth(:, t) = sysNoise.sample(1);
        elseif ismethod(scenarioParam.sysNoise, 'shift')
            sysNoise = scenarioParam.sysNoise;
            sysNoise = sysNoise.shift(groundtruth(:, t - 1));
            groundtruth(:, t) = sysNoise.sample(1);
        else
            error('SysNoise not supported')
        end
    end
else
    error('Cannot generate groundtruth');
end

end
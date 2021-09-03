function scenarioParam = checkAndFixParams(scenarioParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.2
if ~isfield(scenarioParam, 'useTransition')
    scenarioParam.useTransition = false;
end
if ~isfield(scenarioParam, 'useLikelihood')
    scenarioParam.useLikelihood = false;
end
assert(scenarioParam.useLikelihood == (isfield(scenarioParam, 'likelihood') || isfield(scenarioParam, 'likelihoodGenerator')), 'Likelihood or likelihoodGenerator is given but useLikelihood is not set (or the other way around). This is unexpected.');
assert(~isfield(scenarioParam, 'likelihood') || ~iscell(scenarioParam.likelihood) || numel(scenarioParam.likelihood) == scenarioParam.timesteps,'Must either provide single likelihood or cell array comprising as many elements as there are time steps.');
assert(isfield(scenarioParam, 'manifoldType')); % See manifoldType in plotResults, e.g., hypertorus
assert(~scenarioParam.useTransition || isfield(scenarioParam, 'genNextStateWithoutNoise') || isfield(scenarioParam, 'genNextStateWithNoise'), 'Must have function genNextStateWithoutNoise for nonlinear prediction.');
% Cannot have both measNoise and measGenerator
assert(nargout == 1); % Check that params are fixed!
assert(isfield(scenarioParam, 'useLikelihood') && isfield(scenarioParam, 'useTransition'));
assert(xor(isfield(scenarioParam, 'measGenerator'), isfield(scenarioParam, 'measNoise')));
assert(~isnan(scenarioParam.timesteps) && ~isnan(scenarioParam.measPerStep));
assert(xor(isfield(scenarioParam, 'genNextStateWithNoise'), isfield(scenarioParam, 'sysNoise')));
assert(isa(scenarioParam.initialPrior, 'AbstractDistribution'));

if isfield(scenarioParam, 'sysNoise') && ischar(scenarioParam.sysNoise) && strcmp(scenarioParam.sysNoise, 'none')
    scenarioParam.applySysNoiseTimes = false(1, scenarioParam.timesteps);
elseif ~isfield(scenarioParam, 'applySysNoiseTimes')
    scenarioParam.applySysNoiseTimes = [true(1, scenarioParam.timesteps - 1), false];
end
if isfield(scenarioParam,'genNextStateWithNoise')&&~isfield(scenarioParam,'genNextStateWithNoiseIsVectorized')
    % Fail if does not work at all
    scenarioParam.genNextStateWithNoise(scenarioParam.initialPrior.sample(1));
    try % See if vectorized works
        scenarioParam.genNextStateWithNoise(scenarioParam.initialPrior.sample(11));
        scenarioParam.genNextStateWithNoiseIsVectorized = true;
    catch
        warning('Apparently genNextStateWithNoise is not vectorized. This may negatively impact the performance of the particle filter.')
        scenarioParam.genNextStateWithNoiseIsVectorized = false;
    end
end
if isfield(scenarioParam,'genNextStateWithoutNoise')&&~isfield(scenarioParam,'genNextStateWithoutNoiseIsVectorized')
    scenarioParam.genNextStateWithoutNoise(scenarioParam.initialPrior.sample(1));
    try % See if vectorized works
        scenarioParam.genNextStateWithoutNoise(scenarioParam.initialPrior.sample(11));
        scenarioParam.genNextStateWithoutNoiseIsVectorized = true;
    catch
        warning('Apparently genNextStateWithoutNoise is not vectorized. This may negatively impact the performance of the particle filter.')
        scenarioParam.genNextStateWithoutNoiseIsVectorized = false;
    end
end
end
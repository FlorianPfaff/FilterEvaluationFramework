function scenarioParam = checkAndFixParams(scenarioParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
if ~isfield(scenarioParam, 'useTransition')
    scenarioParam.useTransition = false;
end
if ~isfield(scenarioParam, 'useLikelihood')
    scenarioParam.useLikelihood = false;
end
assert(isfield(scenarioParam, 'manifoldType')); % See manifoldType in plotResults, e.g., hypertorus
assert(~scenarioParam.useTransition || isfield(scenarioParam, 'genNextStateWithoutNoise') || isfield(scenarioParam, 'genNextStateWithNoise'), 'Must have function genNextStateWithoutNoise for nonlinear prediction.');
assert(~scenarioParam.useLikelihood || ~isfield(scenarioParam, 'measNoise'), 'No measNoise should be given if using likelihood')
% Cannot have both measNoise and measGenerator
assert(nargout == 1); % Check that params are fixed!
assert(isfield(scenarioParam, 'useLikelihood') && isfield(scenarioParam, 'useTransition'));
assert(xor(isfield(scenarioParam, 'measGenerator'), isfield(scenarioParam, 'measNoise')));
assert(~isnan(scenarioParam.timesteps) && ~isnan(scenarioParam.measPerStep));
assert(~scenarioParam.useLikelihood || isfield(scenarioParam, 'likelihoodCoeffsGenerator') || numel(scenarioParam.likelihood) == scenarioParam.timesteps || ~iscell(scenarioParam.likelihood));
assert(xor(isfield(scenarioParam, 'genNextStateWithNoise'), isfield(scenarioParam, 'sysNoise')));
assert(isa(scenarioParam.initialPrior, 'AbstractDistribution'));

if isfield(scenarioParam, 'sysNoise') && ischar(scenarioParam.sysNoise) && strcmp(scenarioParam.sysNoise, 'none')
    scenarioParam.applySysNoiseTimes = false(1, scenarioParam.timesteps);
elseif ~isfield(scenarioParam, 'applySysNoiseTimes')
    scenarioParam.applySysNoiseTimes = [true(1, scenarioParam.timesteps - 1), false];
end
end
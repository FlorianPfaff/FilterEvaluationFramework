function scenarioParam = checkAndFixParams(scenarioParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2022
% V2.20
arguments (Input)
    scenarioParam (1,1) struct
end
arguments (Output)
    scenarioParam (1,1) struct
end
if ~isfield(scenarioParam, 'useTransition')
    scenarioParam.useTransition = false;
end
if ~isfield(scenarioParam, 'useLikelihood')
    scenarioParam.useLikelihood = false;
end

switch scenarioParam.manifoldType
    case 'circle'
        mustBeA(scenarioParam.initialPrior, 'AbstractCircularDistribution')
    case 'hypertorus'
        mustBeA(scenarioParam.initialPrior, 'AbstractHypertoroidalDistribution')
    case {'hypersphere', 'hypersphereGeneral', 'hypersphereSymmetric'}
        mustBeA(scenarioParam.initialPrior, 'AbstractHypersphericalDistribution')
    case 'hyperhemisphere'
        mustBeA(scenarioParam.initialPrior, 'AbstractHemisphericalDistribution')
    case {'euclidean', 'Euclidean'}
        mustBeA(scenarioParam.initialPrior, 'AbstractLinearDistribution')
    case 'se2'
        mustBeA(scenarioParam.initialPrior, 'AbstractSE2Distribution')
    case 'se3'
        mustBeA(scenarioParam.initialPrior, 'AbstractSE3Distribution')
    otherwise
        error('Manifold not supported.')
end
mustBeNonempty(scenarioParam.timesteps);
mustBeInteger(scenarioParam.timesteps);
mustBeNonnegative(scenarioParam.timesteps); % 0 could be used to only consider the prior
if isfield(scenarioParam, 'nMeasAtIndividualTimeStep') && isfield(scenarioParam, 'measPerStep')
    error('Do not provide nMeasAtIndividualTimeStep and measPerStep at the same time.')
elseif ~isfield(scenarioParam, 'nMeasAtIndividualTimeStep') && isfield(scenarioParam, 'measPerStep')
    mustBeInteger(scenarioParam.measPerStep);
    mustBePositive(scenarioParam.measPerStep);
    scenarioParam.nMeasAtIndividualTimeStep = scenarioParam.measPerStep * ones(1,scenarioParam.timesteps);
    scenarioParam = rmfield(scenarioParam, 'measPerStep');
elseif ~isfield(scenarioParam, 'nMeasAtIndividualTimeStep')
    scenarioParam.nMeasAtIndividualTimeStep = ones(1,scenarioParam.timesteps);
end
mustBeNonempty(scenarioParam.nMeasAtIndividualTimeStep);
assert(scenarioParam.useLikelihood == (isfield(scenarioParam, 'likelihood') || isfield(scenarioParam, 'likelihoodGenerator')), 'Likelihood or likelihoodGenerator is given but useLikelihood is not set (or the other way around). This is unexpected.');
if isfield(scenarioParam, 'measGenerator')
    nTotalMeas = sum(scenarioParam.nMeasAtIndividualTimeStep);
    switch numel(scenarioParam.measGenerator)
        case 1
            % If only one given, repeat in cell array (if only one, it is
            % kept as it is).
            if ~iscell(scenarioParam.measGenerator)
                measGenCell = repmat({scenarioParam.measGenerator}, 1, nTotalMeas);
            else
                measGenCell = repmat(scenarioParam.measGenerator, 1, nTotalMeas);
            end
        case scenarioParam.timesteps
            % If equal to the number of time steps, repeat accoring to the
            % number of measurements in each time step. First case is executed if
            % scenarioParam.timesteps=1, which is also fine.
            measGenDoubleCell = arrayfun(@(i){repmat(scenarioParam.measGenerator(i),[1,scenarioParam.nMeasAtIndividualTimeStep(i)])}, 1:scenarioParam.timesteps);
            measGenCell = [measGenDoubleCell{:}];
        case scenarioParam.timesteps
            % Already of correct size
            measGenCell = scenarioParam.measGenerator;
        otherwise
            error('scenarioParam.measGenerator is of unexpected size.');
    end
    scenarioParam.measGenerator = measGenCell;
end
if isfield(scenarioParam, 'likelihood')
    nTotalMeas = sum(scenarioParam.nMeasAtIndividualTimeStep);
    switch numel(scenarioParam.likelihood)
        case 1
            % If only one given, repeat in cell array (if only one, it is
            % kept as it is).
            if ~iscell(scenarioParam.likelihood)
                likelihoodCell = repmat({scenarioParam.likelihood}, 1, nTotalMeas);
            else
                likelihoodCell = repmat(scenarioParam.likelihood, 1, nTotalMeas);
            end
        case scenarioParam.timesteps
            % If equal to the number of time steps, repeat accoring to the
            % number of measurements in each time step. First case is executed if
            % scenarioParam.timesteps=1, which is also fine.
            likelihoodDoubleCell = arrayfun(@(i){repmat(scenarioParam.likelihood(i),[1,scenarioParam.nMeasAtIndividualTimeStep(i)])}, 1:scenarioParam.timesteps);
            likelihoodCell = [likelihoodDoubleCell{:}];
        case scenarioParam.timesteps
            % Already of correct size
            likelihoodCell = scenarioParam.likelihood;
        otherwise
            error('scenarioParam.likelihood is of unexpected size.');
    end
    scenarioParam.likelihood = likelihoodCell;
end
assert(isfield(scenarioParam, 'manifoldType')); % See manifoldType in plotResults, e.g., hypertorus
assert(~scenarioParam.useTransition || isfield(scenarioParam, 'genNextStateWithoutNoise') || isfield(scenarioParam, 'genNextStateWithNoise'), 'Must have function genNextStateWithoutNoise for nonlinear prediction.');
% Cannot have both measNoise and measGenerator
assert(nargout == 1); % Check that params are fixed!
assert(isfield(scenarioParam, 'useLikelihood') && isfield(scenarioParam, 'useTransition'));
assert(xor(isfield(scenarioParam, 'measGenerator'), isfield(scenarioParam, 'measNoise')));
mustBePositive(scenarioParam.timesteps);
mustBeInteger(scenarioParam.timesteps);
mustBePositive(scenarioParam.nMeasAtIndividualTimeStep);
mustBeInteger(scenarioParam.nMeasAtIndividualTimeStep);
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
        warning('FilterEvaluationFramework:genNextStateWithNoiseNotVectorizedForPF',...
            'Apparently, genNextStateWithNoise is not vectorized. This may negatively impact the performance of the particle filter.')
        scenarioParam.genNextStateWithNoiseIsVectorized = false;
    end
end
if isfield(scenarioParam,'genNextStateWithoutNoise')&&~isfield(scenarioParam,'genNextStateWithoutNoiseIsVectorized')
    scenarioParam.genNextStateWithoutNoise(scenarioParam.initialPrior.sample(1));
    try % See if vectorized works
        scenarioParam.genNextStateWithoutNoise(scenarioParam.initialPrior.sample(11));
        scenarioParam.genNextStateWithoutNoiseIsVectorized = true;
    catch
        warning('FilterEvaluationFramework:genNextStateWithoutNoiseNotVectorizedForPF',...
            'Apparently, genNextStateWithoutNoise is not vectorized. This may negatively impact the performance of the particle filter.')
        scenarioParam.genNextStateWithoutNoiseIsVectorized = false;
    end
end
if ~isfield(scenarioParam, 'inputs')
    scenarioParam.inputs = [];
end
function scenarioParam = checkAndFixParams(scenarioParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
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
    case 'MTTEuclidean'
        mustBeA(scenarioParam.initialPrior, 'AbstractLinearDistribution')
    otherwise
        error('Manifold not supported.')
end
mustBeNonempty(scenarioParam.timesteps);
mustBeInteger(scenarioParam.timesteps);
mustBeNonnegative(scenarioParam.timesteps); % 0 could be used to only consider the prior
if contains(scenarioParam.manifoldType, 'MTT')
    assert(~isfield(scenarioParam, 'nMeasAtIndividualTimeStep') && ~isfield(scenarioParam, 'measPerStep'))
    if ~isfield(scenarioParam, 'detectionProbability')
        scenarioParam.detectionProbability = 1;
    end
    if ~isfield(scenarioParam, 'clutterRate')
        scenarioParam.clutterRate = 0;
    end
elseif isfield(scenarioParam, 'nMeasAtIndividualTimeStep') && isfield(scenarioParam, 'measPerStep')
    error('Do not provide nMeasAtIndividualTimeStep and measPerStep at the same time.')
elseif ~isfield(scenarioParam, 'nMeasAtIndividualTimeStep') && isfield(scenarioParam, 'measPerStep')
    mustBeInteger(scenarioParam.measPerStep);
    mustBePositive(scenarioParam.measPerStep);
    scenarioParam.nMeasAtIndividualTimeStep = scenarioParam.measPerStep * ones(1,scenarioParam.timesteps);
    scenarioParam = rmfield(scenarioParam, 'measPerStep');
    mustBePositive(scenarioParam.nMeasAtIndividualTimeStep);
    mustBeInteger(scenarioParam.nMeasAtIndividualTimeStep);
elseif ~isfield(scenarioParam, 'nMeasAtIndividualTimeStep')
    scenarioParam.nMeasAtIndividualTimeStep = ones(1,scenarioParam.timesteps);
end
assert(scenarioParam.useLikelihood == (isfield(scenarioParam, 'likelihood') || isfield(scenarioParam, 'likelihoodGenerator')), 'Likelihood or likelihoodGenerator is given but useLikelihood is not set (or the other way around). This is unexpected.');
if isfield(scenarioParam, 'measGenerator')
    if numel(scenarioParam.measGenerator)==1
        % If only one given, repeat in cell array.
        if ~iscell(scenarioParam.measGenerator)
            scenarioParam.measGenerator = repmat({scenarioParam.measGenerator}, 1, scenarioParam.timesteps);
        else
            scenarioParam.measGenerator = repmat(scenarioParam.measGenerator, 1, scenarioParam.timesteps);
        end
    end
    % Either one is a cell array or none is
    assert(all(iscell(scenarioParam.measGenerator{1})==cellfun(@(measGenForOneTimeStep)iscell(measGenForOneTimeStep), scenarioParam.measGenerator)));
    % If not a cell itself (or single element), pack into cell and repeat
    % according to number of measurements in the respective time step
    if all(cellfun(@(measGenForOneTimeStep)iscell(measGenForOneTimeStep), scenarioParam.measGenerator))||...
       all(cellfun(@(measGenForOneTimeStep)numel(measGenForOneTimeStep)==1, scenarioParam.measGenerator))
       scenarioParam.measGenerator = arrayfun(@(i){repmat(scenarioParam.measGenerator(i),[1,scenarioParam.nMeasAtIndividualTimeStep(i)])}, 1:scenarioParam.timesteps);
    else
        assert(isequal(scenarioParam.nMeasAtIndividualTimeStep,...
            cellfun(@(measGenForOneTimeStep)numel(measGenForOneTimeStep), scenarioParam.measGenerator)),...
            'Size of likelihood cell array is not compatible. It is has to be a cell array of t elements comprising cell arrays with a number of elements equal to nMeasAtIndividualTimeStep.');
    end
end
if isfield(scenarioParam, 'likelihood')
    if numel(scenarioParam.likelihood)==1
        % If only one given, repeat in cell array.
        if ~iscell(scenarioParam.likelihood)
            scenarioParam.likelihood = repmat({scenarioParam.likelihood}, 1, scenarioParam.timesteps);
        else
            scenarioParam.likelihood = repmat(scenarioParam.likelihood, 1, scenarioParam.timesteps);
        end
    end
    % Either one is a cell array or none is
    assert(all(iscell(scenarioParam.likelihood{1})==cellfun(@(likelihoodForOneTimeStep)iscell(likelihoodForOneTimeStep), scenarioParam.likelihood)));
    % If not a cell itself (or single element), pack into cell and repeat
    % according to number of measurements in the respective time step
    if all(cellfun(@(likelihoodForOneTimeStep)iscell(likelihoodForOneTimeStep), scenarioParam.likelihood))||...
       all(cellfun(@(likelihoodForOneTimeStep)numel(likelihoodForOneTimeStep)==1, scenarioParam.likelihood))
       scenarioParam.likelihood = arrayfun(@(i){repmat(scenarioParam.likelihood(i),[1,scenarioParam.nMeasAtIndividualTimeStep(i)])}, 1:scenarioParam.timesteps);
    else
        assert(isequal(scenarioParam.nMeasAtIndividualTimeStep,...
            cellfun(@(likelihoodForOneTimeStep)numel(likelihoodForOneTimeStep), scenarioParam.likelihood)),...
            'Size of likelihood cell array is not compatible. It is has to be a cell array of t elements comprising cell arrays with a number of elements equal to nMeasAtIndividualTimeStep.');
    end
end
assert(isfield(scenarioParam, 'manifoldType')); % See manifoldType in plotResults, e.g., hypertorus
assert(~scenarioParam.useTransition || isfield(scenarioParam, 'genNextStateWithoutNoise') || isfield(scenarioParam, 'genNextStateWithNoise'), 'Must have function genNextStateWithoutNoise for nonlinear prediction.');
% Cannot have both measNoise and measGenerator
assert(nargout == 1); % Check that params are fixed!
assert(isfield(scenarioParam, 'useLikelihood') && isfield(scenarioParam, 'useTransition'));
assert(xor(isfield(scenarioParam, 'measGenerator'), isfield(scenarioParam, 'measNoise')));
mustBePositive(scenarioParam.timesteps);
mustBeInteger(scenarioParam.timesteps);
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

if ~isfield(scenarioParam, 'nTargets')
    scenarioParam.nTargets = 1;
end
assert(numel(scenarioParam.initialPrior) == scenarioParam.nTargets);
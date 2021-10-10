function [filter, predictionRoutine, likelihoodForFilter, measNoiseForFilter] = configureForFilter(filterParam, scenarioParam, precalculatedParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.2
if isfield(scenarioParam, 'likelihood')
    likelihoodForFilter = scenarioParam.likelihood; % Is overwritten below if necessary
else
    likelihoodForFilter = [];
end
if isfield(scenarioParam, 'measNoise')
    measNoiseForFilter = scenarioParam.measNoise; % Is overwritten below if necessary
else
    measNoiseForFilter = [];
end
switch filterParam.name
    case 'twn'
        filter = ToroidalWNFilter();
        if isa(scenarioParam.initialPrior, 'HypertoroidalUniformDistribution')
            warning('Trying to initialize TWN filter with uniform prior. Setting to TWN with random mu very high uncertainty')
            mu = scenarioParam.initialPrior.sample(1);
            initialPrior = ToroidalWNDistribution(mu, 100*eye(filter.dim));
        else
            initialPrior = scenarioParam.initialPrior;
        end
        filter.setState(initialPrior);
        if ~scenarioParam.useLikelihood && ~isa(scenarioParam.measNoise, 'ToroidalWNDistribution')
            measNoiseForFilter = precalculatedParams.measNoiseForFilter;
        end

        assert(isa(scenarioParam.sysNoise, 'AbstractToroidalDistribution'))
        if ~isa(scenarioParam.sysNoise, 'ToroidalWNDistribution')
            tfdSys = ToroidalFourierDistribution.fromDistribution(scenarioParam.sysNoise, 9, 'identity');
            sysNoiseForFilter = tfdSys.toTWN;
        else
            sysNoiseForFilter = scenarioParam.sysNoise;
        end
        predictionRoutine = @()filter.predictNonlinear( ...
            @(x)scenarioParam.genNextStateWithoutNoise(x), sysNoiseForFilter);
    case {'iff', 'sqff', 'ffidResetOnPred', 'ffsqrtResetOnPred'}
        if strfind(filterParam.name, 'iff')
            trans = 'identity';
        elseif strfind(filterParam.name, 'sqff')
            trans = 'sqrt';
        end
        coeffs = repmat(filterParam.parameter, 1, scenarioParam.initialPrior.dim);
        if isa(scenarioParam.initialPrior, 'AbstractCircularDistribution')
            filter = FourierFilter(coeffs, trans);
            filter.setState(FourierDistribution.fromDistribution(scenarioParam.initialPrior, coeffs, trans));
        elseif isa(scenarioParam.initialPrior, 'AbstractHypertoroidalDistribution')
            filter = HypertoroidalFourierFilter(coeffs, trans);
            filter.setState(HypertoroidalFourierDistribution.fromDistribution(scenarioParam.initialPrior, coeffs, trans));
        else
            error('Prior not supported');
        end
        if ~scenarioParam.useLikelihood
            if isa(filter, 'FourierFilter')
                measNoiseForFilter = FourierDistribution.fromDistribution(scenarioParam.measNoise, coeffs, trans);
            elseif isa(filter, 'HypertoroidalFourierFilter')
                measNoiseForFilter = HypertoroidalFourierDistribution.fromDistribution(scenarioParam.measNoise, coeffs, trans);
            else
                error('Configuration not supported');
            end
        end
        if contains(filterParam.name, 'ResetOnPred')
            fdUniform = FourierDistribution.fromDistribution(CircularUniformDistribution, filterParam.parameter);
            predictionRoutine = @()filter.predictIdentity(fdUniform);
        elseif scenarioParam.useTransition % No parameters are chosen accoring to the ones in filter
            hfdTrans = precalculatedParams.hfdTrans;
            predictionRoutine = @()filter.predictNonlinearViaTransitionDensity(hfdTrans);
        else
            if isa(scenarioParam.initialPrior, 'AbstractCircularDistribution')
                sysNoiseFourier = FourierDistribution.fromDistribution(scenarioParam.sysNoise, filterParam.parameter, trans);
            else
                sysNoiseFourier = HypertoroidalFourierDistribution.fromDistribution(scenarioParam.sysNoise, filterParam.parameter, trans);
            end
            predictionRoutine = @()filter.predictIdentity(sysNoiseFourier);
        end
    case 'htgf'
        filter = HypertoroidalGridFilter(filterParam.parameter, scenarioParam.initialPrior.dim);
        filter.setState(HypertoroidalGridDistribution.fromDistribution( ...
            scenarioParam.initialPrior, filterParam.parameter * ones(1, scenarioParam.initialPrior.dim)));
        if scenarioParam.useTransition
            predictionRoutine = @()filter.predictNonlinearViaTransitionDensity(precalculatedParams.fTrans_tdxtd);
        else
            error('Currently not supported');
        end
    case 'fig'
        assert(scenarioParam.initialPrior.dim == 1);
        filter = FIGFilter(filterParam.parameter);
        filter.setState(FIGDistribution.fromDistribution(scenarioParam.initialPrior, filterParam.parameter));
        sysNoiseGrid = FIGDistribution.fromDistribution(scenarioParam.sysNoise, filterParam.parameter);
        predictionRoutine = @()filter.predictIdentity(sysNoiseGrid);
    case 'figResetOnPred'
        filter = FIGFilter(filterParam.parameter);
        predictionRoutine = @()filter.setState(FIGDistribution.fromDistribution( ...
            CircularUniformDistribution(), filterParam.parameter));
    case {'ishf','sqshf'}
        if strfind(filterParam.name, 'ishf')
            trans = 'identity';
        elseif strfind(filterParam.name, 'sqshf')
            trans = 'sqrt';
        end
        filter = SphericalHarmonicsFilter(filterParam.parameter, trans);
        shdInit = SphericalHarmonicsDistributionComplex.fromDistributionNumericalFast( ...
            scenarioParam.initialPrior, filterParam.parameter, trans);
        filter.setState(shdInit);
        if strcmp(scenarioParam.sysNoise, 'none')
            predictionRoutine = @()[];
        else
            sysNoiseForFilter = SphericalHarmonicsDistributionComplex.fromDistributionNumericalFast( ...
                scenarioParam.sysNoise, filterParam.parameter, trans);
            if strcmp(trans,'sqrt')
                sysNoiseForFilter = sysNoiseForFilter.transformViaCoefficients('square', 2*filterParam.parameter);
            end
            predictionRoutine = @()filter.predictIdentity(sysNoiseForFilter);
        end
        if isfield(scenarioParam, 'measNoise')
            measNoiseForFilter = SphericalHarmonicsDistributionComplex.fromDistributionNumericalFast( ...
                scenarioParam.measNoise, filterParam.parameter, trans);
        end
    case 'pf'
        noParticles = filterParam.parameter;
        if isempty(noParticles) || (noParticles == 0)
            error('Using zero particles does not make sense');
        end
        switch scenarioParam.manifoldType
            case {'circle', 'hypertorus'}
                filter = HypertoroidalParticleFilter(noParticles, scenarioParam.initialPrior.dim);
                filter.setState(scenarioParam.initialPrior);

                if isfield(scenarioParam, 'genNextStateWithNoise')
                    predictionRoutine = @()filter.predictNonlinear(scenarioParam.genNextStateWithNoise, [], scenarioParam.genNextStateWithNoiseIsVectorized);
                elseif isfield(scenarioParam, 'sysNoise')
                    predictionRoutine = @()filter.predictNonlinear(@(x)x, scenarioParam.sysNoise, true);
                end
            case {'hypersphere', 'hypersphereGeneral', 'hypersphereSymm'}
                filter = HypersphericalParticleFilter(noParticles, scenarioParam.initialPrior.dim);
                filter.setState(scenarioParam.initialPrior);

                if isfield(scenarioParam, 'genNextStateWithNoise')
                    predictionRoutine = @()filter.predictNonlinear(scenarioParam.genNextStateWithNoise, [], scenarioParam.genNextStateWithNoiseIsVectorized);
                elseif isfield(scenarioParam, 'sysNoise')
                    predictionRoutine = @()filter.predictNonlinear(@(x)x, scenarioParam.sysNoise, true);
                end
            case 'hypercylinder'
                filter = HypercylindricalParticleFilter(noParticles, ...
                    scenarioParam.initialPrior.boundD, scenarioParam.initialPrior.linD);
                filter.setState(SE2DiracDistribution(scenarioParam.initialPrior.sample(noParticles)));
                predictionRoutine = @()filter.predictNonlinear( ...
                    scenarioParam.genNextStateWithoutNoise, scenarioParam.sysNoise, scenarioParam.genNextStateWithoutNoiseIsVectorized);
            case 'se2'
                filter = SE2ParticleFilter(noParticles);
                filter.setState(SE2DiracDistribution(scenarioParam.initialPrior.sample(noParticles)));
                predictionRoutine = @()filter.predictNonlinear( ...
                    scenarioParam.genNextStateWithoutNoise, scenarioParam.sysNoise, scenarioParam.genNextStateWithoutNoiseIsVectorized);
            otherwise
                error('Manifold unsupported.');
        end
    case {'sgf', 'hgf'}
        if strcmp(filterParam.name, 'sgf')
            filter = SphericalGridFilter(filterParam.parameter);
        else
            filter = HypersphericalGridFilter(filterParam.parameter, scenarioParam.initialPrior.dim);
        end
        filter.setState(scenarioParam.initialPrior);
        if scenarioParam.useTransition
            fTrans_s2xs2 = S2CondS2GridDistribution.fromFunction(scenarioParam.fTrans, filterParam.parameter, true, 'eq_point_set');
            predictionRoutine = @()filter.predictNonlinearViaTransitionDensity(fTrans_s2xs2);
        end
    case 'hgfSymm'
        filter = HypersphericalGridFilter(filterParam.parameter, scenarioParam.initialPrior.dim, 'eq_point_set_symm');
        filter.setState(HypersphericalGridDistribution.fromDistribution(scenarioParam.initialPrior, filterParam.parameter, 'eq_point_set_symm'));
        if scenarioParam.useTransition
            predictionRoutine = @()filter.predictNonlinearViaTransitionDensity(precalculatedParams.fTrans_sdxsd);
        end
    case 'hhgf'
        filter = HyperhemisphericalGridFilter(filterParam.parameter, scenarioParam.initialPrior.dim, 'eq_point_set_symm');
        filter.setState(precalculatedParams.priorForFilter);
        if scenarioParam.useTransition
            predictionRoutine = @()filter.predictNonlinearViaTransitionDensity(precalculatedParams.fTrans_sdhalfxsdhalf);
        end
    case 'vmf'
        filter = VMFFilter;
        filter.setState(scenarioParam.initialPrior);
        predictionRoutine = @()filter.predictNonlinear(scenarioParam.genNextStateWithoutNoise, VMFDistribution([0; 0; 1], scenarioParam.kappaSysNoise));
    case 's3f'
        filter = StateSpaceSubdivisionFilter();
        filter.setState(precalculatedParams.priorForFilter);
        %             predictionRoutine=@()filter.predictNonlinear(...
        %                     @(x)scenarioParam.genNextStateWithoutNoise(x),scenarioParam.sysNoise);
        inputs = reshape(scenarioParam.stepSize*[cos(precalculatedParams.condPeriodic.getGrid()); sin(precalculatedParams.condPeriodic.getGrid())], 2, 1, 1, size(filter.apd.gd.gridValues, 1));
        predictionRoutine = @()filter.predictLinear( ...
            precalculatedParams.condPeriodic, scenarioParam.gaussianSysNoise.C, [], inputs);
    case 'se2bf'
        filter = SE2BinghamFilter();
        filter.setState(precalculatedParams.priorForFilter);
        likelihoodForFilter = @(z, x)scenarioParam.likelihood(z, ...
            AbstractSE2Distribution.dualQuaternionToAnglePos(x));
        predictionRoutine = @()filter.predictNonlinear(scenarioParam.genNextStateWithoutNoise, precalculatedParams.sysNoiseForFilter);
    case 'se2ukfm'
        filter = SE2UKFM(3, filterParam.parameter*ones(3, 1));
        filter.setState([scenarioParam.initialPriorPeriodic.mu; scenarioParam.initialPriorLinear.mean()], ...
            blkdiag(scenarioParam.initialPriorLinear.C, scenarioParam.initialPriorPeriodic.toWN.sigma^2));

        % The sys noise should actually given in longitudinal and
        % transveral coordinates, but since our system noise is
        % direction invariant, it works without changing anything
        sysCov = blkdiag(scenarioParam.vmSysNoise.toWN().sigma^2, scenarioParam.gaussianSysNoise.C);
        % This is scenario-dependant, but for now it's okay to hardcode
        % it.
        predictionRoutine = @()filter.predictNonlinear(@localization_f, sysCov, struct('gyro', 0, 'v', [1; 0]));

    case {'dummy', 'random'}
        if isa(scenarioParam.initialPrior, 'AbstractHypertoroidalDistribution')
            filter = HypertoroidalDummyFilter(scenarioParam.initialPrior.dim);
        elseif isa(scenarioParam.initialPrior, 'AbstractHypersphericalDistribution')
            filter = HypersphericalDummyFilter(scenarioParam.initialPrior.dim);
        end
        predictionRoutine = @()NaN; % Do nothing
    otherwise
        error('Filter currently unsupported');
end
if scenarioParam.useLikelihood && isfield(scenarioParam, 'likelihood') && ~iscell(likelihoodForFilter)
    likelihoodForFilter = repmat({likelihoodForFilter}, 1, scenarioParam.timesteps);
elseif numel(likelihoodForFilter)  == scenarioParam.timesteps
    likelihoodForFilter = reshape(repmat(likelihoodForFilter(:)',[scenarioParam.measPerStep,1]),1,[]);
elseif numel(likelihoodForFilter)  == scenarioParam.measPerStep
    likelihoodForFilter = repmat(likelihoodForFilter(:)',[1,scenarioParam.timesteps]);
elseif isempty(likelihoodForFilter) % Do nothing
else
    error('Likelihood is in unknown format');
end
end
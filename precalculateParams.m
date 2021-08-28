function precalculatedParams = precalculateParams(scenarioParam, filterParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.1
switch filterParam.name
    case 'twn'
        if ~scenarioParam.useLikelihood && ~isa(scenarioParam.measNoise, 'ToroidalWNDistribution')
            s = scenarioParam.measNoise.sample(100000);
            precalculatedParams.measNoiseForFilter = ToroidalWNDistribution.mleNumerical(s);
        else
            precalculatedParams = [];
        end
    case 'htgf'
        if scenarioParam.useTransition
            precalculatedParams.fTrans_tdxtd = ...
                TdCondTdGridDistribution.fromFunction(scenarioParam.fTrans, filterParam.parameter, true, 'CartesianProduct', 2*scenarioParam.initialPrior.dim);
        else
            precalculatedParams = [];
        end
    case 'iff'
        filtertmp = HypertoroidalFourierFilter(repmat(filterParam.parameter, [1, scenarioParam.initialPrior.dim]), 'identity');
        if scenarioParam.useTransition
            precalculatedParams.hfdTrans = ...
                filtertmp.getfTransAsHfd(scenarioParam.genNextStateWithoutNoiseFourier, scenarioParam.sysNoise);
        else
            precalculatedParams = [];
        end
    case 'sqff'
        filtertmp = HypertoroidalFourierFilter(repmat(filterParam.parameter, [1, scenarioParam.initialPrior.dim]), 'sqrt');
        if scenarioParam.useTransition
            precalculatedParams.hfdTrans = ...
                filtertmp.getfTransAsHfd(scenarioParam.genNextStateWithoutNoiseFourier, scenarioParam.sysNoise);
        else
            precalculatedParams = [];
        end
    case 'sgf'
        if scenarioParam.useTransition
            precalculatedParams.fTrans_sdxsd = ...
                S2CondS2GridDistribution.fromFunction(scenarioParam.fTrans, filterParam.parameter, true, 'eq_point_set');
        else
            precalculatedParams = [];
        end
    case 'hgf'
        if scenarioParam.useTransition
            precalculatedParams.fTrans_sdxsd = ...
                SdCondSdGridDistribution.fromFunction(scenarioParam.fTrans, filterParam.parameter, true, 'eq_point_set', 2*scenarioParam.initialPrior.dim);
        else
            precalculatedParams = [];
        end
    case 'hgfSymm'
        if scenarioParam.useTransition
            precalculatedParams.fTrans_sdxsd = ...
                SdCondSdGridDistribution.fromFunction(scenarioParam.fTrans, filterParam.parameter, true, 'eq_point_set_symm', 2*scenarioParam.initialPrior.dim);
        else
            precalculatedParams = [];
        end
    case 'hhgf'
        precalculatedParams.priorForFilter = HyperhemisphericalGridDistribution.fromDistribution(scenarioParam.initialPrior, filterParam.parameter, 'eq_point_set_symm');
        if scenarioParam.useTransition
            precalculatedParams.fTrans_sdhalfxsdhalf = ...
                SdHalfCondSdHalfGridDistribution.fromFunction( ...
                scenarioParam.fTrans, filterParam.parameter, true, 'eq_point_set_symm', 2*scenarioParam.initialPrior.dim);
        else
            precalculatedParams = [];
        end
    case 's3f'
        precalculatedParams.priorForFilter = SE2StateSpaceSubdivisionGaussianDistribution( ...
            FIGDistribution.fromDistribution(scenarioParam.initialPriorPeriodic, filterParam.parameter), ...
            repmat(scenarioParam.initialPriorLinear, [filterParam.parameter, 1]));
        precalculatedParams.condPeriodic = ...
            TdCondTdGridDistribution.fromFunction(@(xkk, xk)scenarioParam.vmSysNoise.pdf(xkk - xk), filterParam.parameter, false, 'CartesianProd', 2);
    case 'se2bf'
        noSamplesForFitting = 100000;
        precalculatedParams.priorForFilter = SE2BinghamDistribution.fit(scenarioParam.initialPrior.sample(noSamplesForFitting));
        precalculatedParams.sysNoiseForFilter = SE2BinghamDistribution.fit(scenarioParam.sysNoise.sample(noSamplesForFitting));
    otherwise
        precalculatedParams = [];
end
end
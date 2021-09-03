function scenarioParam = scenarioDatabase(scenario, scenarioCustomizationParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.1
scenarioParam = struct('initialPrior', @()error('Scenario param not initialized'), ...
    'timesteps', NaN, 'measPerStep', 1, 'allSeeds', NaN);
switch scenario
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% Circular scenarios %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'S1IgorsFunction'
        scenarioParam.manifoldType = 'circle';
        scenarioParam.initialPrior = CircularUniformDistribution;
        scenarioParam.useLikelihood = false;
        scenarioParam.measNoise = VMDistribution(0, 1);
        scenarioParam.useTransition = true;
        scenarioParam.genNextStateWithoutNoise = @(x)igor1D(x, 2);
        scenarioParam.genNextStateWithoutNoiseFourier = @(x)igor1D(x, 2);
        scenarioParam.sysNoise = VMDistribution(0, 1);
        scenarioParam.timesteps = 10;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%% Hypertoroidal scenarios %%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'T2unimodal'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        [scenarioParam.si1Sys, scenarioParam.si2Sys, scenarioParam.si1Meas, scenarioParam.si2Meas] = deal(1);
        scenarioParam.rhoMeas = 0.5;
        scenarioParam.rhoSys = 0.9;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.initialPrior = ToroidalWNDistribution([1; 1], eye(2));
        scenarioParam.useLikelihood = false;
        scenarioParam.sysNoise = ToroidalWNDistribution([0; 0], [scenarioParam.si1Sys^2, scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys; scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys, scenarioParam.si2Sys^2]);
        scenarioParam.measNoise = ToroidalWNDistribution([0; 0], [scenarioParam.si1Meas^2, scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas; scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas, scenarioParam.si2Meas^2]);
    case 'T2bimodal'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        [scenarioParam.si1Sys, scenarioParam.si2Sys, scenarioParam.si1Meas, scenarioParam.si2Meas] = deal(1/3);
        scenarioParam.rhoMeas = 0.5;
        scenarioParam.rhoSys = 0.9;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.initialPrior = ToroidalWNDistribution([1; 1], eye(2));
        scenarioParam.useTransition = false;
        scenarioParam.sysNoise = ToroidalWNDistribution([0; 0], [scenarioParam.si1Sys^2, scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys; scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys, scenarioParam.si2Sys^2]);
        scenarioParam.useLikelihood = false;
        scenarioParam.measNoise = ToroidalMixture({ToroidalWNDistribution([.5; .5], [scenarioParam.si1Meas^2, scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas; scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas, scenarioParam.si2Meas^2]), ...
            ToroidalWNDistribution([-.5; -.5], [scenarioParam.si1Meas^2, scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas; scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas, scenarioParam.si2Meas^2])}, ...
            [0.5, 0.5]);
    case 'T2-4twnlooksunimodal'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 10;
        [scenarioParam.si1Sys, scenarioParam.si2Sys] = deal(2);
        [scenarioParam.si1Meas, scenarioParam.si2Meas] = deal(1);
        scenarioParam.rhoMeas = 0.5;
        scenarioParam.rhoSys = 0.9;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.initialPrior = ToroidalWNDistribution([1; 1], eye(2));
        scenarioParam.useTransition = false;
        scenarioParam.sysNoise = ToroidalWNDistribution([0; 0], [scenarioParam.si1Sys^2, scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys; scenarioParam.rhoSys * scenarioParam.si1Sys * scenarioParam.si2Sys, scenarioParam.si2Sys^2]);
        scenarioParam.useLikelihood = false;
        Cmeas = [scenarioParam.si1Meas^2, scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas; scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas, scenarioParam.si2Meas^2];
        scenarioParam.measNoise = ToroidalMixture({ToroidalWNDistribution([.5; .5] / 2, Cmeas), ...
            ToroidalWNDistribution([-.5; -.5] / 2, Cmeas), ToroidalWNDistribution([.5; -.5] / 2, Cmeas), ...
            ToroidalWNDistribution([-.5; .5] / 2, Cmeas)}, [.25, .25, .25, .25]);
    case 'T2IgorsFunctionCustom'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.igorsFunParams = scenarioCustomizationParams;

        [scenarioParam.si1Sys, scenarioParam.si2Sys, scenarioParam.si1Meas, scenarioParam.si2Meas] = deal(1);
        scenarioParam.rhoMeas = 0.5;
        scenarioParam.rhoSys = 0.9;
        scenarioParam.initialPrior = HypertoroidalUniformDistribution(2);
        scenarioParam.useLikelihood = false;
        scenarioParam.measNoise = ToroidalWNDistribution([0; 0], ...
            [scenarioParam.si1Meas^2, scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas; ...
            scenarioParam.rhoMeas * scenarioParam.si1Meas * scenarioParam.si2Meas, scenarioParam.si2Meas^2]);
        scenarioParam.useTransition = true;
        scenarioParam.genNextStateWithoutNoise = @(x)igorsFun2Dvec(x(1), x(2), scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2));
        scenarioParam.genNextStateWithoutNoiseFourier = @(x1, x2)igor2D(x1, x2, scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2));
        scenarioParam.sysNoise = ToroidalWNDistribution([0; 0], [1, -0.3; -0.3, 1.5]);

        scenarioParam.fTrans = @(xkk, xk)fTransIgorsFun2d(xkk, xk, scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2), scenarioParam.sysNoise);
        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;
    case 'T3IgorsFunctionCustom'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.igorsFunParams = scenarioCustomizationParams;
        scenarioParam.Cmeas = [1.9, 0.5, 1.4; 0.5, 0.9, 0.5; 1.4, 0.5, 1.2];
        scenarioParam.Csys = [0.8, 0.8, 0.5; 0.8, 1, 0.6; 0.5, 0.6, 0.5];
        scenarioParam.initialPrior = HypertoroidalUniformDistribution(3);
        scenarioParam.useLikelihood = false;
        scenarioParam.measNoise = HypertoroidalWNDistribution([0; 0; 0], scenarioParam.Cmeas);
        scenarioParam.useTransition = true;
        scenarioParam.genNextStateWithoutNoise = @(x)igorsFun3Dvec(x(1), x(2), x(3), scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2), scenarioParam.igorsFunParams(3));
        scenarioParam.genNextStateWithoutNoiseFourier = @(x1, x2, x3)igorsFun3D(x1, x2, x3, scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2), scenarioParam.igorsFunParams(3));
        scenarioParam.sysNoise = HypertoroidalWNDistribution([0; 0; 0], scenarioParam.Csys);

        scenarioParam.fTrans = @(xkk, xk)fTransIgorsFun3d(xkk, xk, scenarioParam.igorsFunParams(1), scenarioParam.igorsFunParams(2), scenarioParam.igorsFunParams(3), scenarioParam.sysNoise);

        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;
    case 'T3HighNoise'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        scenarioParam.initialPrior = HypertoroidalWNDistribution([1; 1; 1], eye(3));
        Csys = [0.7, 0.4, 0.2; 0.4, 0.6, 0.1; 0.2, 0.1, 1] * 2;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.useLikelihood = false;
        scenarioParam.sysNoise = HypertoroidalWNDistribution([0; 0; 0], Csys);
        Cmeas = Csys';
        scenarioParam.measNoise = HypertoroidalMixture({HypertoroidalWNDistribution([.5; .5; .5], Cmeas), ...
            HypertoroidalWNDistribution([-.5; -.5; -.5], Cmeas)}, [0.5, 0.5]);
    case 'T3LowNoise'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        scenarioParam.initialPrior = HypertoroidalWNDistribution([1; 1; 1], eye(3));
        Csys = [0.7, 0.4, 0.2; 0.4, 0.6, 0.1; 0.2, 0.1, 1] / 4;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.useLikelihood = false;
        scenarioParam.sysNoise = HypertoroidalWNDistribution([0; 0; 0], Csys);
        Cmeas = Csys';
        scenarioParam.measNoise = HypertoroidalMixture({HypertoroidalWNDistribution([.5; .5; .5], Cmeas), ...
            HypertoroidalWNDistribution([-.5; -.5; -.5], Cmeas)}, [0.5, 0.5]);
    case 'T3LowSysNoiseBimodal'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.initialPrior = HypertoroidalWNDistribution([1; 1; 1], eye(3));
        Csys = [0.7, 0.4, 0.2; 0.4, 0.6, 0.1; 0.2, 0.1, 1] / 4;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.useLikelihood = false;
        scenarioParam.useTransition = false;
        scenarioParam.timesteps = 10;
        scenarioParam.sysNoise = HypertoroidalMixture({HypertoroidalWNDistribution([.5; .5; .5], Csys), ...
            HypertoroidalWNDistribution([-.5; -.5; -.5], Csys)}, [0.5, 0.5]);
        Cmeas = Csys([3, 1, 2], [3, 1, 2]);
        scenarioParam.measNoise = HypertoroidalMixture({HypertoroidalWNDistribution([.5; .5; .5], Cmeas), ...
            HypertoroidalWNDistribution([-.5; -.5; -.5], Cmeas)}, [0.5, 0.5]);
    case 'T4'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        scenarioParam.initialPrior = HypertoroidalWNDistribution([1; 1; 1; 1], eye(4));
        Csys = [0.7, 0.4, 0.2, -0.5; 0.4, 0.6, 0.1, 0; 0.2, 0.1, 1, -0.3; -0.5, 0, -0.3, 0.9] * 2;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.useLikelihood = false;
        scenarioParam.sysNoise = HypertoroidalWNDistribution([0; 0; 0; 0], Csys);
        Cmeas = Csys';
        scenarioParam.measNoise = HypertoroidalMixture({HypertoroidalWNDistribution([.5; .5; .5; .5], Cmeas), ...
            HypertoroidalWNDistribution([-.5; -.5; -.5; -.5], Cmeas)}, [0.5, 0.5]);
    case 'T5'
        scenarioParam.manifoldType = 'hypertorus';
        scenarioParam.timesteps = 50;
        Csys = [0.4, 0.4, -0.1, 0.1, 0.4; 0.4, 0.7, 0.3, 0.2, 0.7; -0.1, 0.3, 1.1, 0.5, 0.2; 0.1, 0.2, 0.5, 0.6, 0.2; 0.4, 0.7, 0.2, 0.2, 0.9];
        scenarioParam.initialPrior = HypertoroidalWNDistribution(ones(size(Csys, 1), 1), eye(size(Csys)));
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.useLikelihood = false;
        scenarioParam.sysNoise = HypertoroidalWNDistribution(zeros(size(Csys, 1), 1), Csys);
        Cmeas = Csys';
        scenarioParam.measNoise = HypertoroidalMixture({HypertoroidalWNDistribution(.5 * ones(size(Csys, 1), 1), Cmeas), ...
            HypertoroidalWNDistribution(.5 * ones(size(Csys, 1), 1), Cmeas)}, [0.5, 0.5]);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%% (Hyper)spherical scenarios %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'S2xyzSequentiallyThreeTimes'
        scenarioParam.manifoldType = 'hypersphere';
        scenarioParam.sysNoise = VMFDistribution([0; 0; 1], 10);
        scenarioParam.timesteps = 9;
        scenarioParam.applySysNoiseTimes = [false, false, true, false, false, true, false, false, false];
        scenarioParam.initialPrior = HypersphericalUniformDistribution(3);
        scenarioParam.seed = NaN; % This is to be replaced in each run
        sigmaX = 0.3;
        sigmaY = 0.3;
        sigmaZ = 0.3;
        scenarioParam.measPerStep = 3;
        scenarioParam.measGenerator = {@(x)normrnd(x(1), sigmaX), ...
            @(x)normrnd(x(2), sigmaY), @(x)normrnd(x(3), sigmaZ), ...
            @(x)normrnd(x(1), sigmaX), @(x)normrnd(x(2), sigmaY), ...
            @(x)normrnd(x(3), sigmaZ), @(x)normrnd(x(1), sigmaX), ...
            @(x)normrnd(x(2), sigmaY), @(x)normrnd(x(3), sigmaZ)};

        scenarioParam.likelihood = {@(z, x)normpdf(x(1, :), z, sigmaX), ...
            @(z, x)normpdf(x(2, :), z, sigmaY), @(z, x)normpdf(x(3, :), z, sigmaZ), ...
            @(z, x)normpdf(x(1, :), z, sigmaX), @(z, x)normpdf(x(2, :), z, sigmaY), ...
            @(z, x)normpdf(x(3, :), z, sigmaZ), @(z, x)normpdf(x(1, :), z, sigmaX), ...
            @(z, x)normpdf(x(2, :), z, sigmaY), @(z, x)normpdf(x(3, :), z, sigmaZ)};
        scenarioParam.useLikelihood = true;
    case 'S2azAndEleNoiseSphere'
        scenarioParam.manifoldType = 'hypersphere';
        scenarioParam.azNoise = VMDistribution(0, 3);
        scenarioParam.eleNoise = VMDistribution(0, 1);
        scenarioParam.useTransition = true;
        scenarioParam.genNextStateWithoutNoise = @(x)x;
        scenarioParam.genNextStateWithNoise = @(oldState)addAzAndEleNoise(oldState, ...
            scenarioParam.azNoise, scenarioParam.eleNoise);
        scenarioParam.measNoise = VMFDistribution([0; 0; 1], 1);
        scenarioParam.initialPrior = HypersphericalUniformDistribution(3);
        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;
        scenarioParam.kappaMeas = 1;
        scenarioParam.fTrans = @(xkk, xk)cell2mat(arrayfun(@(i) ...
            fTransVMAzEleForSinglexk(xkk, xk(:, i), scenarioParam.azNoise, scenarioParam.eleNoise), ...
            1:size(xk, 2), 'UniformOutput', false)');

        scenarioParam.likelihood = @(z, x) exp(scenarioParam.kappaMeas*z'*x); % Normalization not necessary
        scenarioParam.useLikelihood = true;
    case 'S2nlerp'
        scenarioParam.manifoldType = 'hypersphere';
        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;
        scenarioParam.u = [0; -1; 0];
        scenarioParam.alpha = 0.7;
        scenarioParam.kappaSysNoise = 10;
        scenarioParam.genNextStateWithoutNoise = @(oldState)nlerp(oldState, ...
            scenarioParam.u, scenarioParam.alpha);
        scenarioParam.genNextStateWithNoise = @(oldState)noisyNlerp(oldState, ...
            scenarioParam.u, scenarioParam.alpha, 10);
        scenarioParam.initialPrior = VMFDistribution([0; 0; 1], 10);
        scenarioParam.measNoise = VMFDistribution([0; 0; 1], 10);
        scenarioParam.useLikelihood = false;
        scenarioParam.useTransition = true;
        scenarioParam.fTrans = @(xkk, xk)fTransNlerp(xkk, xk, scenarioParam.u, scenarioParam.alpha, scenarioParam.kappaSysNoise);
        scenarioParam.manifoldType = 'hypersphereGeneral';
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%Symmetric hyperspherical / Hyperhemispherical scenarios%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'S2SymmNlerp'
        scenarioParam.manifoldType = 'hypersphereSymm';
        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;
        scenarioParam.u = [0; -1; 0];
        scenarioParam.alpha = 0.7;
        scenarioParam.kappaSysNoise = 10;
        scenarioParam.genNextStateWithNoise = @(oldState)noisyNlerpWatson(oldState, ...
            scenarioParam.u, scenarioParam.alpha, 10);
        scenarioParam.initialPrior = WatsonDistribution([0; 0; 1], 10);
        scenarioParam.measNoise = WatsonDistribution([0; 0; 1], 10);
        scenarioParam.genNextStateWithoutNoise = @(x)(-1)^round(rand(1)) * nlerp(x, scenarioParam.u, scenarioParam.alpha);
        scenarioParam.useLikelihood = false;
        scenarioParam.useTransition = true;
        scenarioParam.fTrans = @(xkk, xk)fTransNlerpWatson(xkk, xk, scenarioParam.u, scenarioParam.alpha, scenarioParam.kappaSysNoise);
    case 'S2SymmMixture'
        scenarioParam.manifoldType = 'hypersphereSymm';
        scenarioParam.timesteps = 10;
        scenarioParam.measPerStep = 1;

        % Prior
        scenarioParam.muPrior = [0; 0; 1];
        scenarioParam.kappaPrior = 1;
        scenarioParam.initialPrior = HypersphericalMixture({VMFDistribution(scenarioParam.muPrior, scenarioParam.kappaPrior), ...
            VMFDistribution(-scenarioParam.muPrior, scenarioParam.kappaPrior)}, [0.5, 0.5]);
        % System model
        scenarioParam.kappaSys = 10;
        scenarioParam.a = @(x)x;
        scenarioParam.useTransition = true;
        scenarioParam.genNextStateWithNoise = @(x)HypersphericalMixture({VMFDistribution(x, scenarioParam.kappaSys), ...
            VMFDistribution(-x, scenarioParam.kappaSys)}, [0.5, 0.5]).sample(1);
        scenarioParam.fTrans = @(xkk, xk)cell2mat(arrayfun(@(i) ... % * 0.5 and * 2 cancel out
            VMFDistribution(xk(:, i), scenarioParam.kappaSys).pdf(xkk) ...
            +VMFDistribution(xk(:, i), scenarioParam.kappaSys).pdf(-xkk), 1:size(xk, 2), 'UniformOutput', false));

        % Measurement model
        scenarioParam.kappaMeas = 10;
        scenarioParam.measGenerator = @(x)HypersphericalMixture( ...
            {VMFDistribution(x, scenarioParam.kappaMeas), VMFDistribution(-x, scenarioParam.kappaMeas)}, [0.5, 0.5]).sample(1);
        % Likelihood is commutative, write it so that it is more efficient
        scenarioParam.useLikelihood = true;
        scenarioParam.likelihood = @(z, x)HypersphericalMixture( ...
            {VMFDistribution(z, scenarioParam.kappaMeas), VMFDistribution(-z, scenarioParam.kappaMeas)}, [0.5, 0.5]).pdf(x);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%% SE2 scenarios %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'se2randomDirectedWalk'
        scenarioParam.timesteps = scenarioCustomizationParams;
        scenarioParam.manifoldType = 'se2';
        scenarioParam.measPerStep = 1;
        % This normally does not need to accept vector-valued inputs, we do so for
        % compatibility with the pf
        scenarioParam.useTransition = true;

        scenarioParam.initialPriorPeriodic = VMDistribution(0, 1);
        scenarioParam.initialPriorLinear = GaussianDistribution([0; 0], eye(2));
        scenarioParam.initialPrior = SE2CartProdStackedDistribution( ...
            {scenarioParam.initialPriorPeriodic; scenarioParam.initialPriorLinear});

        scenarioParam.vmSysNoise = VMDistribution(0, 10);
        scenarioParam.gaussianSysNoise = GaussianDistribution([0; 0], eye(2));
        scenarioParam.sysNoise = SE2CartProdStackedDistribution( ...
            {scenarioParam.vmSysNoise, scenarioParam.gaussianSysNoise});

        scenarioParam.gaussianMeasNoise = GaussianDistribution([0; 0], 0.5*eye(2));

        scenarioParam.stepSize = 1;
        scenarioParam.genNextStateWithoutNoise = ...
            @(x)[x(1, :); x(2:3, :) + scenarioParam.stepSize * [cos(x(1, :)); sin(x(1, :))]];

        scenarioParam.inputsGenerator = @(fullGrid)reshape(stepSize*[cos(fullGrid); sin(fullGrid)], 2, 1, 1, size(apf.getEstimate().gd.gridValues, 1));
        scenarioParam.measGenerator = @(x)x(2:3) + scenarioParam.gaussianMeasNoise.sample(1);
        scenarioParam.useLikelihood = true;
        scenarioParam.likelihood = @(z, x)mvnpdf(x(2:3, :)', z', scenarioParam.gaussianMeasNoise.C)';
    otherwise
        warning('Scenario not recognized. Assuming scenarioCustomizationParams contains all parameters.')
        scenarioParam = scenarioCustomizationParams;
end
end

function p = fTransNlerp(xkk, xk, u, alpha, kappaNoise)
arguments
    xkk(3, :) double
    xk(3, :) double
    u(3, 1) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end
p = NaN(size(xkk, 2), size(xk, 2));
for i = 1:size(xk, 2)
    p(:, i) = fTransNlerpSingleXk(xkk, xk(:, i), u, alpha, kappaNoise);
end
end

function p = fTransNlerpSingleXk(xkk, xk, u, alpha, kappaNoise)
arguments
    xkk(3, :) double
    xk(3, 1) double
    u(3, :) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end

vmfNoise = VMFDistribution(nlerp(xk, u, alpha), kappaNoise);
p = vmfNoise.pdf(xkk);
end

function p = fTransNlerpWatson(xkk, xk, u, alpha, kappaNoise)
arguments
    xkk(3, :) double
    xk(3, :) double
    u(3, 1) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end
p = NaN(size(xkk, 2), size(xk, 2));
for i = 1:size(xk, 2)
    p(:, i) = fTransNlerpSingleXkWatson(xkk, xk(:, i), u, alpha, kappaNoise);
end
end

function p = fTransNlerpSingleXkWatson(xkk, xk, u, alpha, kappaNoise)
arguments
    xkk(3, :) double
    xk(3, 1) double
    u(3, :) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end
vmfNoise = WatsonDistribution(nlerp(xk, u, alpha), kappaNoise);
p = vmfNoise.pdf(xkk);
end

function xkk = noisyNlerp(xk, u, alpha, kappaNoise)
arguments
    xk(3, 1) double
    u(3, 1) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end
vmfNoise = VMFDistribution(nlerp(xk, u, alpha), kappaNoise);
xkk = vmfNoise.sample(1);
end

function xkk = noisyNlerpWatson(xk, u, alpha, kappaNoise)
arguments
    xk(3, 1) double
    u(3, 1) double
    alpha(1, 1) double
    kappaNoise(1, 1) double
end
vmfNoise = WatsonDistribution(nlerp(xk, u, alpha), kappaNoise);
xkk = vmfNoise.sample(1);
end

function xkk = nlerp(xk, u, alpha)
arguments
    xk(3, 1) double
    u(3, 1) double
    alpha(1, 1) double
end
xNewUnnormalized = alpha * xk + (1 - alpha) * u;
xkk = xNewUnnormalized / norm(xNewUnnormalized);
end

function p = fTransVMAzEleForSinglexk(xkk, xk, azNoiseCurr, eleNoiseCurr)
arguments
    xkk(3, :) double
    xk(3, 1) double
    azNoiseCurr VMDistribution
    eleNoiseCurr VMDistribution
end
[azk, elek] = cart2sph(xk(1), xk(2), xk(3));
azNoiseCurr.mu = azk;
eleNoiseCurr.mu = elek + pi / 2;

pdf = @(azkkAll, elekkAll)(azNoiseCurr.pdf(azkkAll) .* eleNoiseCurr.pdf(elekkAll) + azNoiseCurr.pdf(azkkAll + pi) .* eleNoiseCurr.pdf(-elekkAll));
pdfHypersphere = @(x)pdf(atan2(x(2, :), x(1, :)), atan2(x(3, :), hypot(x(1, :), x(2, :)))+pi/2) ...
    ./ (sin(atan2(x(3, :), hypot(x(1, :), x(2, :))) + pi / 2) + eps); % +eps to avoid division by zero
p = pdfHypersphere(xkk);
end

function newStates = addAzAndEleNoise(oldStates, azNoise, eleNoise)
[az, ele] = cart2sph(oldStates(1, :), oldStates(2, :), oldStates(3, :));
az = az + azNoise.sample(numel(az)); % Plus is allowed for 1D
ele = ele + eleNoise.sample(numel(ele)); % Plus is allowed for 1D
[x, y, z] = sph2cart(az, ele, 1);
newStates = [x; y; z];
end

function p = fTransIgorsFun3d(xkk, xk, param1, param2, param3, sysNoise)
arguments
    xkk(3, :) double
    xk(3, :) double
    param1(1, 1) double
    param2(1, 1) double
    param3(1, 1) double
    sysNoise AbstractHypertoroidalDistribution
end
assert(sysNoise.dim == 3);
p = NaN(size(xkk, 2), size(xk, 2));
for i = 1:size(xk, 2)
    p(:, i) = sysNoise.shift(igorsFun3Dvec(xk(1, i), xk(2, i), xk(3, i), param1, param2, param3)).pdf(xkk);
end
end

function x = igorsFun3Dvec(x1, x2, x3, param1, param2, param3)
% 3-D Igor's function
x1 = mod(x1, 2*pi);
x2 = mod(x2, 2*pi);
x3 = mod(x3, 2*pi);
x1Propagated = pi * (sin(sign(x1 - pi) / 2 .* abs(x1 - pi).^param1 / pi^(param1 - 1)) + 1);
x2Propagated = pi * (sin(sign(x2 - pi) / 2 .* abs(x2 - pi).^param2 / pi^(param2 - 1)) + 1);
x3Propagated = pi * (sin(sign(x3 - pi) / 2 .* abs(x2 - pi).^param3 / pi^(param3 - 1)) + 1);
x = [x1Propagated; x2Propagated; x3Propagated];
end

function [x1Propagated, x2Propagated, x3Propagated] = igorsFun3D(x1, x2, x3, param1, param2, param3)
% 3-D Igor's function
x1 = mod(x1, 2*pi);
x2 = mod(x2, 2*pi);
x3 = mod(x3, 2*pi);
x1Propagated = pi * (sin(sign(x1 - pi) / 2 .* abs(x1 - pi).^param1 / pi^(param1 - 1)) + 1);
x2Propagated = pi * (sin(sign(x2 - pi) / 2 .* abs(x2 - pi).^param2 / pi^(param2 - 1)) + 1);
x3Propagated = pi * (sin(sign(x3 - pi) / 2 .* abs(x2 - pi).^param3 / pi^(param3 - 1)) + 1);
end


function p = fTransIgorsFun2d(xkk, xk, param1, param2, sysNoise)
arguments
    xkk(2, :) double
    xk(2, :) double
    param1(1, 1) double
    param2(1, 1) double
    sysNoise AbstractHypertoroidalDistribution
end
assert(sysNoise.dim == 2);
p = NaN(size(xkk, 2), size(xk, 2));
for i = 1:size(xk, 2)
    p(:, i) = sysNoise.shift(igorsFun2Dvec(xk(1, i), xk(2, i), param1, param2)).pdf(xkk);
end
end

function p = fTransIgorsFun2dSingleXk(xkk, xk, param1, param2, sysNoise) %#ok<DEFNU>
arguments
    xkk(2, :) double
    xk(2, :) double
    param1(1, 1) double
    param2(1, 1) double
    sysNoise AbstractHypertoroidalDistribution
end

noise = sysNoise.shift(igorsFun2Dvec(xk(1), xk(2), param1, param2));
p = noise.pdf(xkk);
end

function x = igorsFun2Dvec(x1, x2, param1, param2)
% 2-D Igor's function
x1 = mod(x1, 2*pi);
x2 = mod(x2, 2*pi);
x1Propagated = pi * (sin(sign(x1 - pi) / 2 .* abs(x1 - pi).^param1 / pi^(param1 - 1)) + 1);
x2Propagated = pi * (sin(sign(x2 - pi) / 2 .* abs(x2 - pi).^param2 / pi^(param2 - 1)) + 1);
x = [x1Propagated; x2Propagated];
end

function [x1Propagated, x2Propagated] = igor2D(x1, x2, param1, param2)
% 1-D Igor's function
x1 = mod(x1, 2*pi);
x2 = mod(x2, 2*pi);
x1Propagated = pi * (sin(sign(x1 - pi) / 2 .* abs(x1 - pi).^param1 / pi^(param1 - 1)) + 1);
x2Propagated = pi * (sin(sign(x2 - pi) / 2 .* abs(x2 - pi).^param2 / pi^(param2 - 1)) + 1);
end

function x1 = igor1D(x1, param1)
% 1-D Igor's function
x1 = pi * (sin(sign(x1 - pi) / 2 .* abs(x1 - pi).^param1 / pi^(param1 - 1)) + 1);
end
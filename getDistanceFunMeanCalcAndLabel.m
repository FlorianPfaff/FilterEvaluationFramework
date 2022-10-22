function [distanceFunction, extractMean, errorLabel] = getDistanceFunMeanCalcAndLabel(mode)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V2.9
arguments
    mode char
end
switch mode
    case {'circleSymm1Highest', 'circleSymm2Highest', 'circleSymm3Highest', 'circleSymm4Highest', 'circleSymm5Highest', ...
            'circleSymm6Highest', 'circleSymm7Highest', 'circleSymm8Highest', 'circleSymm9Highest', ...
            'circleSymm1All', 'circleSymm2All', 'circleSymm3All', 'circleSymm4All', 'circleSymm5All', ...
            'circleSymm6All', 'circleSymm7All', 'circleSymm8All', 'circleSymm9All', ...
            'circleSymm1MinExpDev', 'circleSymm2MinExpDev', 'circleSymm3MinExpDev', 'circleSymm4MinExpDev', 'circleSymm5MinExpDev', ...
            'circleSymm6MinExpDev', 'circleSymm7MinExpDev', 'circleSymm8MinExpDev', 'circleSymm9MinExpDev'}
        errorLabel = 'Error in radian';
        nSymm = sscanf(mode, 'circleSymm%d');
        symmetryOffsets = linspace(0, 2*pi, nSymm+1);
        symmetryOffsets(end) = [];
        if contains(mode, 'Highest')
            % Use the highest peak and compare it to the
            % closest real mode
            extractMean = @(filterState)fminbnd(@(input)reshape(-filterState.pdf(input(:)'), size(input)), 0, 2*pi);
            distanceFunction = @(xest, xtrue)min(angularError(xest, xtrue + reshape(symmetryOffsets, 1, 1, [])), [], 3);
        elseif contains(mode, 'All')
            % Consider mean error for all modes
            % Find all modes (along dim 3)
            extractMean = @(filterState)findAllModes(filterState, nSymm);
            % Compare with all possible true modes (along dim 4), then take
            % min (to do a proper "assignment") and then
            distanceFunction = @(xest, xtrue)mean(min(angularError(xest, xtrue + reshape(symmetryOffsets, 1, 1, 1, [])), [], 4), 3);
        elseif contains(mode, 'MinExpDev')
            distanceFunction = @(xest, xtrue)min(angularError(xest, xtrue + reshape(symmetryOffsets, 1, 1, [])), [], 3);
            extractMean = @(filterState)fminbnd(@(possibleEst) ...
                integral(@(x)distanceFunction(possibleEst, x) .* filterState.pdf(x), 0, 2 * pi), 0, 2*pi);
        else
            error('Not supported');
        end
    case {'circle', 'hypertorus'}
        distanceFunction = @(xest, xtrue)norm(angularError(xest, xtrue));
        errorLabel = 'Error in radian';
        % This is overwritten below if lastFilterState is not vailable
        extractMean = @(filterState)filterState.meanDirection();
    case {'hypersphere', 'hypersphereGeneral'}
        distanceFunction = @(x1, x2)acos(dot(x1, x2));
        extractMean = @(filterState)filterState.meanDirection();
        errorLabel = 'Error (orthodromic distance) in radian';
    case 'hypersphereSymm'
        distanceFunction = @(x1, x2)min(acos(dot(x1, x2)), acos(dot(x1, -x2))); % With two arguments to calculate it over the entire array
        extractMean = 'custom';
        errorLabel = 'Angular error in radian';
    case {'se2','se2linear'}
        distanceFunction = @(x1, x2)vecnorm(x1(2:3, :)-x2(2:3, :));
        extractMean = @extractEstimateSE2;
        errorLabel = 'Error in meters';
    case 'se2bounded'
        distanceFunction = @(xest, xtrue)norm(angularError(xest(1,:), xtrue(1,:)));
        extractMean = @extractEstimateSE2;
        errorLabel = 'Error in radian';
    case {'se3','se3linear'}
        distanceFunction = @(x1, x2)vecnorm(x1(5:7, :)-x2(5:7, :));
        extractMean = @(filterState)filterState.hybridMean();
        errorLabel = 'Error in meters';
    case 'se3bounded'
        distanceFunction = @(x1, x2)min(acos(dot(x1(1:4), x2(1:4))), acos(dot(x1(1:4), -x2(1:4)))); % With two arguments to calculate it over the entire array
        extractMean = @(filterState)filterState.hybridMean();
        errorLabel = 'Error in radian';
    case {'euclidean', 'Euclidean'}
        distanceFunction = @(x1, x2)vecnorm(x1-x2);
        extractMean = @(filterState)filterState.mean();
        errorLabel = 'Error in meters';
    otherwise
        error('Mode not recognized');
end
end

function est = extractEstimateSE2(filterState)
if isa(filterState, 'SE2BinghamDistribution')
    est = AbstractSE2Distribution.dualQuaternionToAnglePos(filterState.mode());
else
    est = filterState.hybridMean; % Without () to allow extracting it from a struct
end
end

function allModes = findAllModes(filterState, nSymm)
arguments
    filterState(1, 1) AbstractCircularDistribution
    nSymm(1, 1) double {mustBePositive, mustBeInteger}
end
highestMode = fminbnd(@(input)reshape(-filterState.pdf(input(:)'), size(input)), 0, 2*pi);
region = [highestMode - pi / nSymm, highestMode + pi / nSymm];
allModes = NaN(1, 1, nSymm);
allModes(1) = highestMode;
for i = 2:nSymm
    region = region + 2 * pi / nSymm;
    allModes(i) = fminbnd(@(input)reshape(-filterState.pdf(input(:)'), size(input)), region(1), region(2));
end
allModes = mod(allModes, 2*pi);
end
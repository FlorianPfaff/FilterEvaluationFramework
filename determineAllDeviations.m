function [allDeviationsLastMat, allExpectedDeviationsLastMat] = determineAllDeviations(results, extractMean, distanceFunction, meanCalculationSymm, groundtruths)
% If two outputs: Assume that extractMean returns the expected
% deviation as the second output argument. This is useful when finding
% the estimate that minimizes the expected deviation via fminbnd.
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
arguments
    results struct
    extractMean
    distanceFunction(1, 1) function_handle
    meanCalculationSymm char = ''
    groundtruths cell = {}
end
allDeviationsLastMat = repmat({NaN(size(groundtruths))}, size(results));
if nargout == 2
    allExpectedDeviationsLastMat = repmat({NaN(size(groundtruths))}, size(results));
end
for config = 1:size(results, 2)
    % Allow filters to bring own groundtruths to be able to combine
    % different evaluation runs. If they do not bring it, set their groundtruth as
    % default
    if isfield(results, 'groundtruths') && ~isempty(results(config).groundtruths)
        warning('%s with %d parameters uses other groundtruth from a different evaluation. Make sure the scenarios are the same and sufficient runs are used have a good average.', ...
            results(config).filterName, results(config).filterParams);
        currGts = results(config).groundtruths';
    else
        currGts = groundtruths;
    end
    for run = 1:numel(groundtruths)
        if isa(extractMean, 'function_handle')
            if nargout == 1
                finalEstimate = extractMean(results(config).lastFilterStates(run));
            elseif nargout == 2
                [finalEstimate, allExpectedDeviationsLastMat{config}(run)] = extractMean(results(config).lastFilterStates(run));
            else
                error('This should not happen');
            end
        else
            assert(strcmp(extractMean, 'custom'));
            switch results(config).filterName
                case 'hhgf'
                    switch meanCalculationSymm
                        case 'meanShift'
                            gridValues = results(config).lastFilterStates(run).gridValues;
                            finalEstimate = sphMeanShift(results(config).lastFilterStates(run).grid, gridValues'/sum(gridValues));
                        case 'Bingham'
                            gdFullSphere = results(config).lastFilterStates(run).toFullSphere;
                            finalEstimate = BinghamDistribution.fit(gdFullSphere.getGrid(), gdFullSphere.gridValues'/sum(gdFullSphere.gridValues)).mode;
                        case 'meanDirection'
                            finalEstimate = results(config).lastFilterStates(run).meanDirection;
                        otherwise
                            error('meanCalculation not recognized')
                    end
                case {'hgf', 'hgfSymm'}
                    switch meanCalculationSymm
                        case 'meanShift'
                            gridValues = results(config).lastFilterStates(run).gridValues;
                            finalEstimate = sphMeanShift(results(config).lastFilterStates(run).grid, gridValues'/sum(gridValues));
                        case 'Bingham'
                            gd = results(config).lastFilterStates(run);
                            finalEstimate = BinghamDistribution.fit(gd.getGrid(), gd.gridValues'/sum(gd.gridValues)).mode;
                        case 'meanDirection'
                            finalEstimate = results(config).lastFilterStates(run).meanDirection;
                        otherwise
                            error('meanCalculation not recognized')
                    end
                case 'pf'
                    switch meanCalculationSymm
                        case 'meanShift'
                            finalEstimate = sphMeanShift(results(config).lastFilterStates(run).d, results(config).lastFilterStates(run).w);
                        case 'Bingham'
                            finalEstimate = BinghamDistribution.fit(results(config).lastFilterStates(run).d, results(config).lastFilterStates(run).w).mode;
                        case 'meanDirection'
                            finalEstimate = results(config).lastFilterStates(run).meanDirection;
                        otherwise
                            error('meanCalculation not recognized')
                    end
                case {'random', 'randomSphere'}
                    finalEstimate = results(config).lastFilterStates(run).sample(1);
                case 'bingham'
                    finalEstimate = results(config).lastFilterStates(run).mode;
                otherwise
                    error('Filter not recognized');
            end
        end
        if ~isempty(finalEstimate)
            allDeviationsLastMat{config}(run) = distanceFunction(finalEstimate, currGts{run}(:, end));
        else % Set to inf if filter failed
            allDeviationsLastMat{config}(run) = inf;
        end
    end
    if sum(isinf(allDeviationsLastMat{config})) > 0
        warning('%s with %d parameters apparently failed %d times. Check if this is plausible.', ...
            results(config).filterName, results(config).filterParams, sum(isinf(allDeviationsLastMat{config})));
    end
end
end
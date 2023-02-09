function plotFilterStateAndGt(filter, groundtruth, measurements, timeIndex, measIndex, scenarioParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2023
arguments
    filter (1,1) AbstractFilter
    groundtruth (:,:) double
    measurements (:,:) double
    timeIndex (1,1) {mustBeInteger, mustBePositive}
    measIndex (1,1) {mustBeInteger, mustBeNonnegative}
    scenarioParam struct = struct()
end
currentGroundtruth = groundtruth(:, timeIndex);
if isa(filter, 'AbstractHypertoroidalFilter') || isa(filter.getEstimate(), 'AbstractHypertoroidalDistribution')
    figure(765), clf, shg
    filter.plotFilterState();
    if filter.getEstimate().dim == 1
        line([currentGroundtruth, currentGroundtruth], ylim(), 'color', 'r');
    end
    drawnow, pause(0.5);
elseif isa(filter, 'AbstractHypersphericalFilter') || isa(filter.getEstimate(), 'AbstractHypersphericalDistribution')
    figure(765), clf, shg
    filter.plotFilterState();
    xlabel('x');
    ylabel('y');
    zlabel('z');
    title(sprintf('t=%d m=%d', timeIndex, measIndex));
    hold on
    pause(1);
    if isa(filter, 'HypersphericalParticleFilter'), AbstractHypersphericalDistribution.plotSphere; end
    scatter3(currentGroundtruth(1), currentGroundtruth(2), currentGroundtruth(3), 100, [1, 0, 0], 'filled');
    mu = filter.getEstimateMean;
    scatter3(mu(1), mu(2), mu(3), 100, [1, 1, 0], 'filled');
    drawnow
elseif isa(filter, 'AbstractSE2Filter') || isa(filter.getEstimate(), 'AbstractSE2Distribution')
    if isa(filter, 'SE2UKFM')
        error('Plotting state not supported for UFKM');
    end
    if measIndex == 0
        figNo = 765;
        currTitle = 'Prior';
    else
        figNo = 766;
        currTitle = 'Posterior';
    end
    figure(figNo)
    if timeIndex == 1 && (measIndex == 0 || measIndex == 1)
        xlimits = xlim;
        ylimits = ylim;
    else
        xlimits = [-10, 10];
        ylimits = [-10, 10];
    end
    clf, title(currTitle);
    filter.getEstimate().plotSE2State();
    hold on
    if all(groundtruth(2, max(timeIndex - 3, 1):timeIndex) < xlimits(1)) || all(groundtruth(2, max(timeIndex - 3, 1):timeIndex) > xlimits(2))
        xlimits = [-10, 10] + mean(groundtruth(2, max(timeIndex - 3, 1):timeIndex));
    end
    if all(groundtruth(3, max(timeIndex - 3, 1):timeIndex) < ylimits(1)) || all(groundtruth(3, max(timeIndex - 3, 1):timeIndex) > ylimits(2))
        ylimits = [-10, 10] + mean(groundtruth(3, max(timeIndex - 3, 1):timeIndex));
    end
    xlim(xlimits)
    ylim(ylimits)
    AbstractSE2Distribution.plotSE2trajectory(groundtruth(1, (max(timeIndex - 10, 1)):timeIndex), groundtruth(2:3, (max(timeIndex - 10, 1)):timeIndex), false);
    scatter(measurements(1, (max(timeIndex - 10, 1)):timeIndex), measurements(2, (max(timeIndex - 10, 1)):timeIndex), 'x');
elseif isa(filter, 'AbstractLinearFilter') || isa(filter.getEstimate(), 'AbstractLinearDistribution')
    switch this.dim
        case 2
            filter.plotFilterState();
            scatter(currentGroundtruth(1), currentGroundtruth(2));
        case 3
            filter.plotFilterState();
            scatter3(currentGroundtruth(1), currentGroundtruth(2), currentGroundtruth(3));
        otherwise
            error('Dimension currently unsupported.')
    end
elseif isa(filter, 'AbstractMultitargetTracker')
    if isfield(scenarioParam, 'observedArea')
        axes(scenarioParam.observedArea);
    end
    filter.plotFilterState();
else
    filter.plotFilterState();    
end
end
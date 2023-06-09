classdef (SharedTestFixtures={matlab.unittest.fixtures.TemporaryFolderFixture,...
        ...% Some warnings can happen, e.g., due to the low number of
        ...% coefficients, but these are not related to this framework and
        ...% can be useful as information to users (outside of test
        ...% cases).
        matlab.unittest.fixtures.SuppressedWarningsFixture(...
        {'MATLAB:hg:AutoSoftwareOpenGL', 'PlotResults:FewRuns',...
        'Normalization:notNormalized', 'Normalization:negative',...
        'FilterEvaluationFramework:TWNUniform',...
        'getDistanceFunMeanCalcAndLabel:OSPAUnspecifiedCutoff'})})...
        FilterEvaluationFrameworkTest < matlab.unittest.TestCase
    % @author Florian Pfaff pfaff@kit.edu
    % @date 2016-2023
    properties (Constant)
        noRunsDefault = 10
    end
    methods (Test)
        function testR2randomWalk(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'R2randomWalk';
            filters = struct( ...
                'name', {'kf', 'pf'}, 'filterParams', {NaN, [51, 81]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1);
        end
        function testR4randomWalk(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'R4randomWalk';
            filters = struct( ...
                'name', {'kf', 'pf'}, 'filterParams', {NaN, [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 2);
        end
        function testSE2filters(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'se2randomDirectedWalk';
            filters = struct('name', {'se2ukfm', 'pf', 'se2bf', 's3f'}, ...
                'filterParams', {[1e-3, 1e-2, 1e-1, 1], [101, 201], NaN, ...
                [150, 200]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1,...
                scenarioCustomizationParams = 50, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            isSE2bf = strcmp({paramTimeAndErrorPerFilter.filterName}, 'se2bf');
            testCase.verifyLessThan([paramTimeAndErrorPerFilter(~isSE2bf).meanErrorAllConfigs], 1.5);
        end
        function testSE3filters(testCase)
            tempFixture = testCase.getSharedTestFixtures();     
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture({...
                'FilterEvaluationFramework:genNextStateWithNoiseNotVectorizedForPF',...
                'FilterEvaluationFramework:genNextStateWithoutNoiseNotVectorizedForPF',...
                'AbstractHypersphereSubsetDistribution:meanAxisUnreliable'}));
            scenarioName = 'se3randomDirectedWalk';
            filters = struct('name', {'s3f','pf'},'filterParams', {[15, 20],[200, 1000]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1,...
                scenarioCustomizationParams = 50, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan(paramTimeAndErrorPerFilter(1).meanErrorAllConfigs(end), 1.9);
            testCase.verifyLessThan(paramTimeAndErrorPerFilter(2).meanErrorAllConfigs(end), 1.9);
        end
        function testRandomFilter(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'random'}, ...
                'filterParams', {[5, 7], NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder,...
                convertToPointEstimateDuringRuntime = true, autoWarningOnOff=false);
        end
        function testCombineMats(testCase)
            % Use a different temporary filter for this test case so we
            % only have the .mat files of this test in the folder.
            tempFolderFixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFolderFixture.Folder, autoWarningOnOff=false);
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFolderFixture.Folder, autoWarningOnOff=false);

            files = dir(tempFolderFixture.Folder);
            matFiles = files(contains({files.name}, 'S1Igors'));
            matFilesFullPath = cellfun(@(name, folder){fullfile(folder, name)}, {matFiles.name}, {matFiles.folder});
            testCase.verifyWarningFree(@()combineMats(matFilesFullPath));
        end
        function testPlotResultsBoxplot(testCase)
            tempFixture = testCase.getSharedTestFixtures();

            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, autoWarningOnOff=false);
            plotResultsBoxplot();
        end

        function testPlotErrorsForAllTimeSteps(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture(...
                'FilterEvaluationFramework:SlowdownExtractEstimates'));
            noRunsSpecific = 2;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'pf'}, ...
                'filterParams', {[5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, noRunsSpecific,...
                plotEachStep = true, saveFolder = tempFixture(1).Folder,...
                extractAllPointEstimates = true, autoWarningOnOff=false);
        end
        
        function testConvertToPointEstimateDuringRuntime(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture(...
                'FilterEvaluationFramework:FilterStatesNotFoundForPlotting'));
            scenarioName = 'se2randomDirectedWalk';
            filters = struct('name', {'pf', 'se2bf', 's3f'}, ...
                'filterParams', {[101, 201], NaN, [150, 200]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault, scenarioCustomizationParams=3,...
                saveFolder = tempFixture(1).Folder, plotEachStep=false,...
                convertToPointEstimateDuringRuntime=true, tolerateFailure=true,...
                autoWarningOnOff=false);
            plotResults();
        end

        function testInputs(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'R4randomWalkWithInputs';
            filters = struct( ...
                'name', {'kf', 'pf'}, 'filterParams', {NaN, [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.5);
        end

        function testGenerateGTAndMeasurementsMTT(testCase)
            scenarioName = 'MTT3targetsR2';
            scenarioParam = scenarioDatabase(scenarioName);
            scenarioParam = checkAndFixParams(scenarioParam);
            x0T1 = [1;1;1;1];
            x0T2 = -[1;1;1;1];
            x0T3 = [1;-1;1;-1];
            groundtruth = generateGroundtruth(cat(3, x0T1, x0T2, x0T3), scenarioParam);
            measurements = generateMeasurements(groundtruth, scenarioParam);
            testCase.verifySize(measurements, [1,scenarioParam.timesteps])
            cellfun(@(m)testCase.verifySize(m, [2,3]), measurements)
        end
        
        function testDistanceMetricMTTOspaZeroWhenEqualSingleTarget(testCase)
            distanceFunction = getDistanceFunMeanCalcAndLabel('MTTEuclidean');
            % Distance should be zero when both are equal (for 1 target)
            testCase.verifyEqual(distanceFunction([1;2;3;4],[1;2;3;4]), 0);
            testCase.verifyEqual(distanceFunction([1;2;3;4;5;6],[1;2;3;4;5;6]), 0);
            % Distance should still be zero when only the velocity differs (for 1 target)
            testCase.verifyEqual(distanceFunction([1;10;3;30],[1;20;3;40]), 0);
            testCase.verifyEqual(distanceFunction([1;10;3;30;5;50],[1;20;3;40;5;60]), 0);
        end
        function testDistanceMetricMTTOspaZeroWhenEqualMultiTarget(testCase)
            distanceFunction = getDistanceFunMeanCalcAndLabel('MTTEuclidean');
            % Distance should be zero when both are equal (for 2 targets)
            testCase.verifyEqual(distanceFunction([[10;30;40;50],[10;30;40;50]+10],...
                [[10;30;40;50],[10;30;40;50]+10]), 0);
            testCase.verifyEqual(distanceFunction([[10;30;40;50;0;0],[10;30;40;50;0;0]+10],...
                [[10;30;40;50;0;0],[10;30;40;50;0;0]+10]), 0);
            % Distance should still be zero when only the velocity differs (for 2 targets)
            testCase.verifyEqual(distanceFunction([[10;30;40;50],[10;30;40;50]+10],...
                [[10;130;40;150],[10;130;40;150]+10]), 0);
            testCase.verifyEqual(distanceFunction([[10;30;40;50;0;0],[10;30;40;50;0;0]+10],...
                [[10;130;40;150;0;0],[10;130;40;150;0;0]+10]), 0);
            % Distance should still be zero even when the target order is
            % swapped
            testCase.verifyEqual(distanceFunction([[10;30;40;50],[10;30;40;50]+10],...
                [[10;130;40;150]+10,[10;130;40;150]]), 0);
            testCase.verifyEqual(distanceFunction([[10;30;40;50;0;0],[10;30;40;50;0;0]+10],...
                [[10;130;40;150;0;0]+10,[10;130;40;150;0;0]]), 0);
        end

        function testDistanceMetricMTTOspaWhenUnequalSingleTarget(testCase)
            distanceFunction = getDistanceFunMeanCalcAndLabel('MTTEuclidean');
            % Test some examples for which we can easily determine the real
            % value
            trackStates = [1;2;3;4];
            testCase.verifyEqual(distanceFunction(trackStates, trackStates), 0);
            for padTo3D = [false, true]
                trackStatesCurr = [trackStates; zeros(2*padTo3D, size(trackStates,2))];
                for i = 1:numel(trackStatesCurr)
                    % Change all values in the matrix for the true state
                    % isolatedly.
                    truthsCurr = trackStatesCurr;
                    truthsCurr(i) = truthsCurr(i) + 5;
                    % If even: Is velocity. If odd: Is position
                    if mod(i,2)==0
                        testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), 0);
                    else
                        testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), 5);
                    end
                end
                % Now, always modify the first entry (which is a position component)
                % and then try changing all of the others
                for i = 2:numel(trackStatesCurr)
                    % Change all values in the matrix for the true state
                    % isolatedly.
                    truthsCurr = trackStatesCurr;
                    truthsCurr(1) = truthsCurr(1) + 5;
                    truthsCurr(i) = truthsCurr(i) + 5;
                    % If even: Is velocity. If odd: Is position
                    if mod(i,2)==0
                        testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), 5);
                    else
                        testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), sqrt(2*5^2), 'AbsTol', 1e-10);
                    end
                end
            end
        testCase.verifyEqual(distanceFunction([1;2;3;4;5;6],[11;2;13;4;15;6]), sqrt(3*10^2));
        testCase.verifyEqual(distanceFunction([1;2;3;4;5;6],[11;12;13;14;15;16]), sqrt(3*10^2));
        end
        
        function testDistanceMetricMTTOspaWhenUnequalMultitarget(testCase)
            distanceFunction = getDistanceFunMeanCalcAndLabel('MTTEuclidean');
            trackStates = [[10;30;40;50],[10;30;40;50]+10];
            testCase.verifyEqual(distanceFunction(trackStates,trackStates), 0);
            % Should not depend on the order of the true states
            for swapOrderForTruth = [false, true]
                % Try for 2-D tracking with 4 components and 3-D tracking with
                % 6 components.
                for padTo3D = [false, true]
                    trackStatesCurr = [trackStates; zeros(2*padTo3D, size(trackStates,2))];
                    for i = 1:numel(trackStatesCurr)
                        % Change all values in the matrix for the true state
                        % isolatedly.
                        truthsCurr = trackStatesCurr;
                        if swapOrderForTruth
                            truthsCurr = fliplr(truthsCurr);
                        end
                        truthsCurr(i) = truthsCurr(i) + 3;
                        % If even: Is velocity. If odd: Is position
                        if mod(i,2)==0
                            testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), 0);
                        else
                            testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), sqrt(1/2*3^2));
                        end
                    end
                    % Now, always modify the first entry (which is a position component)
                    % and then try changing all of the others
                    for i = 2:numel(trackStatesCurr)
                        % Change all values in the matrix for the true state
                        % isolatedly.
                        truthsCurr = trackStatesCurr;
                        if swapOrderForTruth
                            truthsCurr = fliplr(truthsCurr);
                        end
                        truthsCurr(1) = truthsCurr(1) + 3;
                        truthsCurr(i) = truthsCurr(i) + 3;
                        % If even: Is velocity. If odd: Is position
                        if mod(i,2)==0
                            testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), sqrt(1/2*3^2));
                        else
                            testCase.verifyEqual(distanceFunction(trackStatesCurr,truthsCurr), 3, 'AbsTol', 1e-10);
                        end
                    end
                end
            end
        end

        function testMTT(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'MTT3targetsR2';
            filters = struct( ...
                'name', {'GNN'}, 'filterParams', {NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 10);
        end
    end
end
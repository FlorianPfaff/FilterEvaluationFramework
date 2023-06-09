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
        function testCircularFilters(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault, ...
                saveFolder = tempFixture(1).Folder, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi*0.8);
        end
        function testHypertoroidalFiltersT2unimodal(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T2unimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault, ...
                saveFolder = tempFixture(1).Folder, initialSeed = 2, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);
        end
        function testHypertoroidalFiltersT2bimodal(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T2bimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault, ...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);
        end
        function testHypertoroidalFiltersT2twnMixture(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T2twnMixtureLooksUnimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);
        end
        function testHypertoroidalFiltersT2IgorsFunctionCustom(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T2IgorsFunctionCustom';
            filters = struct( ...
                'name', {'iff', 'sqff', 'htgf', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, ...
                scenarioCustomizationParams = [1.5, 2], autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);
        end
        function testHypertoroidalFiltersT3IgorsFunctionCustom(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T3IgorsFunctionCustom';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1,...
                scenarioCustomizationParams = [0.5, 1, 1.5], autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);
        end
        function testHypertoroidalFiltersT3HighNoise(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T3HighNoise';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[7, 9], [7, 9], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);
        end
        function testHypertoroidalFiltersT3LowNoise(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T3LowNoise';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[7, 9], [7, 9], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);
        end
        function testHypertoroidalFiltersT3LowSysNoiseBimodal(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T3LowSysNoiseBimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[7, 9], [7, 9], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);
        end
        function testHypertoroidalFiltersT4(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T4';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[7, 9], [7, 9], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);
        end
        function testHypertoroidalFiltersT5(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            scenarioName = 'T5';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[3, 5], [3, 5], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.5*pi);
        end
        function testHypersphericalFiltersS2xyzSequentiallyThreeTimes(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture('setState:nonGrid'));
            scenarioName = 'S2xyzSequentiallyThreeTimes';
            filters = struct( ...
                'name', {'ishf', 'sqshf', 'pf'}, ...
                'filterParams', {[15, 19], [15, 19], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testHypersphericalFiltersS2azAndEleNoiseSphere(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture('setState:nonGrid'));
            scenarioName = 'S2azAndEleNoiseSphere';
            filters = struct( ...
                'name', {'sgf', 'hgf', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testHypersphericalFiltersS2nlerp(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture({...
                'setState:nonGrid', 'FilterEvaluationFramework:genNextStateWithNoiseNotVectorizedForPF',...
                'FilterEvaluationFramework:genNextStateWithoutNoiseNotVectorizedForPF'}));
            scenarioName = 'S2nlerp';
            filters = struct( ...
                'name', {'sgf', 'hgf', 'pf', 'vmf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51], NaN});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testHypersphericalFiltersS2SymmNlerp(testCase)
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture({...
                'setState:nonGrid', 'FilterEvaluationFramework:genNextStateWithNoiseNotVectorizedForPF',...
                'FilterEvaluationFramework:genNextStateWithoutNoiseNotVectorizedForPF'}));
            scenarioName = 'S2SymmNlerp';
            filters = struct( ...
                'name', {'hgf', 'hhgf', 'hgfSymm', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [6, 10], [31, 51]});
            startEvaluation(scenarioName, filters, 1,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testHypersphericalFiltersS2SymmMixture(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            tempFixture = testCase.getSharedTestFixtures();
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture({...
                'setState:nonGrid', 'FilterEvaluationFramework:genNextStateWithNoiseNotVectorizedForPF',...
                'FilterEvaluationFramework:genNextStateWithoutNoiseNotVectorizedForPF'}));
            scenarioName = 'S2SymmMixture';
            filters = struct( ...
                'name', {'hgf', 'hhgf', 'hgfSymm', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [6, 10], [31, 51]});
            startEvaluation(scenarioName, filters, testCase.noRunsDefault,...
                saveFolder = tempFixture(1).Folder, initialSeed = 1, autoWarningOnOff=false);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
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
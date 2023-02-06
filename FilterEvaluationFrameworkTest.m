classdef (SharedTestFixtures={matlab.unittest.fixtures.TemporaryFolderFixture,...
        ...% Some warnings can happen, e.g., due to the low number of
        ...% coefficients, but these are not related to this framework and
        ...% can be useful as information to users (outside of test
        ...% cases).
        matlab.unittest.fixtures.SuppressedWarningsFixture(...
        {'MATLAB:hg:AutoSoftwareOpenGL', 'PlotResults:FewRuns',...
        'Normalization:notNormalized', 'Normalization:negative',...
        'FilterEvaluationFramework:TWNUniform'})})...
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
                'filterParams', {[7, 9], [7, 9], [31, 51]});
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
                'name', {'kf', 'pf'}, 'filterParams', {NaN, [31, 51]});
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
    end
end
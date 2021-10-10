classdef FilterEvaluationFrameworkTest < matlab.unittest.TestCase
    % @author Florian Pfaff pfaff@kit.edu
    % @date 2016-2021
    % V2.1
    methods (Test)
        function testCircularFilters(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi*0.8);
        end
        function testHypertoroidalFilters(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'T2unimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);

            scenarioName = 'T2bimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);

            scenarioName = 'T2-4twnlooksunimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);

            scenarioName = 'T2IgorsFunctionCustom';
            filters = struct( ...
                'name', {'iff', 'sqff', 'htgf', 'pf', 'twn'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [21, 22], NaN});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1, scenarioCustomizationParams = [1.5, 2]);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], pi);

            scenarioName = 'T3IgorsFunctionCustom';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1, scenarioCustomizationParams = [0.5, 1, 1.5]);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);

            scenarioName = 'T3HighNoise';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);

            scenarioName = 'T3LowNoise';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);

            scenarioName = 'T3LowSysNoiseBimodal';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);

            scenarioName = 'T4';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.2*pi);

            scenarioName = 'T5';
            filters = struct( ...
                'name', {'iff', 'sqff', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 1.5*pi);
        end
        function testHypersphericalFilters(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);
            noRuns = 10;
            scenarioName = 'S2xyzSequentiallyThreeTimes';
            filters = struct( ...
                'name', {'ishf', 'sqshf', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);

            scenarioName = 'S2azAndEleNoiseSphere';
            filters = struct( ...
                'name', {'sgf', 'hgf', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);

            scenarioName = 'S2nlerp';
            filters = struct( ...
                'name', {'sgf', 'hgf', 'pf', 'vmf'}, ...
                'filterParams', {[5, 7], [5, 7], [31, 51], NaN});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testHypersphericalFiltersForSymmetricCases(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'S2SymmNlerp';
            filters = struct( ...
                'name', {'hgf', 'hhgf', 'hgfSymm', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [6, 10], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);

            scenarioName = 'S2SymmMixture';
            filters = struct( ...
                'name', {'hgf', 'hhgf', 'hgfSymm', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [6, 10], [31, 51]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            testCase.verifyLessThan([paramTimeAndErrorPerFilter.meanErrorAllConfigs], 0.8*pi);
        end
        function testSE2filters(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);
            
            noRuns = 10;
            scenarioName = 'se2randomDirectedWalk';
            filters = struct('name', {'se2ukfm', 'pf', 'se2bf', 's3f'}, ...
                'filterParams', {[1e-3, 1e-2, 1e-1, 1], [101, 201], NaN, ...
                [150, 200]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, initialSeed = 1, scenarioCustomizationParams = 50);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            paramTimeAndErrorPerFilter = plotResults();
            isSE2bf = strcmp({paramTimeAndErrorPerFilter.filterName}, 'se2bf');
            testCase.verifyLessThan([paramTimeAndErrorPerFilter(~isSE2bf).meanErrorAllConfigs], 1.5);
        end
        function testRandomFilter(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'dummy'}, ...
                'filterParams', {[5, 7], NaN});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder, convertToPointEstimateDuringRuntime = true);
        end
        function testCombineMats(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder);
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder);

            files = dir(tempFixture.Folder);
            matFiles = files(contains({files.name}, 'S1Igors'));
            matFilesFullPath = cellfun(@(name, folder){fullfile(folder, name)}, {matFiles.name}, {matFiles.folder});
            testCase.verifyWarningFree(@()combineMats(matFilesFullPath));
        end
        function testPlotResultsBoxplot(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 10;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'sqff', 'fig', 'figResetOnPred', 'pf'}, ...
                'filterParams', {[5, 7], [5, 7], [5, 7], [5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, noRuns, saveFolder = tempFixture.Folder);

            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            plotResultsBoxplot();
        end

        function testPlotErrorsForAllTimeSteps(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            noRuns = 2;
            scenarioName = 'S1IgorsFunction';
            filters = struct( ...
                'name', {'iff', 'pf'}, ...
                'filterParams', {[5, 7], [21, 31]});
            startEvaluation(scenarioName, filters, noRuns, plotEachStep = true, saveFolder = tempFixture.Folder, extractAllPointEstimates = true);
        end
        
        function testConvertToPointEstimateDuringRuntime(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);
            
            noRuns = 10;
            scenarioName = 'se2randomDirectedWalk';
            filters = struct('name', {'pf', 'se2bf', 's3f'}, ...
                'filterParams', {[101, 201], NaN, [150, 200]});
            startEvaluation(scenarioName, filters, noRuns, scenarioCustomizationParams=3,...
                saveFolder=tempFixture.Folder, plotEachStep=false, convertToPointEstimateDuringRuntime=true, tolerateFailure=true);
            testCase.applyFixture(SuppressedWarningsFixture('PlotResults:FewRuns'));
            plotResults();
        end
    end
end
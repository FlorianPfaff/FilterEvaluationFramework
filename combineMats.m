function [results, groundtruths, scenarioParam] = combineMats(filenamesOrPath, checkForEqualScenariosThroughly, saveMat)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% V1.0
arguments
    filenamesOrPath {mustBeA(filenamesOrPath, {'char', 'cell'}), mustBeNonempty}
    checkForEqualScenariosThroughly(1, 1) logical = false
    saveMat (1,1) logical = true
end
% Needs to contain date, therefore 20
if iscell(filenamesOrPath) || contains(filenamesOrPath, '20') % Multiple or single file given as name
    files = struct('name', filenamesOrPath);
    multipleScenarios = false;
else % Path is given
    currDir = pwd;
    cd(filenamesOrPath);
    files = dir('*.mat');
    multipleScenarios = true;
end

matInfos = [];
for currFileIndex = 1:length(files)
    if ~isempty(strfind(files(currFileIndex).name, 'combined')) || ~isempty(strfind(files(currFileIndex).name, 'Combined'))
        continue % Do not include files that are already combined versions of original ones
    end
    fnpart = regexp(files(currFileIndex).name, ' ', 'split');
    matInfos = [matInfos, struct('scenario', fnpart{1}, 'filename', files(currFileIndex).name)]; %#ok<AGROW>
end
scenariosInFiles = unique({matInfos.scenario});
if (numel(scenariosInFiles) > 1) && ~multipleScenarios
    error('Only give a cell array of files that are from one scenario');
end
for currScenario = scenariosInFiles
    matsCurrScenario = matInfos(contains({matInfos.scenario}, currScenario));
    load(matsCurrScenario(1).filename, 'scenarioParam', 'hostname', 'groundtruths', 'results', 'measurements')
    allSeedsSoFar = scenarioParam.allSeeds;
    for currMatIndex = 2:length(matsCurrScenario)
        fprintf('loading file %d\n',currMatIndex);
        currMat = load(matsCurrScenario(currMatIndex).filename);
        % Remove artifacts that came up on long term training on a server
        % computer
        assert(strcmp(erase(currMat.hostname,{newline,char(13),'^[OA'}), erase(hostname,{newline,char(13),'^[OA'})),...
            'You should not combine mats from different computers!');
        assert(~currMat.scenarioParam.plot, 'Do not use runs in which plotting was enabled');

        assert(isempty(intersect(currMat.scenarioParam.allSeeds, allSeedsSoFar)), 'Same seed, i.e., identical scenarios were used!');
        allSeedsSoFar = [allSeedsSoFar, currMat.scenarioParam.allSeeds]; %#ok<AGROW>

        assert(all(cellfun(@(x, y)isequal(x, y) || isa(x, 'function_handle'), ...
            struct2cell(rmfield(scenarioParam, 'allSeeds')), ...
            struct2cell(rmfield(currMat.scenarioParam, 'allSeeds')))), 'Do not combine if scenarios don''t match')
        groundtruths = [groundtruths, currMat.groundtruths]; %#ok<AGROW>
        for currConfigIndex = 1:length(results)
            assert(isequal(results(currConfigIndex).filterName, currMat.results(currConfigIndex).filterName));
            assert(isequaln(results(currConfigIndex).filterParams, currMat.results(currConfigIndex).filterParams));

            results(currConfigIndex).timeTaken = [results(currConfigIndex).timeTaken, currMat.results(currConfigIndex).timeTaken];
            if isfield(results, 'lastEstimates')
                results(currConfigIndex).lastEstimates = [results(currConfigIndex).lastEstimates; currMat.results(currConfigIndex).lastEstimates];
            end
            if isfield(results, 'allEstimates')
                results(currConfigIndex).allEstimates = [results(currConfigIndex).allEstimates; currMat.results(currConfigIndex).allEstimates];
            end
            if isfield(results, 'lastFilterStates')
                results(currConfigIndex).lastFilterStates = [results(currConfigIndex).lastFilterStates, currMat.results(currConfigIndex).lastFilterStates];
            end
            if isfield(results, 'measurements')
                results(currConfigIndex).measurements = [results(currConfigIndex).measurements, currMat.results(currConfigIndex).measurements];
            end
        end
    end
    if saveMat
        fprintf('Current scenario: %s\nTotal number of configurations: %d\nTotal number of runs: %d\n', currScenario{1}, numel(results), numel(results(1).timeTaken));
        saveFn = [currScenario{1}, ' combined.mat'];
        if exist(saveFn,'file')
            fprintf('File %s already exists. Press any key to overwrite.', saveFn);
            pause
        end
        save(saveFn, 'results', 'scenarioParam', 'hostname', 'groundtruths', 'measurements');
    end
end
scenarioParam.allSeeds = allSeedsSoFar;
% Check for equal scenarios quickly
assert(numel(unique(scenarioParam.allSeeds)) == numel(scenarioParam.allSeeds));
% Perform a more thorough (but expensive) check
if checkForEqualScenariosThroughly
    for i = 1:size(groundtruths, 2) % Check no scenarios are identical
        for j = setdiff(1:size(groundtruths, 2), i)
            assert(~isequal(groundtruths{i}, groundtruths{j}));
        end
    end
end

if multipleScenarios
    cd(currDir) % Go back to current directory
end
end
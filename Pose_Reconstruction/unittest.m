classdef unittest < matlab.unittest.TestCase
    properties
        ProjectObj
        BaseDir = '/tmp/test_project'
    end
    
    methods (TestMethodSetup)
        function createProject(testCase)
            if exist(testCase.BaseDir, 'dir')
                rmdir(testCase.BaseDir, 's');
            end
            mkdir(testCase.BaseDir);
            testCase.ProjectObj = Project('TestProject', testCase.BaseDir, struct());
        end
    end
    
    methods (TestMethodTeardown)
        function deleteProject(testCase)
            if exist(testCase.BaseDir, 'dir')
                rmdir(testCase.BaseDir, 's');
            end
        end
    end
    
    methods (Test)
        function testProjectCreation(testCase)
            testCase.verifyEqual(testCase.ProjectObj.name, 'TestProject');
            testCase.verifyTrue(isfolder(testCase.ProjectObj.baseDir));
            testCase.verifyTrue(isfolder(testCase.ProjectObj.dataDir));
        end
        
        function testAddProcessedFile(testCase)
            originalFilePath = fullfile(testCase.BaseDir, 'data', 'original.mat');
            processedData = rand(10);
            processingType = 'testType';
            
            % Create a dummy original file
            save(originalFilePath, 'processedData');
            
            processedFilePath = testCase.ProjectObj.addProcessedFile(originalFilePath, processedData, processingType);
            testCase.verifyTrue(isfile(processedFilePath));
            
            % Verify the file registry
            registry = testCase.ProjectObj.fileRegistry;
            testCase.verifyEqual(registry(1).original, originalFilePath);
            testCase.verifyEqual(registry(1).processed.(processingType), processedFilePath);
        end
        
        function testGetProcessedFile(testCase)
            originalFilePath = fullfile(testCase.BaseDir, 'data', 'original.mat');
            processedData = rand(10);
            processingType = 'testType';
            
            % Create a dummy original file
            save(originalFilePath, 'processedData');
            
            % Add processed file
            testCase.ProjectObj.addProcessedFile(originalFilePath, processedData, processingType);
            
            % Retrieve processed file
            retrievedFilePath = testCase.ProjectObj.getProcessedFile(originalFilePath, processingType);
            testCase.verifyEqual(retrievedFilePath, fullfile(testCase.BaseDir, 'data', 'original_testType.mat'));
        end
        
        
        function testDisplayProjectSummary(testCase)
            testCase.verifyWarningFree(@() testCase.ProjectObj.displayProjectSummary());
        end
    end
end
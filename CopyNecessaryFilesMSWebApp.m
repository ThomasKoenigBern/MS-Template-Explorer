mfilePath = fileparts(which('MSTemplateExplorer.mlapp'));


FilesINeed = matlab.codetools.requiredFilesAndProducts('MSTemplateExplorer.mlapp')';
FilesINeed = [FilesINeed;matlab.codetools.requiredFilesAndProducts('MSTemplateEditor.mlapp')'];

FilesINeed = unique(FilesINeed);

FilesINeed(contains(FilesINeed,'MSWebApp')) = [];
FilesINeed(contains(FilesINeed,'userpath.m')) = [];

for i = 1:numel(FilesINeed)
    [FilePath,FileName,Ext] = fileparts(FilesINeed{i});
    Dest = fullfile(mfilePath,[FileName Ext]);
    copyfile(FilesINeed{i},Dest);
end
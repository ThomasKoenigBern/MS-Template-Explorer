indir = '/Users/thomaskoenig/Dropbox (PUK-TRC)/Documents/MATLAB/MSWebApp/Templates/Maps 2023-04-l19';

d = dir(fullfile(indir,'Custo*.set'));
outdir = fullfile(indir,'fixed');
mkdir(outdir);

for i = 1:numel(d)
    
    load(fullfile(d(i).folder,d(i).name),'-mat');
    [~,fn] = fileparts(d(i).name);
    EEG.setname = fn;
    
    nClasses = EEG.msinfo.ClustPar.MaxClasses;
    clc
    disp('-----------------------');
    fprintf(1,'%s: %s, %s\n',fn,EEG.msinfo.Citation.Authors,EEG.msinfo.Citation.Year);
    
    CurrentLabels = EEG.msinfo.MSMaps(nClasses).Labels;
    disp(CurrentLabels);

    answer = questdlg('Fix label names?');

    if strcmp(answer,'Cancel')
        break;
    end

    if strcmp(answer,'Yes')
        answer = inputdlg({'Old part','New part'},'Fix things',1,{CurrentLabels{1},fn});
        if ~isempty(answer)
            for l = 1:numel(CurrentLabels)
                CurrentLabels{l} = strrep(CurrentLabels{l},answer{1},answer{2});
            end
            EEG.msinfo.MSMaps(nClasses).Labels = CurrentLabels;
        end
    end

    save(fullfile(outdir,d(i).name),'EEG','-mat');

    
end
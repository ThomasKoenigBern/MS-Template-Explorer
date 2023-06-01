function C = CompareTemplateMaps(eeg1,eeg2,nTemplates1, nTemplates2)


if nargin < 3
    if eeg1.msinfo.ClustPar.MinClasses ~= eeg1.msinfo.ClustPar.MaxClasses
        eeg1.setname
        error('Dataset can only contain one microstate solution');
    else
        nTemplates1 = eeg1.msinfo.ClustPar.MinClasses;
    end
else
    if nTemplates1 < eeg1.msinfo.ClustPar.MinClasses || nTemplates1 > eeg1.msinfo.ClustPar.MaxClasses
        error('Dataset 1 does not contain the requested microstate solution');
    end
end

if nargout > 0 && nargin < 2
    C = corr(eeg1.msinfo.MSMaps(nTemplates1).Maps');
    return
end

if nargin < 4
    if eeg2.msinfo.ClustPar.MinClasses ~= eeg2.msinfo.ClustPar.MaxClasses
        error('Dataset can only contain one microstate solution');
    else
        nTemplates2 = eeg2.msinfo.ClustPar.MinClasses;
    end
else
    if nTemplates2 < eeg2.msinfo.ClustPar.MinClasses || nTemplates2 > eeg2.msinfo.ClustPar.MaxClasses
        error('Dataset 2 does not contain the requested microstate solution');
    end
end

nChannels1 = size(eeg1.msinfo.MSMaps(nTemplates1).Maps,2);
nChannels2 = size(eeg2.msinfo.MSMaps(nTemplates2).Maps,2);


if isequal(eeg1.chanlocs,eeg2.chanlocs)
    Maps1 = eeg1.msinfo.MSMaps(nTemplates1).Maps;
    Maps2 = eeg2.msinfo.MSMaps(nTemplates2).Maps;
else
    if nChannels1 > nChannels2
        
        ResamplingMat = MakeResampleMatrices(eeg1.chanlocs,eeg2.chanlocs);
        Maps1 = eeg1.msinfo.MSMaps(nTemplates1).Maps * ResamplingMat';
        Maps2 = eeg2.msinfo.MSMaps(nTemplates2).Maps;
    else
        ResamplingMat = MakeResampleMatrices(eeg2.chanlocs,eeg1.chanlocs);
        Maps1 = eeg1.msinfo.MSMaps(nTemplates1).Maps;
        Maps2 = eeg2.msinfo.MSMaps(nTemplates2).Maps * ResamplingMat';
    end
end

C = corr(double(Maps1)',double(Maps2)');


if nargout < 1
    clf
    for i = 1:nTemplates1
        subplot(nTemplates1+1,nTemplates2+1,i * (nTemplates2+1)+1);
        mx = max(abs(eeg1.msinfo.MSMaps(nTemplates1).Maps(:)));
        dspCMap(double(eeg1.msinfo.MSMaps(nTemplates1).Maps(i,:)),eeg1.chanlocs,'Step',mx/8);
    end
    
    for j = 1:nTemplates2
        subplot(nTemplates1+1,nTemplates2+1,j + 1);
        mx = max(abs(eeg2.msinfo.MSMaps(nTemplates2).Maps(:)));
        dspCMap(double(eeg2.msinfo.MSMaps(nTemplates2).Maps(j,:)),eeg2.chanlocs,'Step',mx/8);
    end

    
    
    
    for i = 1:nTemplates1
        for j = 1:nTemplates2
            h = subplot(nTemplates1+1,nTemplates2+1,j + 1 + (nTemplates2+1) * i);
            text(0.5,0.5,sprintf('%3.3f',C(i,j)),'HorizontalAlignment','center');
            h.XLim = [0 1];
            h.YLim = [0 1];
            axis(h,'off');
        end
    end
end

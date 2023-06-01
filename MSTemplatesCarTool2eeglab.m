function [EEG,OutFileName] = MSTemplatesCarTool2eeglab(varargin)


p = inputParser;
addOptional(p,'FileName',[]);
addOptional(p,'XYZFile',[]);
addOptional(p,'LabelFile',[]);
addOptional(p,'OutputFile',[]);
addOptional(p,'Comment',[]);

parse(p,varargin{:});

EEG = [];
OutFileName = [];

if isempty(p.Results.FileName)
    [FileName,PathName] = uigetfile({"*.ep","Select EP file";"*.txt","Select text file"});
    if FileName == 0
        return
    end

    EPFile = fullfile(PathName,FileName);
else
    EPFile = p.Results.FileName;
end

if ~isempty(p.Results.XYZFile)
    [Montage,xyz,Labels] = ReadSXYZ(p.Results.XYZFile);
    if isempty(Montage)
        error('Cannot read file %s',p.Results.XYZFile);
    end
elseif ~isempty(p.Results.LabelFile)
    Labels = readlines(p.Results.LabelFile);
    Montage = GetChannelPositionsFromLabels(Labels);
    [x,y,z] = VAsph2cart(Montage);
    xyz = [x;y;z]';
else
    [FileName,PathName,FilterIndex] = uigetfile({"*.xyz","Select XYZ file";"*.txt","Select text file with labels"});

    switch(FilterIndex)
        case 0
            return;

        case 1
            [Montage,xyz,Labels] = ReadSXYZ(fullfile(PathName,FileName));
            if isempty(Montage)
                error('Cannot read file %s',p.Results.XYZFile);
            end

        case 2
            Labels = readlines(fullfile(PathName,FileName));
            Montage = GetChannelPositionsFromLabels(Labels);
            [x,y,z] = VAsph2cart(Montage);
            xyz = [x;y;z]';
    end
end


MSMaps = load(EPFile);
[nMaps,nChannels] = size(MSMaps);

aref = eye(nChannels) - 1/nChannels;
MSMaps = MSMaps * aref;

% Convert the XYZ to a sfp file

nChannels = size(xyz,1);

EEG = eeg_emptyset();
EEG.nbchan = size(MSMaps,2);
EEG.trials = 1;
EEG.pnts   = size(MSMaps,1);
EEG.srate  = 1000;
EEG.xmin   = 0;
EEG.xmax   = (size(MSMaps,1) - 1)  / 1000;
EEG.times  = 0 : (size(MSMaps,1) - 1);
EEG.data   = single(MSMaps');

if ~isempty(p.Results.Comment)
    EEG.comments = p.Results.Comment;
end

for i = 1:nChannels
    x = -xyz(i,1);
    y =  xyz(i,2);
    z =  xyz(i,3);
    EEG.chanlocs(i).Y = x;
    EEG.chanlocs(i).X = y;
    EEG.chanlocs(i).Z = z;
    EEG.chanlocs(i).labels = Labels(i);
    [th,phi,radius] = cart2sph(x,y,z);
    EEG.chanlocs(i).sph_theta      = th/pi*180;
	EEG.chanlocs(i).sph_phi        = phi/pi*180;
	EEG.chanlocs(i).sph_radius     = radius;
    EEG.chanlocs(i).theta          = -EEG.chanlocs(i).sph_theta;
    EEG.chanlocs(i).radius         = 0.5 - EEG.chanlocs(i).sph_phi/180;
    EEG.chanlocs(i).sph_theta_besa = 0;
    EEG.chanlocs(i).sph_phi_besa   = 0;
    EEG.chanlocs(i).type = [];
end


EEG.chaninfo = struct('icachansind',[],...
                       'plotrad',[],...
                       'shrink',[],...
                       'nosedir','+X',...
                       'nodatchans',[]);

EEG.ref = 'common';
EEG.msinfo.MSMaps(nMaps).Maps = MSMaps;
EEG.msinfo.MSMaps(nMaps).ExpVar = nan;
EEG.msinfo.MSMaps(nMaps).ColorMap = lines(nMaps);
EEG.msinfo.MSMaps(nMaps).SortMode = 'none';
EEG.msinfo.MSMaps(nMaps).SortedBy = '';
EEG.msinfo.MSMaps(nMaps).SpatialCorrelation = [];
EEG.msinfo.MSMaps(nMaps).Parents = [];
if nargin > 4
    EEG.msinfo.MSMaps(nMaps).Labels = Labels;
else
    for i = 1:nMaps
        EEG.msinfo.MSMaps(nMaps).Labels(i) = {sprintf('Class_%i',i)};
    end
end
EEG.msinfo.ClustPar = struct('MinClasses',nMaps,...
                             'MaxClasses',nMaps,...
                             'GFPPeaks',1,...
                             'IgnorePolarity', 1, ...
                             'MaxMaps', NaN, ...
                             'Restarts', 5, ...
                             'UseAAHC', 0, ...
                             'Normalize', 1);

OutFileName = EPFile;

if nargout < 1
    [outpath,outname,ext] = fileparts(OutFile);
    pop_saveset(EEG,'filename',[outname,ext],'filepath',outpath);
end


function EEG = eeg_emptyset()

EEG.setname     = '';
EEG.filename    = '';
EEG.filepath    = '';
EEG.subject     = '';
EEG.group       = '';
EEG.condition   = '';
EEG.session     = [];
EEG.comments    = '';
EEG.nbchan      = 0;
EEG.trials      = 0;
EEG.pnts        = 0;
EEG.srate       = 1;
EEG.xmin        = 0;
EEG.xmax        = 0;
EEG.times       = [];
EEG.data        = [];
EEG.icaact      = [];
EEG.icawinv     = [];
EEG.icasphere   = [];
EEG.icaweights  = [];
EEG.icachansind = [];
EEG.chanlocs    = [];
EEG.urchanlocs  = [];
EEG.chaninfo    = [];
EEG.ref         = [];
EEG.event       = [];
EEG.urevent     = [];
EEG.eventdescription = {};
EEG.epoch       = [];
EEG.epochdescription = {};
EEG.reject      = [];
EEG.stats       = [];
EEG.specdata    = [];
EEG.specicaact  = [];
EEG.splinefile  = '';
EEG.icasplinefile = '';
EEG.dipfit      = [];
EEG.history     = '';
EEG.saved       = 'no';
EEG.etc         = [];

%EEG.reject.threshold  = [1 0.8 0.85];
%EEG.reject.icareject  = [];
%EEG.reject.compreject = [];
%EEG.reject.gcompreject= [];
%EEG.reject.comptrial  = [];
%EEG.reject.sigreject  = [];
%EEG.reject.elecreject = [];

%EEG.stats.kurta      = [];
%EEG.stats.kurtr      = [];
%EEG.stats.kurtd      = [];		
%EEG.stats.eegentropy = [];
%EEG.stats.eegkurt    = [];
%EEG.stats.eegkurtg   = [];
%EEG.stats.entropy    = [];
%EEG.stats.kurtc      = [];
%EEG.stats.kurtt      = [];
%EEG.stats.entropyc   = [];

return;

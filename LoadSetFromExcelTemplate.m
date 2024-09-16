function EEG = LoadSetFromExcelTemplate(InFile)
    if nargin < 1
        [fn,pn] = uigetfile('*.xlsx', 'Pick an Excel file');
        if fn == 0
            return
        end
        InFile = fullfile(pn,fn);
    end

    % Read the template maps
    
    TemplateMapTable = readcell(InFile,"Sheet","Template Maps");
    TemplateMaps    = cell2mat(TemplateMapTable(2:end,2:end));
    TemplateNames   = TemplateMapTable(2:end,1);
    ElectrodeNames = TemplateMapTable(1,2:end);

    for i = 1:numel(ElectrodeNames)
        if isnumeric(ElectrodeNames{i})
            ElectrodeNames{i} = sprintf('%i',ElectrodeNames{i});
        end
    end

    % Read the electrode positions
    opts = spreadsheetImportOptions("NumVariables", 4);
    opts.VariableTypes = ["string", "double", "double", "double"];
    opts.VariableNames = ["labels", "X", "Y", "Z"];
    opts.DataRange = 'A2';
    ElectrodeTable = readtable(InFile,opts,"Sheet","Electrode Coordinates");

    if size(ElectrodeTable,1) ~= numel(ElectrodeNames)
        error('Channel number inconsistent');
    end

    if ~all(cellfun(@strcmp,ElectrodeNames',ElectrodeTable.labels))
        error('Channel ordering inconsistent');
    end

    Coords.pos = table2array(ElectrodeTable(:,2:4));
    
    if any(isnan(Coords.pos(:)))
        warning('Defaulting channel positions');
        ChannelPositions = GetChannelPositionsFromLabels(ElectrodeTable.labels);
        res = VAsph2cartStruct(ChannelPositions);
        Coords.pos = res.Coords';
    end
    
    Coords.lbl = ElectrodeNames;

    h = SetXYZCoordinates([],[],[],Coords);

    if isempty(h)
        EEG = [];
        return;
    end

    Coords = get(h,'UserData');

    close(h);

    x = Coords.x;
    y = Coords.y;
    z = Coords.z;

    EEG      = EmptySet(TemplateMaps,[x y z],ElectrodeNames);

    nTemplates = size(TemplateMaps,1);

    EEG.msinfo.MSMaps(nTemplates) = struct('Maps'               ,TemplateMaps, ...
                                           'ExpVar'             , nan, ...
                                           'ColorMap'           , lines(nTemplates), ...
                                           'SortMode'           , 'none',...
                                           'SortedBy'            , '', ...
                                           'SpatialCorrelations',[], ...
                                           'Parents'            ,[]);
    EEG.msinfo.MSMaps(nTemplates).Labels = TemplateNames';
    
    % Read the findings
    FindingsTable = readtable(InFile,"Sheet","Findings");

    NamesToSearch = [TemplateNames;{'Class independent effect'}];

    for i = 1:numel(NamesToSearch)
        idx = find(strcmp(FindingsTable.MicrostateClass,NamesToSearch{i}));
        if ~isempty(idx)
            EEG.msinfo.MSMaps(nTemplates).Findings{i} = table2cell(FindingsTable(idx,2:5));
        else
            EEG.msinfo.MSMaps(nTemplates).Findings{i} = [];
        end
    end
    
    MetaDataTable   = readtable(InFile,"Sheet","MetaData");
    DomainDataTable = readtable(InFile,"Sheet","Research Domain");
    Keywords        = readtable(InFile,"Sheet","Keywords");


    CitationFields = {'Authors','Title','Journal','Year','Pages','DOI','EMail'};
    MetaDataFields =  {'AlgorithmUsed','BackFittingDataSelection','SoftwareUsed','ModelSelection','BandPassFilter','EyeState','nSubjects','MeanTime'};
    DomainFields =  {'Cognition and Emotion','Neurological disorders','Psychiatric disorders','Consciousness and its disorders','Development','Drugs and brain stimulation'};

    for i = 1:numel(CitationFields)
        EEG.msinfo.Citation.(CitationFields{i}) = GetValuefromField(MetaDataTable,CitationFields{i});
    end

    for i = 1:numel(MetaDataFields)
        EEG.msinfo.MetaData.(MetaDataFields{i}) = GetValuefromField(MetaDataTable,MetaDataFields{i});
    end

    for i = 1:numel(DomainFields)
        FieldName = DomainFields{i};
        FieldName(isspace(FieldName)) = [];
        EEG.msinfo.Citation.(FieldName) = GetBooleanfromField(DomainDataTable,DomainFields{i});
    end

    EEG.msinfo.Citation.FreeKeyWords = '';
    for i = 1:numel(Keywords)
        if i == 1
            EEG.msinfo.Citation.FreeKeyWords = [EEG.msinfo.Citation.FreeKeyWords, Keywords.Keywords{i,1}]; 
        else
            EEG.msinfo.Citation.FreeKeyWords = [EEG.msinfo.Citation.FreeKeyWords, ', ' Keywords.Keywords{i,1}];
        end
    end

    
    EEG.msinfo.MetaData.DataSelection = GetValuefromField(MetaDataTable,'ClusterDataSelection');
    EEG.msinfo.MetaData.nSubjects  = str2double(EEG.msinfo.MetaData.nSubjects);
    EEG.msinfo.MetaData.MeanTime   = str2double(EEG.msinfo.MetaData.MeanTime);
    EEG.msinfo.ClustPar.MinClasses = EEG.pnts;
    EEG.msinfo.ClustPar.MaxClasses = EEG.pnts;
end

function value = GetBooleanfromField(Data,FieldName)
    idx = find(strcmpi(Data.Domain,FieldName));
    if isempty(idx)
        value = '';
    else
        if strcmpi(Data.Applicable{idx},'Yes')
            value = true;
        elseif strcmpi(Data.Applicable{idx},'No')
            value = false;
        else    
            value = nan;
        end
    end
end



function value = GetValuefromField(Data,FieldName)
    idx = find(strcmpi(Data.Field,FieldName));
    if isempty(idx)
        value = '';
    else
        value = Data.Value {idx};
    end
end
    



function EEG = EmptySet(data, xyz,Labels)
    EEG.setname     = '';
    EEG.filename    = '';
    EEG.filepath    = '';
    EEG.subject     = '';
    EEG.group       = '';
    EEG.condition   = '';
    EEG.session     = [];
    EEG.comments    = '';
    EEG.nbchan      = size(data,2);
    EEG.trials      = 1;
    EEG.pnts        = size(data,1);
    EEG.srate       = 1;
    EEG.xmin        = 0;
    EEG.xmax        = EEG.pnts -1;
    EEG.times       = EEG.xmin : EEG.xmax;
    EEG.data        = data';
    EEG.icaact      = [];
    EEG.icawinv     = [];
    EEG.icasphere   = [];
    EEG.icaweights  = [];
    EEG.icachansind = [];
    for i = 1:size(xyz,1)
        x = -xyz(i,1);
        y =  xyz(i,2);
        z =  xyz(i,3);
        EEG.chanlocs(i).Y = x;
        EEG.chanlocs(i).X = y;
        EEG.chanlocs(i).Z = z;
        EEG.chanlocs(i).labels = Labels{i};
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
end
        
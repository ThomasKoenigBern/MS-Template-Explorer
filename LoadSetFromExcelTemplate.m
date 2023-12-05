function EEG = LoadSetFromExcelTemplate(InFile)
    if nargin < 1
        [fn,pn] = uigetfile('*.xlsx', 'Pick an Excel file');
        if fn == 0
            return
        end
        InFile = fullfile(pn,fn);
    end

    % Read the template maps
    TemplateMapTable = readtable(InFile,"Sheet","Template Maps");
    TemplateMaps    = table2array(TemplateMapTable(:,2:end));
    TemplateNames  = table2cell(TemplateMapTable(:,1));
    ElectrodeNames = TemplateMapTable.Properties.VariableNames(1,2:end)';

    % Read the electrode positions
    ElectrodeTable = readtable(InFile,"Sheet","Electrode Coordinates");

    if size(ElectrodeTable,1) ~= numel(ElectrodeNames)
        error('Channel number inconsistent');
    end

    if ~all(cellfun(@strcmp,ElectrodeNames,ElectrodeTable.labels))
        error('Channel ordering inconsistent');
    end

    EEG      = EmptySet(TemplateMaps,table2array(ElectrodeTable(:,2:4)),ElectrodeNames);

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
            EEG.msinfo.MSMaps(nTemplates).Findings{i} = table2cell(FindingsTable(idx,2:end));
        else
            EEG.msinfo.MSMaps(nTemplates).Findings{i} = [];
        end
    end
    
    MetaDataTable = readtable(InFile,"Sheet","MetaData");

    CitationFields = {'Authors','Title','Journal','Year','Pages','DOI','EMail','Editor'};
    MetaDataFields =  {'AlgorithmUsed','DataSelection','SoftwareUsed','ModelSelection','BandPassFilter','EyeState','nSubjects','MeanTime'};

    for i = 1:numel(CitationFields)
        EEG.msinfo.Citation.(CitationFields{i}) = GetValuefromField(MetaDataTable,CitationFields{i});
    end

    for i = 1:numel(MetaDataFields)
        EEG.msinfo.MetaData.(MetaDataFields{i}) = GetValuefromField(MetaDataTable,MetaDataFields{i});
    end


end

function value = GetValuefromField(Data,FieldName)
    idx = find(strcmp(Data.Field,FieldName));
    if isempty(idx)
        error(['Field ' FieldName ' not found in the table']);
    end
    value = Data.Value {idx};
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
        
Clean

d = dir('Template Maps/*.set');

fnames = {d.name};

for i = 1:67
    MSTemplateEditor(fullfile('Template Maps/',fnames{i}));
end
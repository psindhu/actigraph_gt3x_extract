addpath('jsonlab')

basedir = '/home/sdka/phd/data/goactiwe/ActiGraph/';
file_list = getAllFiles(basedir);

for i=1:length(file_list)
    file = file_list{i};
    [pathstr,name,ext] = fileparts(file);
        
    if strcmp(ext, '.gt3x')
        disp(file)
        [info, data] = ExtractGT3x(file);
    
        csvwrite(fullfile(pathstr, strcat(name, '.csv')), data);
        savejson('', info, fullfile(pathstr, strcat(name, '.json')));
    end
    
end
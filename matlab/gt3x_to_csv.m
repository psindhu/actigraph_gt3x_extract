addpath('jsonlab')

basedir = '';
file_list = getAllFiles(basedir);

for i=1:length(file_list)
    file = file_list{i};
    [pathstr,name,ext] = fileparts(file);
    [~,sub_name,~] = fileparts(pathstr);
    
    if strcmp(ext, '.gt3x')
        disp(file)
        if exist(fullfile(pathstr, strcat(name, '.csv')), 'file')
            disp('Already extracted')
        else
            try
                [info, data, timestamp] = ExtractGT3x(file);
                csvwrite(fullfile(pathstr, strcat(name, '.csv')), data);
                csvwrite(fullfile(pathstr, strcat(name, '_timestamp.csv')), timestamp)
                savejson('', info, fullfile(pathstr, strcat(name, '.json')));
            catch
                disp('Errored')
            end
        end
    end
end

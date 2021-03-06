function [info, data, timestamp] = ExtractGT3x(fullFilename)
% Extract raw data from ActiGraph GT3x
%   Expects version 3.2.1

    if(exist(fullFilename,'file'))
        [pathName, baseName, ext] = fileparts(fullFilename);
        tmpDir = fullfile(pathName, baseName);

        if(exist(tmpDir,'dir'))
            SUCCESS =  true;
        else
            [SUCCESS,MESSAGE,~] = mkdir(tmpDir);
        end

        if(~SUCCESS)
            fprintf('Unable to make a temporary folder (%s) to extract the file %s.%s\n.  The following error was generated by the O/S:\t%s\n',tmpDir, baseName, ext,MESSAGE);
        else
            if(exist(fullfile(tmpDir, 'log.bin'), 'file'))
                % unzip(fullFilename, tmpDir);
                info = ExtractInfo(fullfile(tmpDir, 'info.txt'));
                [data, timestamp] = ExtractBin(fullfile(tmpDir, 'log.bin'));
            end
        end
    end
end

function [infoStruct] = ExtractInfo( infoTxtFullFilename )
    fid = fopen(infoTxtFullFilename,'r');
    pat = '(?<field>[^:]+):\s+(?<values>[^\r\n]+)\s*';
    fileText = fscanf(fid,'%c');
    result = regexp(fileText,pat,'names');
    infoStruct = [];
    for f=1:numel(result)
        fieldName = strrep(result(f).field,' ','_');
        infoStruct.(fieldName)=result(f).values;
    end
    if(isfield(infoStruct,'Firmware'))
        firmware = infoStruct.Firmware;
    else
        firmware = '';
    end
    fclose(fid);
end

function [ axesFloatData, timeStamp ] = ExtractBin( fullRawActivityBinFilename )
    if(exist(fullRawActivityBinFilename,'file'))
        recordCount = 0;
        fid = fopen(fullRawActivityBinFilename,'r','b');
        if(fid>0)
            encodingEPS = 1/341;
            precision = 'ubit12=>double';
            try
                tic
                axesPerRecord = 3;
                checksumSizeBytes = 1;
                triaxialAccelCode = 0;
                bitsPerByte = 8;
                bitsPerAccelRecord = 36;  %size in number of bits (12 bits per acceleration axis)
                recordsPerByte = bitsPerByte/bitsPerAccelRecord;
                timeStampSizeBytes = 4;
                while(~feof(fid))
                    sep = fread(fid,1,'char', 'l');
                    packetCode = fread(fid,1,'char','l');
                    timestamp = fread(fid,1,'ulong', 'l');
                    packetSizeBytes = fread(fid,1,'ushort', 'l');
                    if(~feof(fid))
                        % packetSizeBytes = [1 256]*packetSizeBytes;
                        if(packetCode == triaxialAccelCode)
                            packetRecordCount = packetSizeBytes*recordsPerByte;
                            if(packetRecordCount>1)
                                recordCount = recordCount+packetRecordCount;
                            else
                                fprintf('Record count <=1 at file position %u\n',ftell(fid));
                            end
                        end
                        if(packetSizeBytes~=0)
                            fseek(fid,packetSizeBytes+checksumSizeBytes,0);
                        else
                            fprintf('Packet size is 0 bytes at file position %u\n',ftell(fid));
                        end
                    end
                end

                frewind(fid);
                curRecord = 1;
                axesUBitData = zeros(recordCount,axesPerRecord);
                timeStamp = zeros(recordCount,1);
                while(~feof(fid) && curRecord<=recordCount)
                    sep = fread(fid,1,'char', 'l');
                    packetCode = fread(fid,1,'char','l');
                    timestamp = fread(fid,1,'ulong', 'l');
                    % packetSizeBytes = fread(fid,1,'ushort', 'l');
                    packetSizeBytes = [1 256]*fread(fid,2,'uint8');

                    if(packetCode==triaxialAccelCode)
                        timeStamp(curRecord) = timestamp;

                        packetRecordCount = packetSizeBytes*recordsPerByte;

                        axesUBitData(curRecord:curRecord+packetRecordCount-1,:) = fread(fid,[axesPerRecord,packetRecordCount],precision)';
                        curRecord = curRecord+packetRecordCount;
                        checkSum = fread(fid,checksumSizeBytes,'uint8');
                    else
                        if(~feof(fid))
                            fseek(fid,packetSizeBytes+checksumSizeBytes,0);
                        end
                    end
                end

                curRecord = curRecord -1;  %adjust for the 1 base offset matlab uses.
                if(recordCount~=curRecord)
                    fprintf(1,'There is a mismatch between the number of records expected and the number of records found.\n\tPlease check your data for corruption.\n');
                end

                axesFloatData = (-bitand(axesUBitData,2048)+bitand(axesUBitData,2047))*encodingEPS;

                toc;
                fclose(fid);
                fprintf('Skipping resample count data step\n');

            catch
                fclose(fid);
            end
        else
            fprintf('Warning - could not open %s for reading!\n',fullRawActivityBinFilename);
        end
    else
        fprintf('Warning - %s does not exist!\n',fullRawActivityBinFilename);
    end
end

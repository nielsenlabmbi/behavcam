function camPldapsCb(obj, event)

global cam UDPport fileInfo trialCounter meta;

try
    n = get(UDPport,'BytesAvailable');
     
    if n > 0
        inString = fread(UDPport,n);
        inString = char(inString');
    else
        return
    end
    
    inString = inString(1:end-1);  %Get rid of the terminator
    msg=strsplit(inString,';');
    disp(['received: ' msg{1}])
    
    switch msg{1}
        
        case 'P' %preview
            camPreview;
            
        case 'F' %filename
            fileInfo.filename=msg{2};
            camFile;
           
        case 'G' %get camera ready for acquisition (starts with hardware trigger)
            disp(['Trial ' num2str(trialCounter) ' start (waiting for trigger)']);
            start(cam);
        
        case 'S' %stop camera
            disp('Acquisition stopped');
            stop(cam);
            camSaveData;
          
        case 'E' %close files, clean up
            disp('Protocol end.  Closing files and camera.');
            %save metadata
            fname=fullfile(fileInfo.pathname,[fileInfo.filename '_meta.mat']);
            save(fname, 'meta');
            
            %close movie file
            close(fileInfo.writerObj);

            %close and clean up
            camClose;
        
            
    end
 
    if ~strcmp(msg{1},'G')
        fwrite(UDPport,'a~');
    end
   
catch ME
    disp(ME.message);
    
end
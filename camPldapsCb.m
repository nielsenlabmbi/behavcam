function camPldapsCb(obj, event)

global cam UDPport fileInfo;

try
    n = get(UDPport,'BytesAvailable');
     
    if n > 0
        inString = fread(UDPport,n);
        inString = char(inString');
    else
        return
    end
    
    inString = inString(1:end-1)  %Get rid of the terminator
    msg=strsplit(inString,';');
    
    switch msg{1}
        
        case 'P' %preview
            camPreview(cam);
            
        case 'F' %filename
            fileInfo.filename=msg{2};
            camFile;
            
            
    end
 
    fwrite(UDPport,'a~')
   
catch
    disp(lasterror);
    
end
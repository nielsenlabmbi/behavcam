% 
function camUdpBytesAvailable(obj, event)

global message cam;

message = char(fread(obj)');
message=message(1:end-1)

if(strcmp(message, 'stop'))
    stop(cam);
end

% fprintf(['<' message '>\n']);
 
return;
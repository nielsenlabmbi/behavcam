% 
function camUdpBytesAvailable(obj, event)

global message cam;

message = char(fread(obj)');

if(strcmp(message, 'stop'))
    stop(cam);
end

% fprintf(['<' message '>\n']);
 
return;
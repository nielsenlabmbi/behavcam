%% Recording program for the Genie Nano C1920 GigE camera
%
global cam UDPport trialCounter meta fileInfo;

% create & initialize camera
cam = videoinput('gige', 1);
src = getselectedsource(cam);
stop(cam);

% set camera trigger 
framesPerTrigger = 15000; % We're counting on a software stop
cam.FrameGrabInterval = 2;          % save every other frame
cam.FramesPerTrigger = framesPerTrigger / cam.FrameGrabInterval;
src.TriggerSelector = 'FrameBurstStart';
triggerconfig(cam,'hardware','DeviceSpecific','DeviceSpecific');
set(cam, 'TriggerFcn', @camTriggerOccurred);

% make sure Jumbo Frames are set to 9k in the GigE NIC adapter settings
src.PacketSize = 9000;

%set details of movie acquisition
fileInfo.Fps = 15;  % Hz
fileInfo.resizeScale = 0.25;  % 0.5;    reduce frame size
fileInfo.pathname = 'C:\movie\';

%trial counter and meta information of movie data
meta = {};
trialCounter = 1;

disp('Camera initialized');

%% UDP connection to PLDAPS machine
masterIP='172.30.11.122';
port=instrfindall('RemoteHost',masterIP); 
if ~isempty(port) 
    fclose(port); 
    delete(port);
    clear port;
end

UDPport = udp(masterIP,'RemotePort',9000,'LocalPort',8000);

set(UDPport, 'InputBufferSize', 1024)
set(UDPport, 'OutputBufferSize', 1024)

set(UDPport, 'Datagramterminatemode', 'off')

%Establish serial port event callback criterion
UDPport.BytesAvailableFcnMode = 'Terminator';
UDPport.Terminator = '~'; %Magic number to identify request from Stimulus ('c' as a string)

    
fopen(UDPport);
stat=get(UDPport, 'Status');

if ~strcmp(stat, 'open')
    disp([' Trouble opening connection to camera computer; cannot proceed']);
    UDPport.udpHandle=[];
    return;
end

UDPport.bytesavailablefcn = @camPldapsCb;

disp('UDP initialized');







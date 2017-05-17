%% Recording program for the Genie Nano C1920 GigE camera
%
global message cam;

%
% create & initialize camera
cam = videoinput('gige', 1);
src = getselectedsource(cam);
stop(cam);

framesPerTrigger = 15000; % We're counting on a software stop
imageWidth = 1936;
imageHeight = 1216;

cam.FrameGrabInterval = 2;          % save every other frame
cam.FramesPerTrigger = framesPerTrigger / cam.FrameGrabInterval;
src.TriggerSelector = 'FrameBurstStart';
triggerconfig(cam,'hardware','DeviceSpecific','DeviceSpecific');

% set the function called when a trigger is detected - all it does is print
% "trigger detected"
set(cam, 'TriggerFcn', @camTriggerOccurred);

% make sure Jumbo Frames are set to 9k in the GigE NIC adapter settings
src.PacketSize = 9000;

TimeoutDur = 300;  % seconds to wait for the hardware trigger timeout in wait()
Fps = 15;  % Hz

resizeScale = 0.25;  % 0.5;    reduce frame size

pathname = 'C:\movie\';
filename = '';
meta = {};
trialCounter = 1;
sleepDur = 0.1;
state = 1;
shouldMarkTrialEnd = true;
saveRawFrameData = false;  % Don't use this ... it's *very* slow and incomplete


%% create local messenger
masterIP='172.30.11.XXX';
port=instrfindall('RemoteHost',masterIP); 
if ~isempty(port) 
    fclose(port); 
    delete(port);
    clear port;
end

msg = udp(masterIP,'RemotePort',9000,'LocalPort',8000);
msg.BytesAvailableFcnMode = 'terminator';
msg.Terminator = '~'; 


% the callback function sets message content and, for speed, will stop(cam) if message
% == stop
msg.DatagramReceivedFcn = @camUdpBytesAvailable;
msg.ReadAsyncMode = 'continuous';
fopen(msg);


%%  The main loop
shouldContinue = true;
fprintf('\n\nRunning \n');

% poll and process incoming messages
while(shouldContinue)
    pause(sleepDur);
    
    switch message
        
        case 'start'
            if(state == 3)
                state = 4;
                fprintf('Trial %d begin (waiting for trigger ...)\n', trialCounter);
                
                while(~strcmp(message, 'stop'))
                    % start() takes up to 1.8 seconds and needs to complete
                    % before the hardware trigger occurs.
                    tic;
                    start(cam);
                    epochs(trialCounter, 1) = toc;
                    % wait until framesPerTrigger frames are acquired
                    % or, stop(cam) is called in jkBytesAvailable
                    try
                        wait(cam, TimeoutDur, 'running');
                        epochs(trialCounter, 2) = toc;
                        fprintf('\tAcquisition stopped - transferring data\n');
                    catch ME
                        fprintf('\n\n*** %s ***\n\n', ME.message);
                    end
                    
                    % get the frames and metadata,
                    try
                        % should check first with if(cam.FramesAvailable > 0)
                        [dt, ~, meta{trialCounter}.metadata] = getdata(cam, cam.FramesAvailable);
                        
                        % this is *very* slow and incomplete ... don't use
                        if(saveRawFrameData)
                            if(shouldMarkTrialEnd)
                                dt(:, :, 1, end) = trialCounter;
                            end
                            
                            save([pathname filename], 'dt', '-append');
                            toc
                            meta{trialCounter}.prop = size(dt);
                        else
                            dt2 = imresize(dt, resizeScale, 'nearest');
                            % embed the trial number as a visual trial marker
                            if(shouldMarkTrialEnd)
                                dt2(:, :, 1, end) = trialCounter;
                            end
                            %
                            
                            writeVideo(writerObj, dt2);
                            epochs(trialCounter, 3) = toc;
                            
                            meta{trialCounter}.prop = size(dt2);
                        end
                        
                        state = 3;
                        
                    catch ME
                        fprintf('\n\n*** Something bad happened, probably stop message *before* trigger .. trying to writeVideo');
                        fprintf('\n\n*** %s ***\n\n', ME.message);
                        if(exist('dt2', 'var'))
                            writeVideo(writerObj, dt2);
                        end
                    end
                end
                
                fprintf('\tTrial %d finished\n\n', trialCounter);
                trialCounter = trialCounter + 1;
            else
                message = '';
                fprintf('\nState not correct : %d\n', state);
                state = 3;
                fprintf('\nResetting state to : %d\n', state);
            end
            
            
        case 'end'
            fprintf('Protocol end.  Closing files \n\n');
            if(~saveRawFrameData)
                close(writerObj);
            end
            save([pathname filename '_meta.mat'], 'meta');
            state = 1;
            message = '';
            
        case 'stop'   % handled in the UDP messenger bytesAvailable function
            
        case 'exit'
            shouldContinue = false;
            
        case 'preview'
            % don't allow during trials although the only
            % reason to prevent it is to simplify state management i.e. reduce the
            % amount of "if this state, then ..." code.
            if(state == 1 )
                fprintf('Preview active ... \n');
                set(src, 'TriggerMode', 'Off');
                triggerconfig(cam,'immediate','none','none');
                if(~exist('fig', 'var'))
                    % hardcoded position and size!  Could use AspectRatio
                    % etc
                    fig = figure('Name', 'GigE Preview : Active', 'MenuBar', 'none', 'Position', [100 500 888 500]);
                else
                    set(fig, 'Name', 'GigE Preview : Active');
                end
                vidRes = cam.VideoResolution;
                nBands = cam.NumberOfBands;
                hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
                preview(cam, hImage);
                state = 2;
            elseif(state == 2)
                fprintf('Preview inactive\n');
                stoppreview(cam);
                set(fig, 'Name', '');
                % maybe useful to keep the window open, so don't close() it
                %   close(fig);
                state = 1;
                % reconfig and activate the hardware trigger
                triggerconfig(cam, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
                set(src, 'TriggerMode', 'On');
            end
            
            message = '';
        otherwise           % use the otherwise case to detect and extract
            % filename.  Probably not the best technique
            % format: filename: foo
            if(strfind(message, 'filename'))
                if(state == 2)
                    fprintf('\nPreview is active!\n');
                else
                    % setup file and enable trigger
                    parts = strsplit(message, ':');
                    filename = strtrim(parts{2});
                    fprintf('Filename = %s\n', filename);
                    if(~saveRawFrameData)
                        fprintf('Video path and filename : %s\n\n', [pathname filename '.avi']);
                        writerObj = VideoWriter([pathname filename '.avi']); %#ok<*TNMLP>
                        writerObj.FrameRate = Fps;
                        open(writerObj);
                    else
                        save([pathname filename], 'filename');
                    end
                    
                    % *assume* everything went ok and activate trigger
                    set(src, 'TriggerMode', 'On');
                    
                    trialCounter = 1;
                    state = 3;
                end
                message = '';
            end
    end
    
end

stop(cam);

if(exist('writerObj', 'var'))
    close(writerObj);
end
fprintf('Shutting down and cleaning up.\n\n\n');
cleanupUdpGigE;






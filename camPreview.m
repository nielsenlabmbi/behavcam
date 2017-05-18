function camPreview

global cam;

fprintf('Generating preview\n');

src = getselectedsource(cam);
set(src, 'TriggerMode', 'Off');
triggerconfig(cam,'immediate','none','none');
if(~exist('fig', 'var'))
    % hardcoded position and size!  Could use AspectRatio etc
    fig = figure('Name', 'GigE Preview', 'MenuBar', 'none', 'Position', [100 500 888 500]);
else
    set(fig, 'Name', 'GigE Preview');
end
vidRes = cam.VideoResolution;
nBands = cam.NumberOfBands;
hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
preview(cam, hImage);
pause(1);
stoppreview(cam);
% reconfig and activate the hardware trigger
triggerconfig(cam, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
set(src, 'TriggerMode', 'On');

fprintf('Preview done\n');

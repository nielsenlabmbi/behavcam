% properly shutdown UDP messenger, msg, and GigE camera, cam and src
% 
%  Workspace is also cleared!
%
if(exist('msg', 'var'))
    fclose(msg);
    delete(msg);
    clear msg;
end

if(exist('cam', 'var'))
    delete(cam);
    clear cam;
    clear src;
end

fclose all;
close all;
%clear;


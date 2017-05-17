function camFile

global fileInfo

%open file for movie acquisition
fname=fullfile(fileInfo.pathname,[fileInfo.filename '.avi']);

fprintf('Video path and filename : %s\n\n', fname);
fileInfo.writerObj = VideoWriter(fname); 
fileInfo.writerObj.FrameRate = fileInfo.Fps;
open(fileInfo.writerObj);

 
function camSaveData

global cam fileInfo meta trialCounter;

%get data from camera
[dt, ~, meta{trialCounter}.metadata] = getdata(cam, cam.FramesAvailable);
                        
%resize for faster saving                        
dt2 = imresize(dt, fileInfo.resizeScale, 'nearest');
%embedd trialCounter
dt2(:, :, 1, end) = trialCounter;
         
%save data
writeVideo(fileInfo.writerObj, dt2);
                            
meta{trialCounter}.prop = size(dt2);

disp(['Trial ' num2str(trialCounter) ' saved']);

trialCounter=trialCounter+1;

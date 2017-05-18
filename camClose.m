function camClose

global cam;

src = getselectedsource(cam);

if(exist('cam', 'var'))
    delete(cam);
    clear cam;
    clear src;
end
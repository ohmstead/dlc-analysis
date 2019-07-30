function tsimage(FREEZE_THRESHOLD)
%TSIMAGE    Timeseries image.
%   Plots a figure with an image of a single frame from a video at the top
%   and timeseries corresponding to that frame on the bottom. Initiall
%   written to analyze pose estimation videos produced from DeepLabCut.
% 
%   Written by Jack Olmstead, July 2019

% % check inputs
% assert(isa(inmovie,'videoreader'),'input ''inmovie'' must be a VideoReader object')
% assert(isa(framenum,'integer'),'input ''framenum'' must be an integer')
% assert(isa(csvcontents,'numeric'),'input ''csvcontents'' must be type numeric')

% temp script to develop function
% parpath = 'C:\Users\Han Lab\Desktop\dlc_analysis\cfos-looming\';
% csvfilename = 'mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000.csv';
% vidfilename = 'mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000filtered_labeled.mp4';
% csvfilepath = [parpath 'position-csvs\' csvfilename];
% vidfilepath = [parpath 'labeled-vids\' vidfilename];

% close figs & waitbars
w = findall(0,'type','figure','tag','TMWWaitbar');
close all
close(outmovie)
delete(w)
clearvars

% set freeze threshold
% FREEZE_THRESHOLD = 2.5;  % pixels/s

CSVFILEPATH = ['~/GitHub/dlc-analysis/cfos-looming/position-csvs/' ...
               'mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000.csv'];
VIDFILEPATH = '~/Desktop/temp/mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000filtered_labeled.mp4';

% input variables for script
inmovie = VideoReader(VIDFILEPATH);
% [csvcontents,rawtxt,rawcsv] = xlsread(csvfilepath);
csvcontents = csvread(CSVFILEPATH,3,0);

% find number of points
numcol = size(csvcontents,2);
numpts = (numcol - 1) / 3;
fps = round(inmovie.FrameRate);

% relevantCols is a variable used to isolate x-/y-position columns from csv and
% ignore cols we don't need
relevantCols = 1:numcol;
trashCols = [1, relevantCols(4:3:end)];
relevantCols(trashCols) = [];
relevantCols = reshape(relevantCols,2,[])';

% set position of the image location in figure
imgRatio = inmovie.Width / inmovie.Height;
IMAGE_HEIGHT = .4;
imgWidth = IMAGE_HEIGHT * imgRatio;  % set ratio for image
xstart = (1 - imgWidth) / 2;  % center in middle of fig
ystart = 1 - IMAGE_HEIGHT;  % fill to top
pos = [xstart ystart imgWidth IMAGE_HEIGHT];

% set position of timeseries axes in figure. we will need to be economical
% in the y-direction, since that's the tightest dimension. x matters less.
yremaining = 1 - IMAGE_HEIGHT;
XFOREACH = .9;  % buffers leaves space for legends/labels
ybufferedforeach = yremaining / numpts;
yactualforeach = ybufferedforeach - ybufferedforeach / 10;  % actual is how big space the axes takes up
positionarray = zeros(numpts,4);  % array to store positions
ypositioncounter = 0.015;
for i = 1:numpts
    currentystart = ypositioncounter + .025;
    curraxposition = [(1-XFOREACH)/2 ypositioncounter XFOREACH yactualforeach];
    positionarray(i,:) = curraxposition;
    ypositioncounter = ypositioncounter + ybufferedforeach;
end

% initialize frame capture
numframes = length(csvcontents);
M(numframes) = struct('cdata',[],'colormap',[]);
frame = 1;

% initialize movie object
outmoviename = sprintf('%s/PILOT_freezeThreshold_%.1f.avi', pwd, FREEZE_THRESHOLD);
outmovie = VideoWriter(outmoviename);
open(outmovie)

% get some values for reporting progress to user
pctdone = 0;
initstr = sprintf('0% done. Frame 1 of %d',numframes);
wb = waitbar(pctdone,initstr);
tic

% find speed for tracked pts thruout all video
speed = zeros(length(csvcontents) - 1, numpts);
for k = 1:numpts
    % init some vectors
    Ys = csvcontents(:,relevantCols(k,:));
    timevector = [0:(length(Ys) - 1)] ./ fps;
    Xs = [ timevector', timevector' ];  % frames -> sec

    % find speed for tracked points
    speed2d = diff(Ys);
    speed(:,k) = sqrt(speed2d(:,1).^2 + speed2d(:,2).^2);
    accel = diff(speed);  % instantaneous abs. acceleration (IAA)
end


% loop thru each frame of movie
while hasFrame(inmovie)
    % find duration of last loop
    framesleft = numframes - frame;
    t = toc;
    timeleft = round(framesleft * t);
    tic;
    
    % report progress
    progstr = sprintf('%.1f%% done. Frame %d of %d.\n%d:%02.f remaining',...
                      pctdone * 100,frame,numframes,floor(timeleft/60), rem(timeleft,60));
    wb = waitbar(pctdone,wb,progstr);
    
    % initialize figure and axes
    f = figure('position',[1942 -274 1659 915]);
    imgax = axes(f,'position',pos);

    % extract image from movie
    vidFrame = readFrame(inmovie);

    % plot image
    I = image(vidFrame, 'Parent', imgax);
    axis off

    % text framenum to image
    xplacement = inmovie.Width - inmovie.Width / 15;
    yplacement = inmovie.Height - inmovie.Height / 10 - 20;
    t = text(xplacement,yplacement,...
             num2str(frame),...
             'color','white',...
             'fontsize',20,...
             'horizontalalignment','center');
    
    % get the current speed for all points
    v = max(speed(frame,:));

    % text current speed
    text(inmovie.Width/2, 15,...
         sprintf('current speed: %.1f pixels/s',v),...
         'color','white',...
         'fontsize',20,...
         'horizontalalignment','center')

    % text image if velocity is above a threshold
    if v <= FREEZE_THRESHOLD
        text(inmovie.Width/2, 50,...
             'FREEZE',...
             'color','cyan',...
             'fontsize',20,...
             'horizontalalignment','center')
    end
    
    % text a small freeze threshold marker on frame
    text(xplacement,yplacement+55,...
         sprintf('Freeze threshold:\n%.1f pixel/s',FREEZE_THRESHOLD),...
         'color','white',...
         'horizontalalignment','center');
    
    % plot all timeseries (x-/y-position & velocity)
    for n = 1:numpts
        
        % init axes
        ax = axes(f,'position',positionarray(n,:));

        % plot speed
        hold on
        yyaxis right
        p1 = plot(ax,Xs(1:end-1,1),speed(:,n),'k:','linewidth',1);  % speed
        ylabel('vel. (pixels/s)')
        ylim([0 30])
        vax = ax.Children(1);
        
        % hline
        hL = hline(FREEZE_THRESHOLD,'k--');
        hL.LineWidth = .5;

        
        % plot x-/y-timeseries
        yyaxis left
        p2 = plot(ax,Xs,Ys,'-','linewidth',3);
        hold off

        % vline
        vL = vline(frame / fps,'r-');
        vL.LineWidth = 1.5;
        
        
    %     title(ax,rawtxt{2,relevantCols(n,1)})
        xlabel(ax,'time (s)')
        ylabel(ax,'pixel position')

        pax = ax.Children(1);
        leg = legend([pax, vax],...
            'x-/y-position','velocity');
    end

    % add frame to outmovie
    M(frame) = getframe(f);
    writeVideo(outmovie,M(frame).cdata)
    
    % increment counter
    frame = frame + 1;
    pctdone = frame / numframes;
        
    close(f)
        
end %of movie loop

% play movie
% movie(M);

% save movie
close(outmovie)


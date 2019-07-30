% function outmovie = tsimage(inmovie, framenum, csvcontents)
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
parpath = 'C:\Users\Han Lab\Desktop\dlc_analysis\cfos-looming\';
csvfilename = 'mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000.csv';
vidfilename = 'mouseID_SC cfos 1DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000filtered_labeled.mp4';
csvfilepath = [parpath 'position-csvs\' csvfilename];
vidfilepath = [parpath 'labeled-vids\' vidfilename];

% input variables for script
inmovie = VideoReader(vidfilepath);
[csvcontents,rawtxt,rawcsv] = xlsread(csvfilepath);
framenum = 44;

% find number of points
numcol = size(csvcontents,2);
numpts = (numcol - 1) / 3;
fps = round(inmovie.FrameRate);

% clean csvcontents
relevantCols = 1:numcol;
trashCols = [1, relevantCols(4:3:end)];
relevantCols(trashCols) = [];
relevantCols = reshape(relevantCols,2,[])';
currplot = 1;

% set position of the image location in figure
imgRatio = inmovie.Width / inmovie.Height;
imgHeight = .4;
imgWidth = imgHeight * imgRatio;  % set ratio for image
xstart = (1 - imgWidth) / 2;  % center in middle of fig
ystart = 1 - imgHeight;  % fill to top
pos = [xstart ystart imgWidth imgHeight];

% set position of timeseries axes in figure. we will need to be economical
% in the y-direction, since that's the tightest dimension. x matters less.
xremaining = 1 - xstart;
yremaining = 1 - ystart;
xbufferedforeach = xremaining / numpts;  % buffers leaves space for legends/labels
ybufferedforeach = yremaining / numpts;
yactualforeach = ybufferedforeach - .05;  % actual is how big space the axes takes up
positionarray = zeros(numpts,4);  % array to store positions
ypositioncounter = 0;
for n = 1:numpts
    currentystart = ypositioncounter + .025;
    curraxposition = [.1 ypositioncounter .8 currentystart];
    positionarray(n,:) = curraxposition;
end

% initialize figure and axes
f = figure('position',[1 41 2560 1327]);
imgax = axes(f,'position',pos);
for n = numpts:1
    axes(f,'position',positionarray(n,:))
end

% extract image from movie
vidFrame = readFrame(inmovie);

% plot image
I = image(vidFrame, 'Parent', imgax);
axis off

% add framenum to image
xplacement = inmovie.Width - inmovie.Width / 15;
yplacement = inmovie.Height - inmovie.Height / 10;
t = text(xplacement,yplacement,...
    num2str(framenum),'color','white','fontsize',50);

% plot all timeseries (x-/y-position & velocity)
for n = 1:numpts
    % make plots and add captions for tracked points
    Ys = csvcontents(:,relevantCols(n,:));
    timevector = [0:(size(Ys,1) - 1)] / fps;
    Xs = [ timevector', timevector' ];  % frames -> sec
    
    ax = subplot(numpts,1,n);
    
    % 2-D instantaneous absolute velocity (IAV; no direction) for tracked pt
    iav = diff(csvcontents(:,relevantCols(n,:)),2) * fps;
    iaa = diff(iav,2);  % instantaneous abs. acceleration (IAA)
    
    % plot IAA and x-/y-timeseries
    hold on
    yyaxis right
    p1 = plot(ax,Xs(1:end-2,1),hampel(iav),'k:','linewidth',1);  % IAA
    ylabel('velocity (pixels/second)')
    ylim([-300 300])
    
    yyaxis left
    p2 = plot(ax,Xs,hampel(Ys),'-','linewidth',3);
    hold off
    
    title(ax,rawtxt{2,relevantCols(n,1)})
    xlabel(ax,'time (s)')
    ylabel(ax,'pixel position')
    
    leg = legend([ax.Children(1),ax.Children(2)],...
        'acceleration','x-/y-position');
end

% add vertical line to all timeseries plots
plts = findall(f,'type','axes');
for n = 2:length(plts)
    cplt = plts(n);
    maxy = cplt.YLim;  % get upper limit of y axis
    x = [framenum framenum];
    y = [0 maxy(2)];
    line(x,y,'color','red','linewidth',1);
end

% add frame to outmovie
% suybF = getframe();




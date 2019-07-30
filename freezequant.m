% Script to quantify freezing using deeplabcut (DLC) csv output.

% read in DLC data
csvpath = 'C:/Users/Han Lab/Desktop/mouse2_cfos/mouseID_SC cfos 2DeepCut_resnet50_cfos-loomingJul22shuffle1_1030000.csv';
[rawnum,rawtxt,rawcsv] = xlsread(csvpath);

% set FPS
fps = 24;
interframeInterval = 1/fps;

% find number of tracked points
numcol = size(rawnum,2);
numpts = (numcol - 1) / 3;

%% Step 1: plot all points as timeseries
f = figure('position',[1 41 2560 1.3273e+03]);

% clear out p-value columns, since we don't need them for plotting
relevantCols = 1:numcol;
trashCols = [1, relevantCols(4:3:end)];
relevantCols(trashCols) = [];
relevantCols = reshape(relevantCols,2,[])';
currplot = 1;

for n = 1:numpts
    % make plots and add captions for tracked points
    Ys = rawnum(:,relevantCols(n,:));
    timevector = [0:(size(Ys,1) - 1)] / fps;
    Xs = [ timevector', timevector' ];  % frames -> sec
    
    ax = subplot(numpts,1,n);
    
    % 2-D instantaneous absolute velocity (IAV; no direction) for tracked pt
    iav = diff(rawnum(:,relevantCols(n,:)),2) * fps;
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


%% Step 2: come up with freezing algorithm










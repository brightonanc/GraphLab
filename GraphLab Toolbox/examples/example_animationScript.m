% $Author Brighton Ancelin
% Read in the column data
fid = fopen('exampleData_Compressed.csv');
data = textscan(fid,'%d%d%d%s%s','Delimiter',sprintf(','));
fclose(fid);
mat = [data{1},data{2},data{3}];
% Import the overall graph
overallGraph = importNet(mat(:,[2,3]),false);
% Get a max of 100 graph frames with a time stride of 100
[graphFrames,timesMat] = getGraphFrames(mat(:,[2,3]),mat(:,1),false,100,20);
% Generate titles for each frame
titles = sprintf('Example Graph from times %d to %d;',timesMat.');
titles = strsplit(titles,';');
% Export Convention-Style Animation with 1-second transition time between
% graph frames and 20 frames (0.67 seconds) of each stagnant graph frame
exportConventionStyleVisualAnimated('example_conventionAnimation.gif',...
		graphFrames,titles,1,20,Inf);
% Export Edge-Updating Animation with 30 frames (1 second) per graph frame
% and 5 graph frames before old edges disappear. The layout of the graph is
% 'force'
exportEdgeUpdatingVisualAnimated('example_edgeUpdatingAnimation.gif',...
		overallGraph,graphFrames,titles,30,5,'force',Inf);
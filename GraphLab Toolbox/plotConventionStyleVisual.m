% $Author Brighton Ancelin
% Plots a graph in the convention-style. For information regarding the 
% visual architecture of 'convention-style', See also 
% GETCONVENTIONSTYLEVISUALDATA
%
% INPUT:
%	graphFrame: Graph object to be rendered
%
% OUTPUT:
%	fig: Figure object of the figure used for rendering
%
% GRAPH REQUIREMENTS:
%   - None
function fig = plotConventionStyleVisual(graphFrame)
	% Get drawing coordinates for the nodes and edges
	[frameCoords,frameEdges] = getConventionStyleVisualData(graphFrame);
	fig = figure;
	hold on;
	% Scatter plot draw all the nodes
	scatter(frameCoords(1,:),frameCoords(2,:));
	circleResolution = 0.001; % Precision of the outer ring circle
	% Plot draw a blue outer ring for the lone nodes to lay ons
	plot(cos(2*pi*(0:circleResolution:1)),sin(2*pi*(0:circleResolution:1)),'b');
	for curEdge = frameEdges
		% Plot draw all edges as red lines
		plot(curEdge(1:2),curEdge(3:4),'r');
	end
	% Remove the axis for rendering
	axis off;
	hold off;
end
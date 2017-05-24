% $Author Brighton Ancelin
% Exports a visualization of assortativity data. The x axis represents node
% degree values while the y axis represents the average degree of 
% neighboring nodes. Both axes use a logarithmic scale. A scatter plot 
% shows average degree of neighbors on a node-by-node basis, whereas a line
% shows the average degree of neighbors for all nodes of a specific degree.
% In essence, the points of the line merely depict a weighted average 
% (vertically) of the scatter plot.
%
% INPUT:
%   metrics: Metrics structure of the graph. Used to save
%       computation time
%	netname: Name of the network for visualizations
%
% GRAPH REQUIREMENTS:
%	- None
function varargout = exportAssortativityVis(metrics,netname)
	figObj = figure;
	scatX = metrics.degrees.';
	scatY = metrics.assortativityByNode.';
	lineY = metrics.assortativityByDegree.';
	hold on;
	% Set log scales
	set(gca(),{'xscale','yscale'},{'log','log'});
	scatter(scatX,scatY);
	% Plotting 0-values, or degrees for which there are nodes in the graph,
	% serves no purpose and only disrupts the cleanliness of the line.
	plotMask = 0~=lineY;
	plot(find(plotMask),lineY(plotMask));
	hold off;
	legend('Per-Node Avgs','Overall Avgs');
	xlabel('Degree of Node');
	ylabel('Avg Degree of Neighboring Nodes');
	title('Assortativity Plot');
	input('Press enter to save figure as is.') % Adjust the legend location manually
	print([netname,'_assortativityPlot'],'-dpng');
	if(nargout < 1)
		close(figObj);
	else
		varargout{1} = figObj;
	end
end
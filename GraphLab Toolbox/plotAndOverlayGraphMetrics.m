% $Author Brighton Ancelin
% Overlays several specific metrics onto a visualization of the graph.
%
% INPUT:
%	graphObj: Graph object
%   metrics: (Optional) Metrics structure of the graph. Used to save
%       computation time
%	layout: (Optional) Specify the layout that the graph will be plotted
%		with
%
% OUTPUT:
%   figObj: Object of the figure created for the plot
%
% GRAPH REQUIREMENTS:
%	- None
function figObj = plotAndOverlayGraphMetrics(graphObj,metrics,layout)
	if(nargin < 2)
		metrics = getGraphMetrics(graphObj);
	end
	if(nargin < 3)
		layout = 'auto';
	end
	if(isfield(metrics,'avgClustering'))
		clust = sprintf('%0.2f',metrics.avgClustering);
	else
		clust = 'N/A';
	end
	figObj = figure;
	plot(graphObj,'Layout',layout);
	metricsStr = sprintf([...
		    'Node Count: %d\n',...
			'Edge Count: %d\n',...
			'Average Path: %0.2f\n',...
			'Diameter: %d\n',...
			'Average Clustering: %s\n',...
			'Max Eigenvalue: %0.2f\n',...
			],metrics.nodeCt,metrics.edgeCt,metrics.avgPathLength,...
		    metrics.diameter,clust,metrics.maxEigenvalue);
	legend(metricsStr);
end


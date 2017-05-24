% $Author Brighton Ancelin
% Exports an assortment of metrics visualizations for a particular graph
%
% INPUT:
%   metrics: Metrics structure of the graph. Used to save
%       computation time
%	netname: Name of the network for visualizations
%
% GRAPH REQUIREMENTS:
%	- None
function exportMetricsVisualizations(metrics,netname)
	exportDistDistribVis(metrics,netname); % Fully connected graphs only
	exportClustDistribVis(metrics,netname); % Undirected graphs only
	exportAssortativityVis(metrics,netname);
end
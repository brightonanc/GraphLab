% $Author Brighton Ancelin
% Acts as a standardized import script. Given a graph object, a general
% prefix, and a title for the metrics file, this function will:
%	- export a metrics file
%	- save a .MAT file with the following:
%		- adjacency matrix
%		- graph object
%		- metrics object
%	- export a MATLAB figure of the visualization of the graph's nodes and
%	edges with a legend that has several key metrics
%	- export the aforementioned visualization as a PNG as well
%	- export several additional visuals from exportMetricsVisualizations
%		- See also EXPORTMETRICSVISUALIZATIONS
%
% INPUT:
%	graphObj: Graph object to base data off of
%	prefix: Short prefix that will be used in nearly all variables and
%		filenames.
%	title: Title to be used in the metrics file for this graph
%
% GRAPH REQUIREMENTS:
%	- None
function exportStandardGraphFiles(graphObj,prefix,title)
	% Export metrics file
	metrics = exportMetricsFile(graphObj,title,[prefix,'_metrics']);
	% Build struct of data using prefix in the variable names
	st.([prefix,'AdjMat']) = adjacency(graphObj);
	st.([prefix,'GraphObj']) = graphObj;
	st.([prefix,'Metrics']) = metrics;
	% Save struct data to a .MAT file
	save([prefix,'.mat'],'-struct','st');
	% Delete st (just in case it is consuming too much memory)
	clear st;
	% Create node and edge visualization
	figObj = plotAndOverlayGraphMetrics(graphObj,metrics);
	input('Press enter to save figure as is.') % Adjust the legend location manually
	% Save as a MATLAB figure
	savefig([prefix,'_visualization']);
	% Save as a PNG
	print([prefix,'_visualization'],'-dpng');
	close(figObj);
	% Export further visuals
	exportMetricsVisualizations(metrics,prefix);
end
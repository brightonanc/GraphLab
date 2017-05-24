% $Author Brighton Ancelin
% Exports a visualization of cumulative local clustering coefficient 
% distribution data. The x axis represents local clustering coefficient 
% values while the y axis represents percent of nodes that have that or a 
% lesser local clustering coefficient (hence cumulative percentage). 
% Vertical lines are also overalyed which show where the 50-percentile, 
% 90-percentile, and average local clustering coefficients lie.
%
% INPUT:
%   metrics: Metrics structure of the graph. Used to save
%       computation time
%	netname: Name of the network for visualizations
%
% GRAPH REQUIREMENTS:
%	- None
function varargout = exportClustDistribVis(metrics,netname)
	if(~isfield(metrics,'clusterings'))
		fprintf(['No clustering coefficient data could be found - most',...
				' likely this graph is a directed graph.\nNo',...
				' visualization was made.\n']);
		return;
	end
	figObj = figure;
	clustX = full(sort(metrics.clusterings.'));
	clustY = linspace(0,1,length(clustX)+1);
	% Remove the 0-value
	clustY = clustY(2:end);
	interpSafeMask = [true, 0~=diff(clustY)]; % Important when slope of clustY vs clustX is 0 at some point
	% 50-percentile
	sig50 = ones(2,1).*interp1(clustY(interpSafeMask),clustX(interpSafeMask),0.5);
	% Average
	sigMean = ones(2,1).*metrics.avgClustering;
	% 90-percentile
	sig90 = ones(2,1).*interp1(clustY(interpSafeMask),clustX(interpSafeMask),0.9);
	plot(clustX,clustY,sig50,[0,1],sigMean,[0,1],sig90,[0,1]);
	legend('Clustering Coeffs','50-%ile','Average','90-%ile');
	xlabel('Clustering Coefficients');
	ylabel('Cumulative Percentage');
	title('Distribution of Clustering Coefficients');
	input('Press enter to save figure as is.') % Adjust the legend location manually
	print([netname,'_clusteringDistribution'],'-dpng');
	if(nargout < 1)
		close(figObj);
	else
		varargout{1} = figObj;
	end
end
% $Author Brighton Ancelin
% Exports a visualization of cumulative distance distribution data. The x
% axis represents distance values while the y axis represents percent of
% node pairings that are connected by that or a shorter distance (hence 
% cumulative percentage). Vertical lines are also overalyed which show
% where the 50-percentile, 90-percentile, and average distance lie.
%
% INPUT:
%   metrics: Metrics structure of the graph. Used to save
%       computation time
%	netname: Name of the network for visualizations
%
% GRAPH REQUIREMENTS:
%	- None
function varargout = exportDistDistribVis(metrics,netname)
	if(~isfield(metrics,'distanceDistribution'))
		fprintf(['No distance distribution data could be found - most',...
				' likely this graph is not fully connected.\nNo',...
				' visualization was made.\n']);
		return;
	end
	figObj = figure;
	distX = metrics.distanceDistribution.Distance.';
	% Use cumsum to obtain cumulative data
	distY = cumsum(metrics.distanceDistribution.QuantityOfNodePairs.');
	% Normalize distY to have values between 0 and 1, inclusive
	distY = distY./distY(end);
	interpSafeMask = [true, 0~=diff(distY)]; % Important when slope of distY vs distX is 0 at some point
	% 50-percentile
	sig50 = ones(2,1).*interp1(distY(interpSafeMask),distX(interpSafeMask),0.5);
	% Average
	sigMean = ones(2,1).*metrics.avgPathLength;
	% 90-percentile
	sig90 = ones(2,1).*interp1(distY(interpSafeMask),distX(interpSafeMask),0.9);
	plot(distX,distY,sig50,[0,1],sigMean,[0,1],sig90,[0,1]);
	legend('Distances','50-%ile','Average','90-%ile');
	xlabel('Shortest Distance (edges)');
	ylabel('Cumulative Percentage');
	title('Distribution of Node Distances');
	input('Press enter to save figure as is.') % Adjust the legend location manually
	print([netname,'_distanceDistribution'],'-dpng');
	if(nargout < 1)
		close(figObj);
	else
		varargout{1} = figObj;
	end
end
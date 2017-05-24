% $Author Brighton Ancelin
% Returns the local clustering coefficients of an undirected, unweighted
% graph for each node enumerated in a column vector. Nodes with degree 1 or
% less (i.e. 1 or fewer neighbors) are incapable of forming triangles and 
% are given a default clustering coefficient of 0.
%
% See also:
%	https://en.wikipedia.org/wiki/Clustering_coefficient#Local_clustering_coefficient
%	http://www.stevenstrogatz.com/articles/collective-dynamics-of-small-world-networks-pdf
%
% INPUT:
%	graphObj: Graph object
%
% OUTPUT:
%	clusteringCoeffs: Column vector of clustering coefficients derived for
%	    each node.
%
% GRAPH REQUIREMENTS:
%	- Undirected
%	- Unweighted
function clusteringCoeffs = getClusteringCoefficients(graphObj)
	% Necessary to prune loopback edges for algorithm to properly function
	adjMat = adjacency(pruneLoopbacks(graphObj));
	% Calculates local clustering coefficients by the definition
	degs = sum(adjMat,2);
	numTriangles = diag(adjMat*triu(adjMat)*adjMat);
	maxTrianglesPossible = degs.*(degs-1)./2;
	clusteringCoeffs = numTriangles./maxTrianglesPossible;
	% For nodes where triangles are not possible (degree<=1), assign them a
	% default clustering coefficient of 0
	clusteringCoeffs(degs <= 1) = 0;
end
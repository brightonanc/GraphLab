% $Author Brighton Ancelin
% Returns a structure of various graph metrics.
%
% INPUT:
%	graphObj: Graph object to be analyzed
%
% OUTPUT:
%   metrics: Structure with metrics data. Fields:
%		isDirected: true if graph is directed, false if graph is undirected
%		isFullyConn: true if graph is fully, strongly connected.
%			See also:
%				https://en.wikipedia.org/wiki/Connectivity_(graph_theory)#Connected_graph
%				https://en.wikipedia.org/wiki/Strongly_connected_component
%		distances: NxN (N is the number of nodes) matrix where
%			distances(i,j) represents the shortest path distance between 
%			node i and node j. distances(i,i) will always equal 0,
%			regardless of self-edges.
%			See also:
%				https://en.wikipedia.org/wiki/Shortest_path_problem
%		nodeCt: Integer number of nodes in the graph.
%		edgeCt: Integer number of edges in the graph.
%		avgPathLength: Average of all shortest paths between distinct nodes
%			in the graph.
%		diameter: Maximum shortest path length in the graph, i.e. maximum 
%			value of the aforesaid 'distances' field after matrix 
%			linearization.
%		clusterings: Column vector of local clustering coefficients.
%			clusterings(n) will return the local clustering coefficient of
%			the nth node. Nodes with degree 1 or less (i.e. 1 or fewer 
%			neighbors) are incapable of forming triangles and are given a
%			default clustering coefficient of 0.
%			See also:
%				https://en.wikipedia.org/wiki/Clustering_coefficient#Local_clustering_coefficient
%				http://www.stevenstrogatz.com/articles/collective-dynamics-of-small-world-networks-pdf
%		avgClustering: Average of all local clustering coefficients as
%			defined above.
%		maxEigenvalue: Maximum eigenvalue of the adjacency matrix. By the
%			Perron-Frobenius Theorem, this eigenvalue has an associated
%			eigenvector whose entries are all nonnegative (for undirected 
%			graphs). This is useful for centrality measurements.
%			See also:
%				https://en.wikipedia.org/wiki/Perron%E2%80%93Frobenius_theorem
%		eigenCentralities: Eigenvector associated with the maxEigenvalue
%			referenced above. eigenCentralities(n) will return the 
%			eigencentrality of the nth node.
%			See also:
%				https://en.wikipedia.org/wiki/Eigenvector_centrality
%		degrees: Column vector of degree values. degrees(n) will return the
%			degree of the nth node.
%			See also:
%				https://en.wikipedia.org/wiki/Degree_(graph_theory)
%		degreeCentralities: Column vector of degree centralities, defined
%			as the degree of each node divided by the maximum degree that
%			node could have. degreeCentralities(n) will return the degree 
%			centrality of the nth node.
%			See also:
%				https://en.wikipedia.org/wiki/Centrality#Degree_centrality
%		closenessCentralities: Column vector of closeness centralities,
%			defined as the reciprocal of the average of all shortest paths 
%			originating from a given node. closenessCentralities(n) will 
%			return the closeness centrality of the nth node.
%			See also:
%				https://en.wikipedia.org/wiki/Centrality#Closeness_centrality
%		distanceDistribution: A table of distance distribution data.
%			The 'Distance' vector contains integer values that represent
%			the shortest path lengths. The 'QuantityOfNodePairs' vector
%			contains corresponding quantities of node pairs that have the
%			associated shortest path between them.
%			See also:
%				http://konect.uni-koblenz.de/plots/distance_distribution_plot
%		assortativityByNode: Column vector of assortativity data.
%			assortativityByNode(n) will return the average degree of all
%			neighbors of the nth node.
%			See also:
%				https://en.wikipedia.org/wiki/Assortativity#Neighbor_connectivity
%		assortativityByDegree: Column vector of assortativity data.
%			assortativityByDegree(n) will return the average of the vector
%			assortativityByNode(arr) where arr contains the node indices of
%			all nodes in the graph of degree n.
%			See also:
%				https://en.wikipedia.org/wiki/Assortativity#Neighbor_connectivity
%
% GRAPH REQUIREMENTS:
%	- Unweighted
function metrics = getGraphMetrics(graphObj)
	adjMat = adjacency(graphObj);
	% Some algorithms require any self-edges to be removed from the
	% adjacency matrix. The variable 'adjMatDiagless' is a convenient
	% solution
	adjMatDiagless = adjMat - diag(diag(adjMat));
	metrics.isDirected = isa(graphObj,'digraph');
	if(metrics.isDirected)
		% Determine full, strong connectedness by checking if the bin ID of
		% every node in the graph is identical
		metrics.isFullyConn = all(0 == diff(conncomp(graphObj,'Type','strong')));
	else
		% Determine full connectedness by checking if the bin ID of every 
		% node in the graph is identical
		metrics.isFullyConn = all(0 == diff(conncomp(graphObj)));
	end
	metrics.distances = distances(graphObj);
	metrics.nodeCt = size(metrics.distances,1);
	metrics.edgeCt = size(graphObj.Edges,1);
	% avgPathLength will be Inf if graph is not fully, strongly connected
	% Disregarding self-edges, there are nodeCt*(nodeCt-1) unique paths in
	% the graph
	metrics.avgPathLength = sum(metrics.distances(:))/(metrics.nodeCt*(metrics.nodeCt-1));
	% diameter will be Inf if graph is not fully, strongly connected
	metrics.diameter = max(metrics.distances(:));
	if(~metrics.isDirected)
		% The 'getClusteringCoefficients' function requires the graph be 
		% undirected, unweighted
		metrics.clusterings = getClusteringCoefficients(graphObj);
		metrics.avgClustering = full(mean(metrics.clusterings));
	end
	[eigenvecs,eigenvalsMat] = eig(full(adjMat));
	% Transform the diagonal matrix into a column vector
	eigenvals = diag(eigenvalsMat);
	[metrics.maxEigenvalue,indxr] = max(eigenvals);
	% The MATLAB-generated eigenvector might be all nonpositive values, so
	% a negation of the eigenvector in this case is desirable
	% We compare positive and negative sums because sometimes 0s are
	% rounded as very tiny values of the opposite sign from the rest of the
	% vector
	negate = sum(eigenvecs(:,indxr)<0) > sum(eigenvecs(:,indxr)>0);
	metrics.eigenCentralities = eigenvecs(:,indxr).*((-1)^negate);
	% Summing each row works for both undirected and directed graphs
	metrics.degrees = sum(adjMatDiagless,2);
	% Divide each degree by the maximum degree possible
	metrics.degreeCentralities = metrics.degrees./(metrics.nodeCt-1);
	% Some closeness centralities may be 0 if graph is not fully, strongly 
	% connected
	% Closeness is the inverse of farness. Farness is the average of all
	% shortest paths (not including self-edges) originating from a node.
	metrics.closenessCentralities = (metrics.nodeCt-1)./sum(metrics.distances,2);
	% Ensure that graph is fully connected for distance distribution
	% calculations
	if(isfinite(metrics.diameter))
		distVals = 1:metrics.diameter;
		if(~metrics.isDirected)
			distVec = triu(metrics.distances);
		else
			distVec = metrics.distances;
		end
		% Remove self-edges from 'distVec'; also linearizes matrix into a 
		% vector form
		distVec = distVec(0 ~= distVec);
		qNodePairs = zeros(size(distVals));
		for ind=distVals
			% qNodePairs(ind) contains the quantity of node pairs that have
			% shortest path length of ind between them.
			qNodePairs(ind) = sum(distVec == ind);
		end
		metrics.distanceDistribution = table(distVals.',qNodePairs.','VariableNames',{'Distance','QuantityOfNodePairs'});
	end
	% Necessary to avoid NaN values
	degreesSafeDividing = metrics.degrees;
	% This essentially prevents 0./0 generating a NaN by changing the
	% operation to be 0./1, which equals 0.
	degreesSafeDividing(0==degreesSafeDividing) = 1;
	% Sum the degrees of each nodes neighbors through matrix multiplication
	% and then divide by the total number of neighbors each node has.
	metrics.assortativityByNode = (adjMatDiagless*metrics.degrees)./degreesSafeDividing;
	degComboMat = zeros(max(metrics.degrees),metrics.nodeCt);
	non0mask = 0 ~= metrics.degrees;
	% Create a linear indexing vector which will index all points (i,j) in
	% the matrix such that the jth node has degree i.
	indxr = sub2ind(size(degComboMat),metrics.degrees(non0mask),find(non0mask));
	degComboMat(indxr) = 1;
	% Some complicated math, but effectively degComboMat*adjMatDiagless
	% yields a matrix where entry (i,j) equals the number of instances
	% where the jth node is a neighbor of any node of degree i.
	% degByDegSafeDividing(n) then equals the total number of neighbors
	% to any node of degree n, where double counting is allowed (e.g. if 
	% node 2 has edges with nodes 3 & 4, both of which are of degree 1, 
	% then node 2 is counted as two neighbors, i.e. 
	% degByDegSafeDividing(1) = 2)
	degByDegSafeDividing = sum(degComboMat*adjMatDiagless,2);
	degByDegSafeDividing(0==degByDegSafeDividing) = 1;
	metrics.assortativityByDegree = (degComboMat*adjMatDiagless*metrics.degrees)./degByDegSafeDividing;
end
% $Author Brighton Ancelin
% Generates node and edge coordinates for drawing purposes. Given a graph,
% this function will identify all connected components within the graph
% (weakly connected if digraph) and draw each connected component with the
% nodes placed on the vertices of a regular convex polygon and then draw
% edges between these nodes (digraphs will not have edge direction drawn).
% The centers of these connected component polygons are themselves located
% on the vertices of a regular convex polygon centered at the origin. Two 
% exceptions exist: (1) if there is only 1 connected component, the center 
% of the connected component's polygon is the origin; (2) if there are only
% 2 connected components, the centers of the connected component's polygons
% lay on the edges of a horizontal line segment centered at the origin. All
% lone nodes are drawn along an outer ring, which is merely a circle 
% centered at the origin whose radius extends beyond all the coordinates of
% connected nodes.
%
% INPUT:
%	graphFrame: Graph object to get drawing coordinates from
%
% OUTPUT:
%	frameCoords: Matrix of coordinates of nodes in the graph.
%		frameCoords(1,n) will return the x coordinate for the nth node in
%		the graph, and frameCoords(2,n) will return the y coordinate for
%		the nth node in the graph.
%	frameEdges: Matrix of coordinates for edges in the graph. 
%		frameEdges(1,n) returns the first x coordinate of the nth line,
%		frameEdges(2,n) returns the second x coordinate of the nth line,
%		frameEdges(3,n) returns the first y coordinate of the nth line,
%		frameEdges(4,n) returns the second y coordinate of the nth line.
%
% GRAPH REQUIREMENTS:
%   - None
function [frameCoords,frameEdges] = getConventionStyleVisualData(graphFrame)
	if(isa(graphFrame,'digraph'))
		% If graph is directed
		adjTriu = adjacency(graphFrame);
		% Add adj to its transpose to include all edges in the upper
		% triangle
		adjTriu = adjTriu + adjTriu.';
		% Use logical indexing and casting to create a true adjacency
		% matrix and take the triu of it
		adjTriu = triu(double(0 ~= adjTriu));
	else
		% If graph is undirected
		adjTriu = triu(adjacency(graphFrame));
	end
	adjTriu = adjTriu - diag(diag(adjTriu)); % Remove self-edges
	nodeCt = size(adjTriu,1);
	% Get the bins of the frame
	bins = conncomp(graphFrame);
	% We want to sieve the nodes into two categories: lone nodes, and
	% connected components. The orderedConnNodes variable will be a cell
	% vector storing vectors of node IDs in connected components. The
	% loneNodes variable will store a vector of lone node IDs.
	delBins = bins;
	orderedConnNodes = {};
	loneNodes = [];
	while(~isempty(delBins))
		% Process the largest bin that still hasn't been processed
		curBinNum = mode(delBins);
		% Get the node IDs of nodes in the current connected component
		% (AKA bin)
		nodesInBin = find(bins == curBinNum);
		% Remove the current bin from the still-to-be-processed vector
		delBins = delBins(delBins ~= curBinNum);
		if(length(nodesInBin) > 1)
			% If the current bin has multiple nodes, it is a connected
			% component. Enter it into the connected components cell array
			orderedConnNodes(end+1) = {nodesInBin};
		else
			% If the current bin has a single node, it is a lone node.
			% Enter it into the loneNodes vector
			loneNodes(end+1) = nodesInBin;
		end
	end
	% The radius along which all lone nodes will lay
	outerRadius = 1;
	% 10% separation between outer ring of lone nodes and the largest 
	% possible group drawing (groupCt=1 or 2)
	outerSpacingPercent = 0.1;
	% 20% separation between group circles
	groupSpacingPercent = 0.2;
	% Calculated radius of connected components' origins positions
	groupsPolygonRadius = outerRadius*(1-outerSpacingPercent)/(2-groupSpacingPercent);
	groupCt = length(orderedConnNodes);
	if(groupCt > 1)
		% If there are multiple connected components
		% Evenly space connected components' origins along a circle and
		% store the origins in two vectors, groupOriginsX and groupOriginsY
		groupOriginsX = cos(2*pi*linspace(0,1,groupCt+1));
		groupOriginsX(end) = [];
		groupOriginsY = sin(2*pi*linspace(0,1,groupCt+1));
		groupOriginsY(end) = [];
		if(groupCt > 2)
			% For triangles or regular shapes with more than 2 sides, the
			% following formula will calculate the side length
			polygonSideLength = groupsPolygonRadius.*sin(2*pi/groupCt)/cos(pi/groupCt);
		else
			% Outer if already guarantees groupCt > 1, so groupCt = 2 in this
			% case
			polygonSideLength = 2.*groupsPolygonRadius;
		end
		
		% Scale the origins' positions by the groupsPolygonRadius and store
		% in a groupOrigins matrix
		groupOrigins = groupsPolygonRadius.*[groupOriginsX;groupOriginsY];
		% The radius of nodes on a single connected component (or 'group')
		% with the mandatory groupSpacingPercent between groups is 
		% calculated below.
		groupRadius = 0.5*(1-groupSpacingPercent)*polygonSideLength;
	else
		% If there's only one connected component, set the origin to be the
		% center and the radius to be that of the groupsPolygonRadius
		% variable
		groupOrigins = [0;0];
		groupRadius = groupsPolygonRadius;
	end
	frameCoords = zeros(2,nodeCt); % 1st row: x coords; 2nd row: y coords
	for ind = 1:groupCt
		% Extract the current group's nodes
		nodes = orderedConnNodes{ind};
		% Evenly space the node positions along a circle, and offset the
		% coords by the current group's origin
		xCoords = groupOrigins(1,ind) + groupRadius*cos(2*pi*linspace(0,1,length(nodes)+1));
		xCoords(end) = [];
		yCoords = groupOrigins(2,ind) + groupRadius*sin(2*pi*linspace(0,1,length(nodes)+1));
		yCoords(end) = [];
		% Store the absolute positions of the nodes into the frameCoords
		% variable at the column corresponding to the ID of the node
		frameCoords(:,nodes) = [xCoords;yCoords];
	end
	% Every node has a place on the outer ring, however only the lone nodes
	% will lay in their place on the outer ring. The following line
	% calculates those positions
	frameCoords(:,loneNodes) = outerRadius.*[cos(2*pi*(loneNodes-1)./nodeCt);sin(2*pi*(loneNodes-1)./nodeCt)];
	% Nodes are already sorted, that is important for the following code.
	% All connected nodes have been given coordinates, also important for the
	% following code
	frameEdges = zeros(4,sum(adjTriu(:))); % 1st row: x1; 2nd row: x2; 3rd row: y1; 4th row: y2
	% fEIndxrShift is used to shift the indexing
	fEIndxrShift = 0;
	% Iterate through all nodes with edges
	for node = [orderedConnNodes{:}]
		% Find the current node's neighbors whose indices are greater than
		% the current nodes (achieved using the upper triangle of the 
		% adjacency matrix) (this avoids double-drawing an edge)
		neighbors = find(0~=adjTriu(node,:));
		curEdgeCt = length(neighbors);
		% Create x2 and y2 to store neighbors' coords, and create x1 and y1
		% to store equally sized vectors of the current, originating node's
		% coords
		x2 = frameCoords(1,neighbors);
		y2 = frameCoords(2,neighbors);
		x1 = frameCoords(1,node)*ones(1,curEdgeCt);
		y1 = frameCoords(2,node)*ones(1,curEdgeCt);
		% Place the edge coords into frameEdges variable
		frameEdges(:,fEIndxrShift+(1:curEdgeCt)) = [x1;x2;y1;y2];
		% Update the offset indexer. This is used instead of continually
		% changing the size of the matrix as we build to improve speed
		% performance
		fEIndxrShift = fEIndxrShift + curEdgeCt;
	end
end
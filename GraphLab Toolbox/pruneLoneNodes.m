% $Author Brighton Ancelin
% Prunes a graph of all nodes with no attached edges.
% 
% INPUT:
%	graphObj: Graph object input
%
% OUTPUT:
%	graphObjOut: Graph object output, with lone nodes removed
%	numPruned: the number of lone nodes found and subsequently pruned
%
% GRAPH REQUIREMENTS:
%	- Undirected
function [graphObjOut,numPruned] = pruneLoneNodes(graphObj)
	adjMat = adjacency(graphObj); % All entries are either 1 or 0
	% Remove self-edges for further computation
	diaglessMat = adjMat - diag(diag(adjMat));
	% Create mask of nodes that have no connected edges
	rmNodeMask = (0==sum(diaglessMat,1))&(0==sum(diaglessMat,2)');
	% Remove appropriate nodes
	graphObjOut = rmnode(graphObj,find(rmNodeMask));
	% Calculate number of nodes removed
	numPruned = sum(rmNodeMask);
end
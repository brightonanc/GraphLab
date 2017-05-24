% $Author Brighton Ancelin
% Prunes all edges that are loopbacks, or connect a node to itself
%
% INPUT:
%	graphObj: Graph object
%
% OUTPUT:
%	graphObj: Graph object of the pruned graph
%
% GRAPH REQUIREMENTS:
%	- None
function graphObj = pruneLoopbacks(graphObj)
	% Find loopback edges in the adjacency matrix
	rmNodeInds = find(0~=diag(adjacency(graphObj)));
	% Remove edges which are loopbacks
	graphObj = rmedge(graphObj,rmNodeInds,rmNodeInds);
end
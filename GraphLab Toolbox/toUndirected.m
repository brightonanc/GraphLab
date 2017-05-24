% $Author Brighton Ancelin
% Crudely converts a directed graph into an undirected graph by
% substituting undirected edges for any directed edges.
% 
% INPUT:
%	diGraphObj: Digraph object
%
% OUTPUT:
%	unGraphObj: Undirected graph output
%
% GRAPH REQUIREMENTS:
%	- Directed
function unGraphObj = toUndirected(diGraphObj)
	if(~isa(diGraphObj,'digraph'))
		if(isa(diGraphObj,'graph'))
			% If the input was already an undirected graph, just return it
			unGraphObj = diGraphObj;
			return;
		else
			error('Must enter a valid digraph object');
		end
	end
	diAdjMat = adjacency(diGraphObj);
	% Add the directed adjacency matrix to its transpose and remove the
	% duplicated self-edges
	unAdjMat = diAdjMat + diAdjMat.' - diag(diag(diAdjMat));
	unGraphObj = graph(unAdjMat);
end
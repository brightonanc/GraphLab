% $Author Brighton Ancelin
% Returns the nth largest fully connected bin of the input graph. The
% default value of n is 1. If the input graph is directed, a 3rd boolean 
% parameter may be used to specify is the bin must be weakly (true) or
% strongly (false) connected. The default value of this boolean value is
% true.
%
% INPUT:
%	graphObj: Full graph object input
%	n: (Deafult =1) Positive integer largest bin to return
%   isWeaklyConn: (Default =true) Boolean value for specifying connection
%       criteria in directed graphs
%
% OUTPUT:
%	graphObjOut: The graph object of the nth largest bin
%
% GRAPH REQUIREMENTS:
%	- Unweighted
function graphObjOut = getConnectedBin(graphObj,n,isWeaklyConn)
	if(nargin < 2)
		% Default bin is the 1st largest, or the largest
		n = 1;
	end
	% Extract bins based on function parameters
	if(isa(graphObj,'graph'))
		bins = conncomp(graphObj);
	elseif(isa(graphObj,'digraph'))
		if(isWeaklyConn)
			bins = conncomp(graphObj,'Type','weak');
		else
			bins = conncomp(graphObj,'Type','strong');
		end
	end
	% Identfiy the unique bin IDs
	uniqBins = unique(bins);
	% Determine how many nodes fall into each enumerated bin
	binAmt = zeros(1,length(uniqBins));
	for ind=1:length(uniqBins)
		binAmt(ind) = sum(bins==uniqBins(ind));
	end
	[~,ord] = sort(binAmt);
	% Sort the unique bin IDs by quantity of nodes in each bin, greatest to
	% least
	sUniqBins = uniqBins(ord(end:-1:1));
	% Identify and extract the nth largest bin's subgraph
	binNodeMaskVec = bins==sUniqBins(n);
	graphObjOut = subgraph(graphObj,find(binNodeMaskVec));
end
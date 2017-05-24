% $Author Brighton Ancelin
% Cleans a graph based on the cleaning type specified. Default type is
% type = 1.
%
% INPUT:
%	graphObj: Graph object input
%	type: (Default =1) Specified cleaning type (currently only 1 is
%		supported)
%
% OUTPUT:
%	graphObj: Cleaned graph object
%	metadata: Extra data from the cleaning process
%
% EXAMPLES:
%   graphCleaned = cleanGraph(graphOrig,1)
%   ,
%   graphCleaned = cleanGraph(graphOrig)
%
% GRAPH REQUIREMENTS:
%	- Undirected
%	- Unweighted
function [graphObj,metadata] = cleanGraph(graphObj,type)
	if(nargin < 2)
		% Default type = 1
		type = 1;
	end
	switch(type)
		case 1
			% Type 1 is default cleaning
			[graphObj,metadata] = cleanDefault(graphObj);
		otherwise
			% Default cleaning function
			[graphObj,metadata] = cleanDefault(graphObj);
	end
end

% Removes lone nodes and loopback edges. Metadata contains the number of
% lone nodes removed.
function [graphObj,metadata] = cleanDefault(graphObj)
	[graphObj,numPruned] = pruneLoneNodes(graphObj);
	metadata.numPruned = numPruned;
	graphObj = pruneLoopbacks(graphObj);
end
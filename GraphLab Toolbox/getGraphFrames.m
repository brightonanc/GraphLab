% $Author Brighton Ancelin
% Creates a cell array of graph objects, each of which represents an
% amalgam of all edges seen over each duration of timeStride. Every graph 
% will have the same number of nodes, even if adding lone nodes is 
% necessary. This function won't create any more frames than specified by 
% the maxFrames variable.
% 
% Ex:
%	>> edgeMat = [1,5;...
%	           2,9;...
%	           3,4;...
%	           4,5;...
%	           1,5;...
%	           7,8];
%	>> timestampVec = [0,5,10,5,19,25];
%	>> [graphFrames,startEndMat] = getGraphFrames(edgeMat,timestampVec,false,5,4);
%	>> length(graphFrames)
%	ans =
%	     4
%	>> graphFrames{1}.Edges.EndNodes
%	ans =
%	     1     5
% 	>> graphFrames{2}.Edges.EndNodes
% 	ans =
% 		 2     9
% 		 4     5
% 	>> graphFrames{3}.Edges.EndNodes
% 	ans =
% 		 3     4
% 	>> graphFrames{4}.Edges.EndNodes
% 	ans =
% 		 1     5
% 	>> startEndMat
% 	startEndMat =
% 		 0     5
% 		 5    10
% 		10    15
% 		15    20
%		
%
% INPUT:
%	edgeMat: A Nx2 matrix where each row represents an edge, the first
%		column represents the from node, and the second column represents
%		the to node.
%	timestampVec: A Nx1 column vector where each entry corresponds to the
%		timestamp of the associated edge row in edgeMat.
%	isDirected: A boolean value indicating whether or not the edges are
%		directed.
%	timeStride: A scalar quantity representing the amount of time each
%		frame should encompass.
%	maxFrames: The maximum number of frames this function will generate.
%
% OUTPUT:
%	graphFrames: A cell array of graph objects, each of which contains all
%		edges seen over a given period.
%	startEndMat: A Mx2 matrix where each row corresponds to the start and
%		end timestamps of the corresponding graph frame returned in the
%		previous output. The first column represents start times, the
%		second column represents end times.
%
% GRAPH REQUIREMENTS:
%   - None
function [graphFrames,startEndMat] = getGraphFrames(edgeMat,...
		timestampVec,isDirected,timeStride,maxFrames)
	assert(timeStride > 0);
	% Use the min of the timestamps for the first start time
	curStart = min(timestampVec);
	% Get the number of nodes for the overall graph
	nodeCt = max(edgeMat(:));
	startEndMat = [];
	graphFrames = {};
	% Loop until we either exhaust the timestamps or have enough frames
	% generated
	while(~isempty(timestampVec) && length(graphFrames) < maxFrames)
		% Append to the output matrix
		startEndMat = [startEndMat;curStart,curStart+timeStride];
		% Mask the current frame timestamp duration
		frameMask = curStart<=timestampVec & timestampVec<curStart+timeStride;
		% Extract the current frame's edges
		frameEdges = edgeMat(frameMask,:);
		% Delete the current frame data from the overall edgeMat and
		% timestampVec
		edgeMat = edgeMat(~frameMask,:);
		timestampVec = timestampVec(~frameMask);
		% Import the current graph frame
		graphFrame = importNet(frameEdges,isDirected);
		curNodeCt = height(graphFrame.Nodes);
		if(nodeCt > curNodeCt)
			% If the current frame contain all the nodes that the overall
			% graph does, add them in as lone nodes
			graphFrame = addnode(graphFrame,nodeCt-curNodeCt);
		end
		% Append the graph frame to the output cell array
		graphFrames(end+1) = {graphFrame};
		% Increment the curStart variable
		curStart = curStart+timeStride;
	end
end
% $Author Brighton Ancelin
% Exports a GIF of an animated, edge-updating, infection-spread visual. 
% Nodes are layed out based on the architecture of the overall graph (the 
% graph which is an amalgam of all graph frames) and then kept in the same 
% location throughout the entirety of the GIF. Edges are activated and 
% deactivated over time. Active edges are red, and old edges are grey. If 
% edges decay over time, the grey becomes increasingly transparent. Nodes 
% also update over time, with infected nodes being red and healthy nodes 
% being blue.
%
% INPUT:
%	filename: String representing the filename to which the gif will be
%		saved
%	overallGraph: Graph which contains all edges of all graphFrames.
%		Weights are irrelevant.
%	graphFrames: Cell vector of graph objects, each of which is a different
%		graph frame to be rendered. Typically, these frames represent
%		progression through time of the graph, like at a convention.
%	infectionMat: Matrix of infection data. Each column represents a time
%		step, and each row represents a node. A value of 1 represents
%		infected and a value of 0 represents healthy. E.g. 
%		infectionMat(i,j) = 1 means the ith node is infected at time step
%		j.
%			Note: this data is currently generated using Ceyhun's script,
%			which I don't have access to.
%	titles: Cell vector of string titles corresponding to the 
%		aforementioned graph frames. These titles are rendered above each 
%		image.
%	framesPerGraph: Number of frames to render of each graph frame on. 
%		Framerate of the GIF is 30fps, so a value of 30 would equate to 
%		each graph frame remaining active for a full second in the GIF.
%	decayDur: (Optional, default =8) Number of graph frames that must 
%		elpase prior to an old edge becoming invisible. A value of 0 is a 
%		special case, as it will let edges remain visible indefinitely. A 
%		value of 1 means only active edges will be rendered.
%	layout: (Optional, default ='auto') Layout used for placing nodes. 
%		Approved values are those specified by the default MATLAB plot 
%		function: 'auto' (default), 'circle', 'force', 'layered', 
%		'subspace', 'force3', 'subspace3'
%	loopCount: (Optional, default =0) Number of times this GIF should loop.
%		May be any non-negative integer or Inf.
%
% GRAPH REQUIREMENTS:
%   - None
function exportEdgeUpdatingInfectionVisualAnimated(filename,overallGraph,...
		graphFrames,infectionMat,titles,framesPerGraph,decayDur,layout,...
		loopCount)
	if(nargin < 9)
		% Set default loopCount
		loopCount = 0;
		if(nargin < 8)
			% Set default layout
			layout = 'auto';
			if(nargin < 7)
				 % Integer number of graph frames needed to fully decay an 
				 % old edge
				 % If decayDur is less than 1, edges last indefinitely
				decayDur = 8;
			end
		end
	end
	fig = figure;
	h = plot(overallGraph,'Layout',layout);
	if(all(h.ZData==0))
		% If plot is 2D, then extract node xy coords
		nodeCoords = [h.XData;h.YData];
	else
		% If plot is 3D, then extract node xyz coords
		nodeCoords = [h.XData;h.YData;h.ZData];
	end
	% 30 fps GIF
	framesPerSecond = 30;
	delayTime = 1/framesPerSecond;
	nodePairs = overallGraph.Edges.EndNodes.';
	nodePairs = [ones(1,size(nodePairs,2));nodePairs];
	% At this point, nodePairs contains 3 rows. First row is all 1s and
	% will be used to represent whether or not a specific edge has been
	% activated yet. Rows 2 and 3 are used to store edge nodes. Edges are
	% represented by columns. All edges that will ever occur should exist
	% in this matrix.
	firstFrameEdges = graphFrames{1}.Edges.EndNodes.';
	for curEdge = firstFrameEdges
		% Identify the specific index (single edge) where the current edge 
		% lies in the nodePairs matrix
		activeIndMask = (nodePairs(2,:)==curEdge(1))&(nodePairs(3,:)==curEdge(2));
		% Set the current edge to be active (indicated by a 0 in row 1 of
		% nodePairs)
		nodePairs(1,activeIndMask) = 0;
	end
	% Draw edges and get the updated nodePairs matrix (decay values in the 
	% first row are updated)
	nodePairs = drawEdges(nodePairs,nodeCoords,decayDur);
	% Draw nodes at time step and render the current title
	drawNodes(nodeCoords,infectionMat(:,1));
	title(titles{1});
	% Extract image data from the rendered fig, and write the first frame
	% to the gif file. This first frame will also specify parameters such
	% as 'LoopCount' (how many times the GIF should repeat itself) and
	% 'DelayTime' (time between drawing each frame when rendered)
	[A,map] = rgb2ind(frame2im(getframe(fig)),256);
	imwrite(A,map,filename,'gif','LoopCount',loopCount,'DelayTime',delayTime);
	addFramesToGIF(filename,fig,delayTime,framesPerGraph);
	% Iterate through all graph frames
	for ind = 2:length(graphFrames)
		curFrame = graphFrames{ind};
		curFrameEdges = curFrame.Edges.EndNodes.';
		for curEdge = curFrameEdges
			% Identify the specific index (single edge) where the current edge 
			% lies in the nodePairs matrix
			activeIndMask = (nodePairs(2,:)==curEdge(1))&(nodePairs(3,:)==curEdge(2));
			% Set the current edge to be active (indicated by a 0 in row 1 of
			% nodePairs)
			nodePairs(1,activeIndMask) = 0;
		end
		% Draw edges and get the updated nodePairs matrix (decay values in the 
		% first row are updated)
		nodePairs = drawEdges(nodePairs,nodeCoords,decayDur);
		% Draw nodes at time step and render the current title
		drawNodes(nodeCoords,infectionMat(:,ind));
		title(titles{ind});
		% Save the current rendering to the GIF framesPerGraph times
		addFramesToGIF(filename,fig,delayTime,framesPerGraph);
	end
	close(fig);
end

% Wipes screen clean and draws nodes
function drawNodes(nodeCoords,infectionVec)
	% Mask for all infected nodes at the current time step
	infectedNodeMask = 1==infectionVec;
	if(size(nodeCoords,1) < 3)
		% 2D scatter plot the healthy nodes as blue circles
		scatter(nodeCoords(1,~infectedNodeMask),nodeCoords(2,~infectedNodeMask),'b');
		% 2D scatter plot the infected nodes as red circles
		scatter(nodeCoords(1,infectedNodeMask),nodeCoords(2,infectedNodeMask),'r');
	else
		% 3D scatter plot the healthy nodes as blue circles
		scatter3(nodeCoords(1,~infectedNodeMask),nodeCoords(2,~infectedNodeMask),nodeCoords(3,~infectedNodeMask),'b');
		% 3D scatter plot the infected nodes as red circles
		scatter3(nodeCoords(1,infectedNodeMask),nodeCoords(2,infectedNodeMask),nodeCoords(3,infectedNodeMask),'r');
	end
	% Remove the axis for rendering
	axis off;
end

% nodePairs(1,i) = 1: anticipated edges for the frame (haven't seen them 
%	yet, expecting to see them eventually)
% nodePairs(1,i) = 0: active edges for the frame
% nodePairs(1,i) < 0 : old edges for the frame (already seen them, might 
%	become active again though)
function nodePairs = drawEdges(nodePairs,nodeCoords,decayDur)
	clf; % Clears the figure
	% Sort nodePairs' columns by first row values (important for drawing
	% edges in the correct order of old, active, anticipated)
	[~,ord] = sort(nodePairs(1,:));
	nodePairs = nodePairs(:,ord);
	hold on;
	if(size(nodeCoords,1) < 3)
		% 2D plotting functions will be used
		for curPair = nodePairs
			if((-decayDur<curPair(1) || decayDur<1) && curPair(1)<0)
				% If the edge is old (curPair(1)<0) AND (either it's not yet
				% too old to not not be rendered ((-decayDur<curPair(1)) OR
				% edges don't ever expire (decayDur<1))
				% Old edges
				if(decayDur < 1)
					% Default persistent grey color, no transparency/alpha
					% channel
					grey = 0.5*ones(1,3);
				else
					% Continually more transparent grey
					grey = [0.5*ones(1,3),1+(curPair(1)/decayDur)];
				end
				% Draw the edge as a solid grey line
				plot(nodeCoords(1,curPair(2:3)),nodeCoords(2,curPair(2:3)),'-','color',grey);
			elseif(curPair(1) == 0)
				% Active edges
				% Draw the edge as a solid green line
				plot(nodeCoords(1,curPair(2:3)),nodeCoords(2,curPair(2:3)),'-','color',[0,0.5,0]);
			elseif(curPair(1) == 1)
				% Anticipated edges
				%Removed due to a cluttered appearance
			end
		end
	else
		% 3D plotting functions will be used
		for curPair = nodePairs
			if((-decayDur<curPair(1) || decayDur<1) && curPair(1)<0)
				% If the edge is old (curPair(1)<0) AND (either it's not yet
				% too old to not not be rendered ((-decayDur<curPair(1)) OR
				% edges don't ever expire (decayDur<1))
				% Old edges
				if(decayDur < 1)
					% Default persistent grey color, no transparency/alpha
					% channel
					grey = 0.5*ones(1,3);
				else
					% Continually more transparent grey
					grey = [0.5*ones(1,3),1+(curPair(1)/decayDur)];
				end
				% Draw the edge as a solid grey line
				plot(nodeCoords(1,curPair(2:3)),nodeCoords(2,curPair(2:3)),nodeCoords(3,curPair(2:3)),'-','color',grey);
			elseif(curPair(1) == 0)
				% Active edges
				% Draw the edge as a solid green line
				plot3(nodeCoords(1,curPair(2:3)),nodeCoords(2,curPair(2:3)),nodeCoords(3,curPair(2:3)),'-','color',[0,0.5,0]);
			elseif(curPair(1) == 1)
				% Anticipated edges
				%Removed due to a cluttered appearance
			end
		end
	end
	% Create a mask of edges to decrement their expiration counter (first 
	% row of nodePairs). These are all active edges (nodePairs(1,:)==0) and
	% all edges who are old but not yet fully expired 
	% (-decayDur<nodePairs(1,:) & nodePairs(1,:)<0). In the case that edges
	% last indefinitely (decayDur=0), this mask still works to only
	% decrement values to a minimum of -1.
	decrMask = nodePairs(1,:)==0 | (-decayDur<nodePairs(1,:) & nodePairs(1,:)<0);
	% Decrement the masked values
	nodePairs(1,decrMask) = nodePairs(1,decrMask) - 1;
end

function addFramesToGIF(filenameBase,fig,delayTime,quantity)
	% Get image data from the figure
	[A,map] = rgb2ind(frame2im(getframe(fig)),256);
	% Write the image to the GIF quantity times
	for ind=1:quantity
		imwrite(A,map,filenameBase,'gif','WriteMode','append','DelayTime',delayTime);
	end
end
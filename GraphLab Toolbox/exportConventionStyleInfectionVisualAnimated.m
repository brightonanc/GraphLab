% $Author Brighton Ancelin
% Exports a GIF of an animated, convention-style infection-spread visual. Graph frames are
% transitioned through, and nodes smoothly move between graph frames for
% animation. Nodes colors also update over time, with infected nodes being 
% red and healthy nodes being blue. For information regarding the visual 
% architecture of a single frame, See also GETCONVENTIONSTYLEVISUALDATA
%
% INPUT:
%	filename: String representing the filename to which the gif will be
%		saved
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
%		aforementioned graph frames. These titles are rendered above each image.
%	timeBetweenGraphs: Time between each stagnant graph frame rendering, in
%		seconds.
%	soleGraphFrames: Number of frames to render of each stagnant graph
%		frame. Framerate of the GIF is 30fps, so a value of 30 would equate
%		to each stagnant graph frame remaining active for a full second in
%		the GIF.
%	loopCount: (Optional, default =0) Number of times this GIF should loop.
%		May be any non-negative integer or Inf.
%
% GRAPH REQUIREMENTS:
%   - None
function exportConventionStyleInfectionVisualAnimated(filename,...
		graphFrames,infectionMat,titles,timeBetweenGraphs,...
		soleGraphFrames,loopCount)
	if(nargin < 7)
		% Set default loopCount
		loopCount = 0;
	end
	fig = figure;
	% 30 fps GIF
	framesPerSecond = 30;
	delayTime = 1/framesPerSecond;
	intermediateFrameCt = round(framesPerSecond*timeBetweenGraphs)-1-1; % extra -1 for extra pre-edges frame
	% Get drawing coordinates for the nodes and edges
	[prevFrameCoords,firstFrameEdges] = getConventionStyleVisualData(graphFrames{1});
	% Draw nodes and edges, then render the title for the first graph frame
	drawNodes(prevFrameCoords,infectionMat(:,1));
	drawEdges(firstFrameEdges);
	title(titles{1});
	% Extract image data from the rendered fig, and write the first frame
	% to the gif file. This first frame will also specify parameters such
	% as 'LoopCount' (how many times the GIF should repeat itself) and
	% 'DelayTime' (time between drawing each frame when rendered)
	[A,map] = rgb2ind(frame2im(getframe(fig)),256);
	imwrite(A,map,filename,'gif','LoopCount',loopCount,'DelayTime',delayTime);
	addFramesToGIF(filename,fig,delayTime,soleGraphFrames);
	% Iterate through all graph frames
	for ind = 2:length(graphFrames)
		curFrame = graphFrames{ind};
		% Get the current graph frame's drawing coordinate data
		[curFrameCoords,curFrameEdges] = getConventionStyleVisualData(curFrame);
		if(all(prevFrameCoords == curFrameCoords))
			% If the previous graph frame is identical to the current graph
			% frame, simply draw the previous frame as motionless and
			% edgeless and save it intermediateFrameCt times to the GIF.
			% This speeds up the GIF writing process.
			drawNodes(prevFrameCoords,infectionMat(:,ind-1));
			addFramesToGIF(filename,fig,delayTime,intermediateFrameCt);
		else
			% If the previous graph frame is different from the current
			% graph frame, draw intermediate images that show node motion.
			for ind2 = 1:intermediateFrameCt
				% Calculate the inpterpolation between the previous and
				% current graph frames
				interpPerc = ind2/(intermediateFrameCt+1);
				% Interpolate the coordinates of the previous and current
				% graph frames
				subFrameCoords = ((1-interpPerc)*prevFrameCoords) + (interpPerc*curFrameCoords);
				% Draw and save the image of the interpolation to the GIF
				drawNodes(subFrameCoords,infectionMat(:,ind-1));
				addFramesToGIF(filename,fig,delayTime,1);
			end
		end
		% Draw and save a final edgeless image of the current graph frame
		% to the GIF
		drawNodes(curFrameCoords,infectionMat(:,ind));
		addFramesToGIF(filename,fig,delayTime,1);
		% Draw the edges of the current graph frame and render it's title
		drawEdges(curFrameEdges);
		title(titles{ind});
		% Save the stagnant graph frame's image to the GIF soleGraphFrames
		% times
		addFramesToGIF(filename,fig,delayTime,soleGraphFrames);
		% Update the prevFrameCoords variable
		prevFrameCoords = curFrameCoords;
	end
	close(fig);
end

% Wipes screen clean and draws nodes
function drawNodes(frameCoords,infectionVec)
	hold off;
	% Mask for all infected nodes at the current time step
	infectedNodeMask = 1==infectionVec;
	% Scatter plot the healthy nodes as blue circles
	scatter(frameCoords(1,~infectedNodeMask),frameCoords(2,~infectedNodeMask),'b');
	hold on;
	% Scatter plot the infected nodes as red circles
	scatter(frameCoords(1,infectedNodeMask),frameCoords(2,infectedNodeMask),'r');
	% Remove the axis for rendering
	axis off;
	circleResolution = 0.001; % Precision of the outer ring circle
	% Plot draw a blue outer ring for the lone nodes to lay on
	plot(cos(2*pi*(0:circleResolution:1)),sin(2*pi*(0:circleResolution:1)),'b');
end

% Requires hold on
function drawEdges(frameEdges)
	for curEdge = frameEdges
		% Plot draw all edges as solid green lines
		plot(curEdge(1:2),curEdge(3:4),'g-');
	end
end

function addFramesToGIF(filenameBase,fig,delayTime,quantity)
	% Get image data from the figure
	[A,map] = rgb2ind(frame2im(getframe(fig)),256);
	% Write the image to the GIF quantity times
	for ind=1:quantity
		imwrite(A,map,filenameBase,'gif','WriteMode','append','DelayTime',delayTime);
	end
end
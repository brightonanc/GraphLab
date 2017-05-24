% $Author Brighton Ancelin
% Renders an animated, convention-style visual using MATLAB figures. Graph 
% frames are transitioned through, and nodes smoothly move between graph 
% frames for animation. For information regarding the visual architecture 
% of a single frame, See also GETCONVENTIONSTYLEVISUALDATA
%
% INPUT:
%	graphFrames: Cell vector of graph objects, each of which is a different
%		graph frame to be rendered. Typically, these frames represent
%		progression through time of the graph, like at a convention.
%	titles: Cell vector of string titles corresponding to the 
%		aforementioned graph frames. These titles are rendered above each image.
%	timeBetweenGraphs: Time between each stagnant graph frame rendering, in
%		seconds.
%	soleGraphFrames: Number of frames to render of each stagnant graph
%		frame. Framerate of the rendering process is 30fps, so a value of 
%		30 would equate to each stagnant graph frame remaining active for a
%		full second on the figure.
%
% OUTPUT:
%	fig: Figure object of the figure used for rendering
%
% GRAPH REQUIREMENTS:
%   - None
function fig = plotConventionStyleVisualAnimated(graphFrames,titles,timeBetweenGraphs,soleGraphFrames)
	fig = figure;
	% 30 fps rendering
	framesPerSecond = 30;
	delayTime = 1/framesPerSecond;
	intermediateFrameCt = round(framesPerSecond*timeBetweenGraphs)-1-1; % extra -1 for lag prevention
	% Get drawing coordinates for the nodes and edges
	[prevFrameCoords,firstFrameEdges] = getConventionStyleVisualData(graphFrames{1});
	% Draw nodes and edges, then render the title for the first graph frame
	drawNodes(prevFrameCoords);
	pause(delayTime); % Used to prevent lag from the computation-intensive drawing of edges
	drawEdges(firstFrameEdges);
	title(titles{1});
	pause(delayTime*soleGraphFrames);
	for ind = 2:length(graphFrames)
		curFrame = graphFrames{ind};
		% Get the current graph frame's drawing coordinate data
		[curFrameCoords,curFrameEdges] = getConventionStyleVisualData(curFrame);
		for ind2 = 1:intermediateFrameCt
			% Calculate the inpterpolation between the previous and
			% current graph frames
			interpPerc = ind2/(intermediateFrameCt+1);
			% Interpolate the coordinates of the previous and current
			% graph frames
			subFrameCoords = ((1-interpPerc)*prevFrameCoords) + (interpPerc*curFrameCoords);
			% Draw the image of the interpolation to the GIF
			drawNodes(subFrameCoords);
			pause(delayTime);
		end
		% Draw a final edgeless image of the current graph frame
		drawNodes(curFrameCoords);
		pause(delayTime); % Used to prevent lag from the computation-intensive drawing of edges
		% Draw the edges of the current graph frame and render it's title
		drawEdges(curFrameEdges);
		title(titles{ind});
		pause(delayTime*soleGraphFrames);
		% Update the prevFrameCoords variable
		prevFrameCoords = curFrameCoords;
	end
end

% Wipes screen clean and draws nodes and a blue outer ring
function drawNodes(frameCoords)
	hold off;
	% Scatter plot draw all the nodes
	scatter(frameCoords(1,:),frameCoords(2,:));
	% Remove the axis for rendering
	axis off;
	hold on;
	circleResolution = 0.001; % Precision of the outer ring circle
	% Plot draw a blue outer ring for the lone nodes to lay on
	plot(cos(2*pi*(0:circleResolution:1)),sin(2*pi*(0:circleResolution:1)),'b');
end

% Requires hold on
function drawEdges(frameEdges)
	for curEdge = frameEdges
		% Plot draw all edges as red lines
		plot(curEdge(1:2),curEdge(3:4),'r');
	end
end
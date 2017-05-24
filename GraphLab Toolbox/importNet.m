% $Author Brighton Ancelin
% IMPORTNET Returns network data from an edges file
%   graphObj = IMPORTNET(filename,isDirected,varargin) yields a graph object (as
%   specified in graphfun section of the default matlab toolbox) from the 
%   given file. If the parameter isDirected is true, the data returned will
%   be that of a directed graph, unless data in the file itself disagrees.
%
%   Filetypes supported: .net (Pajek) (Unweighted only), .edges/.txt 
%   (SNAP), .netw (Ancelin-Zhang custom format), any simple matrix-style
%   encoded data (instructions for interpretation can be passed through the
%	varargin parameters, explained below)
%
% INPUT:
%	filenameOrMat: Filename of the imported data, or an array of edge and
%       optionally weight data, in one of the following formats:
%       - Matrix of doubles, e.g. [1,2,1;2,3,10]
%       - 1xM Cell array of columns, e.g. {{'text';'is';'ok'},[1;5;4],[7;5;8]}
%       - NxM Cell array of values, e.g. {'text',1,7;'is',5,5;'ok',4,8}
%	isDirected: Scalar logical specifying if the imported data should be
%	    interpreted as a directed graph
%	varargin: Key-Value Pairs for several other parameters, namely:
%		- 'nodeCols': Length 2 integer vector representing the columns in 
%           the file where the node data exists. The first element of the 
%           vector represents node from, and the second element of the 
%           vector represents node to.
%		- 'weightCol': Integer representing the column in the file where
%		    the edge weight data exists
%		- 'dupMode': String that specifies how duplicate edge entries will
%			be handled. Possible values are:
%			- 'first' (default): Only the first appearance of a unique edge
%				will be implemented in the graph. Will only return a
%				weighted graph if the raw data was interpreted with weight.
%				- Returns: Unweighted or Weighted
%			- 'ignore': Only unique edges will be implemented in the graph,
%				and all weights will be removed/ignored. Works identically
%				to 'first' when raw data is unweighted. 
%				- Returns: Unweighted
%			- 'sum': Duplicate edges will merge into a single unique edge,
%				and all constituent weights will be summed to yield the
%				weight of this unique edge. In the case of an unweighted
%				graph, an implicit edge weight of 1 is assumed for each
%				edge entry.
%				- Returns: Weighted
%			- 'average': Duplicate edges will merge into a single unique 
%				edge, and all constituent weights will be averaged to yield
%				the weight of this unique edge. In the case of an 
%				unweighted graph, an implicit edge weight of 1 is assumed 
%				for each edge entry.
%				- Returns: Weighted
%
% OUTPUT:
%	graphObj: Imported graph object
%
% GRAPH REQUIREMENTS:
%   - None
function graphObj = importNet(filenameOrMat,isDirected,varargin)
	% Parse the varargin and create a metadata struct
	metadata = parseVarargin(varargin);
	if(ischar(filenameOrMat))
		% Filename was given
		filename = filenameOrMat;
		[~,extension] = strtok(filename,'.');
		switch(lower(extension))
			case '.net' 
				% Pajek file
				[edges,isDirected] = rawImportFiletypeNet(filename,isDirected);
				weights = [];
			case '.edges'
				% .edges (Matrix-style) file
				[edges,weights] = rawImportFiletypeDefault(filename,isDirected,metadata);
			case '.txt'
				% .txt (Matrix-style) file
				[edges,weights] = rawImportFiletypeDefault(filename,isDirected,metadata);
			case '.netw'
				% .netw file
				if(nargin > 1)
					disp('.NETW file detected. Second parameter (isDirected) ignored');
				end
				fid = fopen(filename);
				switch(lower(fgetl(fid)))
					case 'directed'
						isDirected = true;
					case 'undirected'
						isDirected = false;
					otherwise
						error('File needs a directed/undirected statement as line 1');
				end
				[edges,weights] = rawImportFiletypeDefault(filename,isDirected,struct('dotnetw',true));
			otherwise
				[edges,weights] = rawImportFiletypeDefault(filename,isDirected,metadata);
		end
	else
		% Matrix was given
		mat = filenameOrMat;
		if(isnumeric(mat))
			% Convert the matrix into a cell array of its columns
			colCt = size(mat,2);
			rawColumns = num2cell(zeros(1,colCt));
			for ind = 1:colCt
				% Input columns into the rawColumns cell array
				rawColumns(ind) = {mat(:,ind)};
			end
		elseif(iscell(mat))
			if(size(mat,1) == 1)
				% If matrix is already in cell array of its columns form
				rawColumns = mat;
			else
				% Convert the matrix into a cell array of its columns
				colCt = size(mat,2);
				rawColumns = num2cell(zeros(1,colCt));
				for ind = 1:colCt
					if(isnumeric(mat{1,ind}))
						% If data is numeric, input as column vector
						curCol = [mat{:,ind}].';
					else
						% If data is not numeric (char, e.g.), input as is
						curCol = mat(:,ind);
					end
					% Input columns into the rawColumns cell array
					rawColumns(ind) = {curCol};
				end
			end
		else
			error('Unknown matrix input format');
		end
		% At this point, rawColumns will contain a row-vector cell array
		% where each element is a column vector of data
		[edges,weights] = importFromCellColumns(rawColumns,isDirected,metadata);
	end
	% Format to MATLAB-friendly 1-based indexing
	if(any(0 == edges(:)))
		edges = edges + 1;
	end
	% Check for invalid node indices (should NEVER happen)
	if(any(1 > edges(:)))
		[matLineNums,col] = find(1>edgeMatrix);
		badLineNum = lineSkipCt + matLineNums(1);
		badNode = edgeMatrix(matLineNums(1),col(1));
		error(['Invalid (negative) node indices found in file. Please review\n',...
				'First occurence:\nLine %d:\nNode Index:%d'],badLineNum,badNode);
	end
	% Create final graphs
	if(isDirected)
		graphObj = digraph(edges(:,1),edges(:,2),weights);
	else
		graphObj = graph(edges(:,1),edges(:,2),weights);
	end
end

function m = parseVarargin(v)
	% Metadata struct
	m = struct();
	for argInd = 1:2:length(v)
		codeword = v{argInd};
		if(argInd+1 > length(v))
			% If there is no parameter associated with the current 
			% codeword, break
			break;
		end
		param = v{argInd+1};
		if(~ischar(codeword))
			% If codeword is not a string (invalid)
			error('Invalid variable argument input term %d class: %s',argInd,class(codeword));
		else
			switch(codeword)
				case 'nodeCols'
					% Specifies which columns have node IDs of edges
					if(~isnumeric(param))
						% Must be numeric indices
						error('Invalid variable argument input term %d class: %s',argInd+1,class(param));
					elseif(2 ~= length(param(:)))
						% Need two node ID edge columns, no more, no less
						error('Invalid variable argument input element size: %d',length(param(:)));
					else
						% Input node columns field
						m.nodeCols = [param(1),param(2)];
					end
				case 'weightCol'
					% Specifies which column has weight values of edges
					if(~isnumeric(param))
						% Must be a numeric index
						error('Invalid variable argument input term %d class: %s',argInd+1,class(param));
					elseif(1 ~= length(param(:)))
						% Need one weight column, no more, no less
						error('Invalid variable argument input element size: %d',length(param(:)));
					else
						% Input weight column field
						m.weightCol = param;
					end
				case 'dupMode'
					if(~ischar(param))
						% Must be string
						error('Invalid variable argument input term %d class: %s',argInd+1,class(param));
					else
						% Input duplicate mode field
						m.dupMode = param;
					end
			end
		end
	end
end

function [edges,weights] = rawImportFiletypeDefault(filename,isDirected,metadata)
	if(nargin < 3)
		% If no metadata was specified, create an empty struct to avoid
		% NPEs
		metadata = struct();
	end
	if(isfield(metadata,'nodeCols'))
		% Metadata-specified node ID columns
		nodeCols = metadata.nodeCols;
	else
		% Default node ID columns
		nodeCols = [1,2];
	end
	if(isfield(metadata,'weightCol'))
		% Metadata-specified weight column
		weightCol = metadata.weightCol;
	else
		if(isfield(metadata,'dotnetw') && metadata.dotnetw)
			% Metadata-specified weight column
			weightCol = 3;
		else
			% Default weight column
			weightCol = [];
		end
	end
	% Build a format string for use with function textscan
	formatBase = 's'.*ones(1,max([nodeCols,weightCol]));
	formatBase([nodeCols,weightCol]) = 'd';
	formatTail = '%'.*ones(1,2*20); % Arbitrarily chose 20
	formatTail(2:2:end) = 's';
	format = '%'.*ones(1,2*length(formatBase));
	format(2:2:end) = formatBase;
	% flag indicates if the format string is sufficiently long for the file
	flag = false;
	while(~flag)
		% textscan will fill excess columns with empty character arrays,
		% therefore by continuously adding a tail of 20 '%s's to format, I
		% should quickly read any input file
		format = [format,formatTail];
		fid = fopen(filename,'r');
		% Scan file for columns of data
		rawColumns = textscan(fid,char(format),'Delimiter',{',',' ',sprintf('\t')});
		fclose(fid);
		flag = isempty(rawColumns{end}{1}); % If this throws an error, you probably forgot to remove the header text from your file
	end
	[edges,weights] = importFromCellColumns(rawColumns,isDirected,metadata);
end

function [edges,weights] = importFromCellColumns(rawColumns,isDirected,metadata)
	if(nargin < 3)
		% If no metadata was specified, create an empty struct to avoid
		% NPEs
		metadata = struct();
	end
	if(isfield(metadata,'nodeCols'))
		% Metadata-specified node ID columns
		nodeCols = metadata.nodeCols;
	else
		% Default node ID columns
		nodeCols = [1,2];
	end
	if(isfield(metadata,'weightCol'))
		% Metadata-specified weight column
		weightCol = metadata.weightCol;
	else
		if(isfield(metadata,'dotnetw') && metadata.dotnetw)
			% Metadata-specified weight column
			weightCol = 3;
		else
			% Default weight column
			weightCol = [];
		end
	end
	
	nodeFrom = rawColumns{nodeCols(1)};
	nodeTo = rawColumns{nodeCols(2)};
	weight = [];
	if(~isempty(weightCol))
		% If a weight column is specified
		weight = rawColumns{weightCol};
		if(all(0 == weight))
			% Weight values must be nonzero
			disp('No weights detected');
			% Reset weight column to nonexistent
			weight = [];
		end
	end
	% Duplicate edge handling --------------------------------------------
	if(~isfield(metadata,'dupMode'))
		% Default duplicate edge handling
		metadata.dupMode = 'first';
	end
	switch(metadata.dupMode)
		case 'ignore'
			% Duplicate entries are erased. Unweighted graph returned
			weight = [];
			if(isDirected)
				% Obtain unique edges only, direction matters
				% Ignore any duplicate edges by only keeping the unique
				% ones
				cleanEdgeMatrix = unique([nodeFrom,nodeTo],'rows','stable');
			else
				% Construct edge matrix that only lists edges where nodeTo
				% is greater than or equal to nodeFrom. This is because
				% direction doesn't matter in undirected graphs
				dirtyEdgeMatrix = zeros(2*size(nodeFrom,1),2);
				% Input from-to edges
				dirtyEdgeMatrix(1:2:end,:) = [nodeFrom,nodeTo];
				% Input to-from edges
				dirtyEdgeMatrix(2:2:end,:) = [nodeTo,nodeFrom];
				% Only from<=to edges will be kept
				validEdgeMask = dirtyEdgeMatrix(:,1) <= dirtyEdgeMatrix(:,2);
				% Keep only from<=to edges
				dirtyEdgeMatrix = dirtyEdgeMatrix(validEdgeMask,:);
				% Ignore any duplicate edges by only keeping the unique
				% ones
				cleanEdgeMatrix = unique(dirtyEdgeMatrix,'rows','stable');
			end
			nodeFrom = cleanEdgeMatrix(:,1);
			nodeTo = cleanEdgeMatrix(:,2);
		case 'sum'
			% Duplicate entries have weights summed. Weighted graph
			% returned
			if(isempty(weight))
				% Default weights assigned
				weight = ones(length(nodeFrom),1);
			end
			if(isDirected)
				[cleanEdgeMatrix,ia,ic] = unique([nodeFrom,nodeTo],'rows','stable');
				ia_missing = 1:length(nodeFrom);
				ia_missing(ia) = [];
				% ia_missing now contains only indexes of duplicate edges
				% Write unique edges' weights to weightNew
				weightNew = weight(ia);
				for ind = (ia_missing(:)).'
					% For all duplicate edges, we identify their copies'
					% index (ic(ind)) and then use that to index the new
					% weights vector (weightNew). We then sum the known
					% weights together, and re-enter the data into the new 
					% weights vector
					weightNew(ic(ind)) = weightNew(ic(ind)) + weight(ind);
				end
			else
				dirtyEdgeMatrix = zeros(2*size(nodeFrom,1),2);
				dirtyEdgeMatrix(1:2:end,:) = [nodeFrom,nodeTo];
				dirtyEdgeMatrix(2:2:end,:) = [nodeTo,nodeFrom];
				weightP = zeros(2*size(nodeFrom,1),1);
				weightP(1:2:end,:) = weight;
				weightP(2:2:end,:) = weight;
				% At this point, dirtyEdgeMatrix and weightP contain 
				% corresponding rows of edges and edge weights
				% Only from<=to edges and weights will be kept
				validEdgeMask = dirtyEdgeMatrix(:,1) <= dirtyEdgeMatrix(:,2);
				% Keep only from<=to edges and weights
				dirtyEdgeMatrix = dirtyEdgeMatrix(validEdgeMask,:);
				weightP = weightP(validEdgeMask);
				[cleanEdgeMatrix,ia,ic] = unique(dirtyEdgeMatrix,'rows','stable');
				ia_missing = 1:length(nodeFrom);
				ia_missing(ia) = [];
				% ia_missing now contains only indexes of duplicate edges
				% Write unique edges' weights to weightNew
				weightNew = weightP(ia);
				for ind = (ia_missing(:)).'
					% For all duplicate edges, we identify their copies'
					% index (ic(ind)) and then use that to index the new
					% weights vector (weightNew). We then sum the known
					% weights together, and re-enter the data into the new 
					% weights vector
					weightNew(ic(ind)) = weightNew(ic(ind)) + weight(ind);
				end
				selfEdgeMask = cleanEdgeMatrix(:,1)==cleanEdgeMatrix(:,2);
				% Fix the double-counting of self-edge weights in
				% undirected processing
				weightNew(selfEdgeMask) = weightNew(selfEdgeMask)./2;
			end
			nodeFrom = cleanEdgeMatrix(:,1);
			nodeTo = cleanEdgeMatrix(:,2);
			weight = weightNew;
		case 'average'
			% Duplicate entries have weights averaged. Weighted graph
			% returned
			if(isempty(weight))
				% Default weights assigned
				weight = ones(length(nodeFrom),1);
			end
			if(isDirected)
				[cleanEdgeMatrix,ia,ic] = unique([nodeFrom,nodeTo],'rows','stable');
				ia_missing = 1:length(nodeFrom);
				ia_missing(ia) = [];
				% ia_missing now contains only indexes of duplicate edges
				% Write unique edges' weights to weightNew
				weightNew = weight(ia);
				% Construct blockInd, which holds all kept edges' 
				% weightNew indices in the first row, and corresponding
				% duplicate edges' weight indices in the second row
				blockInd = [ic(ia_missing(:))';(ia_missing(:))'];
				[~,ord] = sort(blockInd(1,:));
				blockInd = blockInd(:,ord);
				% At this point, blockInd columns are sorted by order of 
				% increasing first row values
				% Do the first step of the upcoming loop to preset
				% variables prevIndB1 and elemadd2
				weightNew(blockInd(1,1)) = weightNew(blockInd(1,1)) + weight(blockInd(2,1));
				prevIndB1 = blockInd(1,1);
				elemadd = 1+1; % Original weightNew weight + first duplicate weight
				for indB = blockInd(:,2:end)
					if(prevIndB1 ~= indB(1))
						% If we've finished summing all duplicate edges for
						% the edge specified by the weightNew index
						% prevIndB1, we need to average the weight by
						% dividing the sum of all weights by the number of
						% elements summed (this is where the elemadd
						% variable is used)
						weightNew(prevIndB1) = weightNew(prevIndB1)./elemadd;
						% Reset the elemadd variable for the subsequent
						% edges' weight summing
						elemadd = 1;
					end
					% Continue summing the weights of all duplicate edges
					weightNew(indB(1)) = weightNew(indB(1)) + weight(indB(2));
					% Set the previous weightNew index used
					prevIndB1 = indB(1);
					% Add 1 to the number of elements summed
					elemadd = elemadd + 1;
				end
			else
				dirtyEdgeMatrix = zeros(2*size(nodeFrom,1),2);
				dirtyEdgeMatrix(1:2:end,:) = [nodeFrom,nodeTo];
				dirtyEdgeMatrix(2:2:end,:) = [nodeTo,nodeFrom];
				weightP = zeros(2*size(nodeFrom,1),1);
				weightP(1:2:end,:) = weight;
				weightP(2:2:end,:) = weight;
				% At this point, dirtyEdgeMatrix and weightP contain 
				% corresponding rows of edges and edge weights
				% Only from<=to edges and weights will be kept
				validEdgeMask = dirtyEdgeMatrix(:,1) <= dirtyEdgeMatrix(:,2);
				% Keep only from<=to edges and weights
				dirtyEdgeMatrix = dirtyEdgeMatrix(validEdgeMask,:);
				weightP = weightP(validEdgeMask);
				[cleanEdgeMatrix,ia,ic] = unique(dirtyEdgeMatrix,'rows','stable');
				ia_missing = 1:length(nodeFrom);
				ia_missing(ia) = [];
				% ia_missing now contains only indexes of duplicate edges
				% Write unique edges' weights to weightNew
				weightNew = weightP(ia);
				% Construct blockInd, which holds all kept edges' 
				% weightNew indices in the first row, and corresponding
				% duplicate edges' weight indices in the second row
				blockInd = [ic(ia_missing(:))';(ia_missing(:))'];
				[~,ord] = sort(blockInd(1,:));
				blockInd = blockInd(:,ord);
				% At this point, blockInd columns are sorted by order of 
				% increasing first row values
				% Do the first step of the upcoming loop to preset
				% variables prevIndB1 and elemadd2
				weightNew(blockInd(1,1)) = weightNew(blockInd(1,1)) + weight(blockInd(2,1));
				prevIndB1 = blockInd(1,1);
				elemadd = 1+1; % Original weightNew weight + first duplicate weight
				for indB = blockInd(:,2:end)
					if(prevIndB1 ~= indB(1))
						% If we've finished summing all duplicate edges for
						% the edge specified by the weightNew index
						% prevIndB1, we need to average the weight by
						% dividing the sum of all weights by the number of
						% elements summed (this is where the elemadd
						% variable is used)
						weightNew(prevIndB1) = weightNew(prevIndB1)./elemadd;
						% Reset the elemadd variable for the subsequent
						% edges' weight summing
						elemadd = 1;
					end
					% Continue summing the weights of all duplicate edges
					weightNew(indB(1)) = weightNew(indB(1)) + weight(indB(2));
					% Set the previous weightNew index used
					prevIndB1 = indB(1);
					% Add 1 to the number of elements summed
					elemadd = elemadd + 1;
				end
				% Final averaging step
				weightNew(prevIndB1) = weightNew(prevIndB1)./elemadd;
				selfEdgeMask = cleanEdgeMatrix(:,1)==cleanEdgeMatrix(:,2);
				% Fix the double-counting of self-edge weights in
				% undirected processing
				weightNew(selfEdgeMask) = weightNew(selfEdgeMask)./2;
			end
			nodeFrom = cleanEdgeMatrix(:,1);
			nodeTo = cleanEdgeMatrix(:,2);
			weight = weightNew;
		case 'first'
			% Only the first entry of a duplicate entry series is used,
			% the rest discarded. Unweighted or weighted graph returned
			if(isDirected)
				% Extract unique edges (first one selected)
				[cleanEdgeMatrix,ia,~] = unique([nodeFrom,nodeTo],'rows','stable');
				if(~isempty(weight))
					% If weights were given, extract the edges' associated
					% weights
					weight = weight(ia);
				end
			else
				% Construct edge matrix that only lists edges where nodeTo
				% is greater than or equal to nodeFrom. This is because
				% direction doesn't matter in undirected graphs
				dirtyEdgeMatrix = zeros(2*size(nodeFrom,1),2);
				% Input from-to edges
				dirtyEdgeMatrix(1:2:end,:) = [nodeFrom,nodeTo];
				% Input to-from edges
				dirtyEdgeMatrix(2:2:end,:) = [nodeTo,nodeFrom];
				if(~isempty(weight))
					% If weights are given, build a corresponding weight
					% vector
					weightP = zeros(2*size(nodeFrom,1),1);
					weightP(1:2:end,:) = weight;
					weightP(2:2:end,:) = weight;
				end
				validEdgeMask = dirtyEdgeMatrix(:,1) <= dirtyEdgeMatrix(:,2);
				% Keep only from<=to edges
				dirtyEdgeMatrix = dirtyEdgeMatrix(validEdgeMask,:);
				if(~isempty(weight))
					% If weights are given, keep the corresponding weights
					weightP = weightP(validEdgeMask);
				end
				% Extract unique edges (first one selected)
				[cleanEdgeMatrix,ia,~] = unique(dirtyEdgeMatrix,'rows','stable');
				if(~isempty(weight))
					% If weights are given, keep the corresponding weights
					weight = weightP(ia);
				end
			end
			nodeFrom = cleanEdgeMatrix(:,1);
			nodeTo = cleanEdgeMatrix(:,2);
		otherwise
			% Default handling is 'first'
			% Only the first entry of a duplicate entry series is used,
			% the rest discarded. Unweighted or weighted graph returned
			if(isDirected)
				% Extract unique edges (first one selected)
				[cleanEdgeMatrix,ia,~] = unique([nodeFrom,nodeTo],'rows','stable');
				if(~isempty(weight))
					% If weights were given, extract the edges' associated
					% weights
					weight = weight(ia);
				end
			else
				% Construct edge matrix that only lists edges where nodeTo
				% is greater than or equal to nodeFrom. This is because
				% direction doesn't matter in undirected graphs
				dirtyEdgeMatrix = zeros(2*size(nodeFrom,1),2);
				% Input from-to edges
				dirtyEdgeMatrix(1:2:end,:) = [nodeFrom,nodeTo];
				% Input to-from edges
				dirtyEdgeMatrix(2:2:end,:) = [nodeTo,nodeFrom];
				if(~isempty(weight))
					% If weights are given, build a corresponding weight
					% vector
					weightP = zeros(2*size(nodeFrom,1),1);
					weightP(1:2:end,:) = weight;
					weightP(2:2:end,:) = weight;
				end
				validEdgeMask = dirtyEdgeMatrix(:,1) <= dirtyEdgeMatrix(:,2);
				% Keep only from<=to edges
				dirtyEdgeMatrix = dirtyEdgeMatrix(validEdgeMask,:);
				if(~isempty(weight))
					% If weights are given, keep the corresponding weights
					weightP = weightP(validEdgeMask);
				end
				% Extract unique edges (first one selected)
				[cleanEdgeMatrix,ia,~] = unique(dirtyEdgeMatrix,'rows','stable');
				if(~isempty(weight))
					% If weights are given, keep the corresponding weights
					weight = weightP(ia);
				end
			end
			nodeFrom = cleanEdgeMatrix(:,1);
			nodeTo = cleanEdgeMatrix(:,2);
	end
	edges = [nodeFrom,nodeTo];
	weights = weight;
end

% This function is imperfect in its current state.
% Can not handle any Pajek file, only those with one block of edges
% and one block of arcs, max. Unweighted graphs only
function [rawArcOrEdgeMatrix,isDirected] = rawImportFiletypeNet(filename,isDirected)
	fid = fopen(filename,'r');
	% 1s-bit means read to matrix
	% 2s-bit means read arc data
	% 4s bit means read edge data
	readMode = uint8(0);
	% Undirected edges are called 'arcs' in Pajek
	arcCells = {};
	% Directed edges are called 'edges' in Pajek
	edgeCells = {};
	line = 'NOT REAL LINE';
	while(ischar(line))
		line = fgetl(fid);
		% Remove leading and trailing whitespace
		trimmedLine = strtrim(line);
		rawMatrix = [];
		% Iterate through all lines in the block
		while((trimmedLine(1)~='*') && ischar(line))
			% If the current block needs to be read as edge/arc data
			if(bitand(readMode,1) ~= 0)
				% Tokenize line
				tokens = strsplit(trimmedLine);
				if(isnan(str2double(tokens{1})))
					tokens = tokens(2:end);
				end
				tokInd = 1;
				tokMax = length(tokens);
				lineArr = [];
				% && needed to short-circuit the evaluation and prevent
				% IndexOutOfBounds-style exceptions
				while(tokMax >= tokInd && ~isnan(str2double(tokens{tokInd})))
					% Convert the line into an array of all elements in the
					% line
					lineArr(tokInd) = str2double(tokens{tokInd});
					tokInd = tokInd + 1;
				end
				% Ensure miswritten file data won't cause issues
				if(isempty(rawMatrix) || size(rawMatrix,2) == length(lineArr))
					% Add edge/arc to the matrix
					rawMatrix = [rawMatrix;lineArr];
				else
					error('Arc input dimension mismatch');
				end
			end
			line = fgetl(fid);
			if(ischar(line))
				trimmedLine = strtrim(line);
			end
		end
		% If previously read block was arc data
		if(bitand(readMode,2))
			arcCells{end+1} = rawMatrix;
		elseif(bitand(readMode,4)) % If previously read block was edge data
			edgeCells{end+1} = rawMatrix;
		end
		% Re-asserting the terminating condition of the loop here to avoid 
		% an error in the next line
		if(~ischar(line))
			break;
		end
		% Tokenize current block label
		[token1,otherTokens] = strtok(trimmedLine);
		switch(lower(token1))
			case '*network'
				% If current block is type 'network' (network label)
				% Irrelevant to our work
				readMode = 0;
			case '*vertices'
				% If current block is type 'vertices' (vertex labels)
				readMode = 0;
				vertexCt = str2double(otherTokens);
				if(isnan(vertexCt))
					fprintf('Miswritten vertex count? ''%s''',otherTokens);
				end
			case '*arcs'
				% If current block is type 'arcs' (undirected edge data)
				readMode = 3;
			case '*edges'
				% If current block is type 'edges' (directed edge data)
				readMode = 5;
			case '*partition'
				% If current block is type 'partition' (partition label)
				% Irrelevant to our work
				readMode = 0;
			otherwise
				fprintf('Unknown Pajek section %s',token1);
				readMode = 0;
		end
	end
	fclose(fid);
	if(isempty(edgeCells) && ~isempty(arcCells))
		% If arc (undirected edge) data was read
		rawArcOrEdgeMatrix = arcCells{1}; % TODO more robust handling than grab 1st index
		if(isDirected)
			isDirected = false;
			disp('Input file was an undirected graph');
		end
	elseif(isempty(arcCells) && ~isempty(edgeCells))
		% If directed edge data was read
		rawArcOrEdgeMatrix = edgeCells{1}; % TODO more robust handling than grab 1st index
		if(~isDirected)
			isDirected = true;
			disp('Input file was a directed graph');
		end
	elseif(isempty(arcCells) && isempty(edgeCells))
		% If no data was read
		rawArcOrEdgeMatrix = [];
		% Above asssignment isn't really necessary due to the subsequent
		% error thrown, but in case the error block goes away I don't want
		% to forget to ensure the matrix is blank
		error('No edge data in file');
	else
		% Ceyhun and Keith said to ignore this issue for time right now
		error('Cannot have both arcs and edges in current implementation. Please remove one');
	end
end
% $Author Brighton Ancelin
% Exports a new file that is identical to the input, however all node IDs
% in the original file have been replaced with the smallest integer values
% possible. This is particularly useful for files where node IDs may be
% large integers natively, such as IP or MAC addresses.
%
% INPUT:
%	filename: String representing the filename of the input file
%	nodeCols: A length-2 vector with each value representing a column where
%       node IDs are stored, 1-indexed
%
% EXAMPLES:
%   exportCompressedNodeIDs('graphdata.txt',[2,3])
function exportCompressedNodeIDs(filename,nodeCols)
    % Build a formatString to use with textscan
	formatBase = 's'.*ones(1,max(nodeCols));
	formatBase(nodeCols) = 'd';
	formatTail = '%'.*ones(1,40); % Arbitrarily chose 40
	formatTail(2:2:end) = 's';
	format = '%'.*ones(1,2*length(formatBase));
	format(2:2:end) = formatBase;
	flag = false;
	while(~flag)
		% textscan will fill excess columns with empty character arrays,
		% therefore by continuously adding a tail of 20 '%s's to format, I
		% should quickly read any input file
		format = [format,formatTail];
		fid = fopen(filename,'r');
		rawColumns = textscan(fid,char(format),'Delimiter',{',',' ',sprintf('\t')});
		fclose(fid);
		flag = isempty(rawColumns{end}{1}); % If this throws an error, you probably forgot to remove the header text from your file
	end
	% Extract node IDs
	fromIDs = rawColumns{nodeCols(1)};
	toIDs = rawColumns{nodeCols(2)};
	% Use the indexing output from unique as ordinal integer alias IDs
	% starting with 1
	[~,~,aliasIDs] = unique([fromIDs;toIDs]);
	% Split the vector back into its from and to halves
	fromAliases = aliasIDs(1:(end/2));
	toAliases = aliasIDs(((end/2)+1):end);
	% Rewrite the rawColumns variable with new alias IDs
	rawColumns{nodeCols(1)} = fromAliases;
	rawColumns{nodeCols(2)} = toAliases;
	[p1,p2] = strtok(filename,'.');
	rawCol2 = cell.empty([size(fromAliases,1),0]);
	for ind=1:size(rawColumns,2)
		if(isnumeric(rawColumns{1,ind}))
			rawCol2 = [rawCol2,num2cell(rawColumns{1,ind})];
		elseif(size(rawCol2,1) == size(rawColumns{1,ind},1))
			rawCol2 = [rawCol2,rawColumns{1,ind}];
		elseif(isempty(rawColumns{1,ind}{1}))
			rawCol2(:,end+1) = {''};
		else
			error('A column was not filled on the last line. Please fix the last line of the file and try again');
		end
	end
	% Create and export the newly generated file
	fid = fopen([p1,'_Compressed',p2],'w');
	formatWrite = reshape([format(1:2:end);format(2:2:end);' '.*ones(1,0.5*length(format))],1,[]);
	for curRow = 1:size(rawCol2,1)
		str = sprintf(char(formatWrite),rawCol2{curRow,:});
		fprintf(fid,[deblank(str),'\n']);
	end
	fclose(fid);
end
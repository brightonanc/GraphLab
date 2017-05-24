% $Author Brighton Ancelin
% Exports a graph to .NETW file format, a format defined by Brighton
% Ancelin and Adam Zhang for undergraduate research in the Weitz Group.
% This format has since been deprecated, due to the fact that these files
% did not accomodate diverse graph data well.
% 
% INPUT:
%	graphObj: Graph object to be exported. graph or digraph types work
%	filenameBase: Filename desired, without the file extension. In cases
%		where the desire filename is already in the directory, a new one
%		will be made with a number added in the name.
%
% GRAPH REQUIREMENTS:
%	- Unweighted
function exportToNetwFile(graphObj,filenameBase)
	% Writes file header (either 'Directed' or 'Undirected')
	if(isa(graphObj,'digraph'))
		head = 'Directed\n';
	elseif(isa(graphObj,'graph'))
		head = 'Undirected\n';
	else
		error('Need a valid graph parameter');
	end
	% Create a file for writing
	[fid,filename] = fcreateAndOpen([filenameBase,'.netw']); % If the extension is changed, importNet code will need updating on how to identify this filetype
	fprintf(fid,'NETW File Format, specified by Brighton Ancelin and Adam Zhang for their undergraduate research work');
	% Print the header
	fprintf(fid,head);
	fclose(fid);
	% Write the adjacency matrix in 'fromNode toNode' format
	dlmwrite(filename,graphObj.Edges.EndNodes,'-append','delimiter',' ');
end
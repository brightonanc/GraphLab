% $Author Brighton Ancelin
% Exports the metrics of a graph to a .METR file, a format defined by
% Brighton Ancelin and Adam Zhang for undergraduate research in the Weitz
% Group
% 
% INPUT:
%	graphObj: Graph object to be analyzed
%	netName: Name of the graph/network as it will be written in the metrics
%		file. Case sensitive.
%	filenameBase: Filename desired, without the file extension. In cases
%		where the desire filename is already in the directory, a new one
%		will be made with a number added in the name.
%
% OUTPUT:
%   metrics: Metrics structure of the input graph
%
% GRAPH REQUIREMENTS:
%	- None
function metrics = exportMetricsFile(graphObj,netName,filenameBase)
	% Generate metrics from input graph object
	metrics = getGraphMetrics(graphObj);
	[fid,filename] = fcreateAndOpen([filenameBase,'.txt']);
	fprintf(fid,'Metrics for %s:\n\n',netName);
	% Print all scalar metrics
	if(metrics.isFullyConn)
		fprintf(fid,'Fully Connected\n');
	else
		fprintf(fid,'Not Fully Connected\n');
	end
	if(metrics.isDirected)
		fprintf(fid,'Directed\n');
	else
		fprintf(fid,'Undirected\n');
	end
	fprintf(fid,'Node Count:                     %d\n',metrics.nodeCt);
	fprintf(fid,'Edge Count:                     %d\n',metrics.edgeCt);
	fprintf(fid,'Average Path Length:            %0.4f\n',metrics.avgPathLength);
	fprintf(fid,'Graph Diameter:                 %d\n',metrics.diameter);
	if(~metrics.isDirected)
		fprintf(fid,'Average Clustering Coefficient: %0.4f\n',metrics.avgClustering);
	end
	fprintf(fid,'Maximum Eigenvalue:             %0.4f\n',metrics.maxEigenvalue);
	fprintf(fid,'\n');
	% Print various centrality ratings for each node
	fprintf(fid,'NodeID,EigenCentrality,DegreeCentrality,ClosenessCentrality\n');
	fclose(fid);
	aspects = [(1:metrics.nodeCt).',metrics.eigenCentralities,metrics.degreeCentralities,metrics.closenessCentralities];
	dlmwrite(filename,full(aspects),'-append','delimiter',',');
end
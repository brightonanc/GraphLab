% $Author Brighton Ancelin
% Import graph
exampleGraphObj = importNet('exampleData_Compressed.csv',false,'nodeCols',[2,3]);
% Extract and clean graph
exampleGraphObj = cleanGraph(getConnectedBin(exampleGraphObj));
% Export metrics and visuals
exportStandardGraphFiles(exampleGraphObj,'example','Example Network');
% Remove the graph object from the workspace
clear exampleGraphObj;

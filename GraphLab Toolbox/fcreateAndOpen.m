% $Author Brighton Ancelin
% Creates and opens a new file, without overwriting any older files. Adds
% numbers to the base name if other similarly named files exist. For
% example, if the directory contains
%	filething.txt
%	filething (1).txt
%	filething (2).txt
% then the file that will be opened will be named
%	filething (3).txt
% 
% INPUT:
%	filename: Filename desired, with the file extension included.
%
% OUTPUT:
%	fid: file ID of newly created file
%	filenameOpen: the filename of the file opened;
function [fid,filenameOpen] = fcreateAndOpen(filename)
	% Break filename into name and extension
	[filenameBase,extension] = strtok(filename,'.');
	filename2 = [filenameBase,extension];
	ind = 1;
	% Check if the original input filename is available; if not, iterate
	% through the integers until an available filename is discovered
	while(0 ~= exist(filename2,'file'))
		filename2 = [filenameBase,' (',num2str(ind),')',extension];
		ind = ind + 1;
	end
	% Open the file, and return the fid and final filename
	fid = fopen(filename2,'w');
	filenameOpen = filename2;
end
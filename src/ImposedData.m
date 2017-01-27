function [tagDex, dsDex] = ImposedData(address)
% IMPOSEDDATA Find the available scoped Gotos and Data Stores that are higher in the
%	hierarchy and are to be in the signature.
%
%   Inputs:
%		address     Simulink model name.
%
%   Outputs:
%       tagDex		Names of Gotos in scope in scope of the system.
%       dsDex		Names of Data Store Memorys in scope of the system.

    tagDex  = {};
    dsDex   = {};

    % Get blocks that are above this system
	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);

    for z = 1:length(allBlocks)
		BlockType = get_param(allBlocks{z}, 'BlockType');

		% Get names of Data Stores and Gotos
        if strcmp(BlockType, 'DataStoreMemory')
			dsDex{end + 1} = get_param(allBlocks{z}, 'DataStoreName');
        elseif strcmp(BlockType, 'GotoTagVisibility')
            tagDex{end + 1} = get_param(allBlocks{z}, 'GotoTag');
        end
    end
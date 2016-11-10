function [tagDex, dsDex] = ImposedData(address)
% IMPOSEDDATA Get the imposed component of the signature.
%
%   Inports:
%		address     Simulink system path.
%
%   Outports:
%       tagDex
%       dsDex

    tagDex  = {};
    dsDex   = {};
    
	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);
    
	for z = 1:length(allBlocks)
		BlockType = get_param(allBlocks{z}, 'BlockType');
        if strcmp(BlockType, 'DataStoreMemory')
			dsDex{end + 1} = get_param(allBlocks{z}, 'DataStoreName');
        elseif strcmp(BlockType, 'GotoTagVisibility')
            tagDex{end + 1} = get_param(allBlocks{z}, 'GotoTag');
        end
	end



function [blockPath, isTag] = getBlockPath(sys, blockID, blockType)
% GETBLOCKPATH Find the full path of the block in system sys with 
% block type blockType, and a name of blockID.
%   Note: For blocks with a tag parameter such as GotoTag or DataStoreName,
%   blockID is assumed to be that tag (any block with this tag is accepted)
%
% Also returns isTags as true if the block had a tag parameter such as 
% GotoTag or DataStoreName.

isTag = true;
switch blockType
    case 'Goto'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'Goto', 'GotoTag', blockID);
        getBlock;
    case 'From'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'From', 'GotoTag', blockID);
        getBlock;
    case 'GotoTagVisibility'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'GotoTagVisibility', 'GotoTag', blockID);
        getBlock;
    case 'DataStoreRead'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreRead', 'DataStoreName', blockID);
        getBlock;
    case 'DataStoreWrite'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreWrite', 'DataStoreName', blockID);
        getBlock;
    case 'DataStoreMemory'
        blockPath = find_system(sys, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreMemory', 'DataStoreName', blockID);
        getBlock;
    otherwise
        % Get block path
        % Could have also done: block = [address '/' blockID];
        blockPath = find_system(sys, 'SearchDepth', 1, 'Name', blockID);
        blockPath = blockPath{1};
        isTag = false;
end

    function getBlock
        if ~isempty(blockPath)
            blockPath = blockPath{1};
        else
            error('Error. \nThere should be at least one %s in the %s system.', blockType, sys);
        end
    end
end
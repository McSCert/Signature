function [blockPath, isTag] = getBlockPath(sys, blockID, blockType)
% GETBLOCKPATH Find the full path of a block in system sys with
%   block type blockType, and a name of blockID.
%
%   Inputs:
%       sys         Simulink model name or path.
%       blockID     The block name, or GotoTag for Goto/Froms, or
%                   DataStoreName for Data Store blocks.
%       blockType   The block type.
%
%   Outputs:
%       blockPath   Block name (including path) of the block with the given
%                   blockID and blockType within sys, returns '' if block
%                   not found.
%       isTag       Logical, true if the block had a tag parameter, such as
%                   GotoTag or DataStoreName, else false.

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
            % Could have also done: block = [sys '/' blockID];
            blockPath = find_system(sys, 'SearchDepth', 1, 'Name', blockID);
            getBlock;
            isTag = false;
    end

    function getBlock
        if ~isempty(blockPath)
            blockPath = blockPath{1};
        else
            blockPath = '';
%             error('Error. \nThere should be at least one %s in the %s system.', blockType, sys); %Not the case for WeakSignature
        end
    end
end
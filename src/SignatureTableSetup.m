function [table, title] = SignatureTableSetup(system, dataTypeMap, getUnit, tableType, signatures, index)

%Set title
switch tableType
    case 'Inports'
        title = 'Inports';
        blockType = 'Inport';
    case 'Outports'
        title = 'Outports';
        blockType = 'Outport';
    case 'GlobalFroms'
        title = 'Global Froms';
        blockType = 'From';
    case 'GlobalGotos'
        title = 'Global Gotos';
        blockType = 'Goto';
    case 'ScopedFromTags'
        title = 'Scoped Froms';
        blockType = 'From';
    case 'ScopedGotoTags'
        title = 'Scoped Gotos';
        blockType = 'Goto';
    case 'DataStoreReads'
        title = 'Data Store Reads';
        blockType = 'DataStoreRead';
    case 'DataStoreWrites'
        title = 'Data Store Writes';
        blockType = 'DataStoreWrite';
    case 'Updates'
        title = 'Updates';
        blockType = 'DataStoreRead'; %Assumes updates can only occur with data stores
    case 'GotoTagVisibilities';
        title = 'Goto Tag Declarations';
        blockType = 'GotoTagVisibility';
    case 'DataStoreMemories'
        title = 'Data Store Declarations';
        blockType = 'DataStoreMemory';
    otherwise
        error(['Error. \n', ...
            'The input tableType was invalid. \n', ...
            'Valid options are: ', ...
            '''Inports'', ''Outports'', ''GlobalFroms'', ''GlobalGotos'', ', ...
            '''ScopedFromTags'', ''ScopedGotoTags'', ''DataStoreReads'', ', ...
            '''DataStoreWrites'', ''Updates'', ''GotoTagVisibilities'', ', ...
            '''DataStoreMemories''']);
end

%Set table header
tableHeader = [{'Name'}, {'Unit'}, {'Min'}, {'Max'}, {'Data Type'}, {'Description'}];
table = tableHeader;

blocks = eval(['signatures{' int2str(index) '}.' tableType]);

%Fill the table with information about the blocks
for i = 1:length(blocks)
    [block, ~] = getBlockPath(system, blocks{i}, blockType);
    table = [table; findBlockInfo(block, blocks{i}, dataTypeMap, getUnit)];
end
end

function blockInfo = findBlockInfo(block, name, dataTypeMap, getUnit)
%blockInfo is given in the following form [{'Name'}, {'Unit'}, {'Min'}, {'Max'}, {'Data Type'}, {'Description'}]; 
%   where each char is replaced with an appropriate value for the block

%Find appropriate values for the row entries
name = strrep({name}, sprintf('\n'), ' ');
unit = getUnit(block);
try
    min = get_param(block, 'OutMin');
    max = get_param(block, 'OutMax');
catch
    min = {'N/A'};
    max = {'N/A'};
end

%TODO mapDataTypes.m needs to be improved to find a type for every block 
try
    datatype = dataTypeMap(char(block));
catch
    datatype = {''};
end

description = {get_param(block, 'Description')};
% if strcmp(description,'')
%     description = {'N/A'};
% end

%Set ith row entries
blockInfo = [name, unit, min, max, datatype, description];
end

%%%Though this is not needed here, it may be useful for other parts of the signature tool
% function blocks = findBlocks(system,blockType)
% %Find the blocks to fill the table
% 
% if strcmp(blockType,'SubSystem')
%     blocks=find_system(system, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'BlockType', blockType, 'MaskType', '');
%     if ~strcmp(system,bdroot)
%         blocks=blocks(2:end);
%     end
% elseif strcmp(blockType,'Goto')
%     blocks=find_system(system, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'BlockType', blockType, 'MaskType', '');
%     
%     % Exclude local gotos
%     blocks=blocks(~strcmp(get_param(blocks,'TagVisibility'),'local'));
% elseif strcmp(blockType,'From')
%     blocks=find_system(system, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'BlockType', blockType, 'MaskType', '');
%     
%     % Exclude froms at the same level, in the same subsystem, as their corresponding goto
%     gotos=find_system(system, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'BlockType', 'Goto', 'MaskType', '');
%     for i = 1:length(gotos)
%         % if any from has the same goto tag as the current goto, then it isn't needed for the interface (as the source is from within)
%         blocks=blocks(~strcmp(get_param(blocks,'GotoTag'),get_param(gotos{i},'GotoTag')));
%     end
%     
%     % Exclude local froms
%     blocks=blocks(~strcmp(get_param(blocks,'TagVisibility'),'local'));
% else
%     blocks=find_system(system, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'BlockType', blockType);
% end
% end
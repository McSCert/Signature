% Note: These functions are used in Signature.rpt
function [table, title] = SignatureTableSetup(system, dataTypeMap, getUnit, ...
    tableType, signatures, index)
% SIGNATURETABLESETUP Create and fill tables in the report.

    % Set title
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
            blockType = 'DataStoreRead'; % Assumes updates can only occur with data stores
        case 'GotoTagVisibilities'
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

    % Set table header
    tableHeader = [{'Name'}, {'Data Type'}, {'Min'}, {'Max'}, {'Unit'}, {'Description'}];
    table = tableHeader;

    blocks = eval(['signatures{' int2str(index) '}.' tableType]);

    % Fill the table with information about the blocks
    for i = 1:length(blocks)
        [block, ~] = getBlockPath(system, blocks{i}, blockType);
        table = [table; findBlockInfo(block, blocks{i}, dataTypeMap, getUnit)];
    end
end

function blockInfo = findBlockInfo(block, name, dataTypeMap, getUnit)
% BLOCKINFO Produce block information in the form:
%    [{'Name'}, {'Data Type'}, {'Min'}, {'Max'}, {'Unit'}, {'Description'}];
% where each char is replaced with an appropriate value for the block

    % Find appropriate values for the row entries
    name = strrep({name}, sprintf('\n'), ' ');
    try
        unit = getUnit(block);
    catch
        unit = {'N/A'};
    end

    try
        min = get_param(block, 'OutMin');
        max = get_param(block, 'OutMax');
    catch
        min = {'N/A'};
        max = {'N/A'};
    end

    % TODO mapDataTypes.m needs to be improved to find a type for every block
    try
        datatype = dataTypeMap(char(block));
    catch
        datatype = {'N/A'};
    end

    try
        description = {get_param(block, 'Description')};
        if strcmp(description,'')
            description = {'N/A'};
        end
    catch
        description = {'N/A'};
    end

    % Set ith row entries
    blockInfo = [name, datatype, min, max, unit, description];
end
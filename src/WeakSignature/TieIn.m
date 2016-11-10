function TieIn(address, num, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd,...
    dataStoreReadAdd, globalFroms, globalGotos, hasUpdates)
%  TIEIN Ties in all the files responsible for signature extraction
%  
%	Inputs:
%       address         Simulink system path.
%
%		scopeGotoAdd    List of scoped Goto Tags that need to be added to the
%                       signature.
%
%		scopeFromAdd    Scoped From Tags to be added to the signature.
%
%		DataStoreAdd    List of Data Store Tags to be added to the
%                       signature.
%
%		num             Zero if not be recursed, one for recursed.
%
%       dataStoreWriteAdd List of data store reads to be added to the signature.
%
%		globalGotos     Tags of global gotos to be added in recursion.
%
%       hasUpdates      Boolean indicating whether updates are included in the 
%                       signature.
%
%   Outputs:
%       N/A
%
%	The function first calls InportSig and OutportSig which add and 
%	connect the appropriate blocks for the inport and outport,
%	according to the Signature format. If in the appropriate level, it
%	also calls FindGlobals which outputs the globalGotos in the model.
%	addDataStoreGoto adds the appropriate scoped Gotos and dataStores
%	to the level.
%
%   Example:
%       TieIn('ESSR', 0, {}, {})

    % Constants: 
    FONT_SIZE = 14; % Heading font size
    Y_OFFSET = 25;  % Vertical offset in pixels for spacing signature elements
    
    % Get signature for Inports and Outports 
    [inAddress, InportGoto, InportFrom, Inports, inGotoLength] = InportSig(address);
    [outAddress, OutportGoto, OutportFrom, Outports, outGotoLength] = OutportSig(address);

    % Add global Gotos
    if num == 0
        globalGotos = FindGlobals(address);
        globalGotos = unique(globalGotos);
        globalFroms = globalGotos;
    end

    removableGotos = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    removableGotosNames = {};
    for i = 1:length(removableGotos)
        removableGotosNames{end + 1} = get_param(removableGotos{i}, 'GotoTag');
    end
    globalGotosx = setdiff(globalGotos, removableGotosNames);

    [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, ...
        updateBlocks] = ...
        AddImplicits(address, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, hasUpdates);

    gotoLength = 10;

    % Add Inports
    verticalOffset = RepositionInportSig(inAddress, InportGoto, InportFrom, Inports, gotoLength);
    add_block('built-in/Note', [address '/Inputs'], 'Position', [90 10], 'FontSize', FONT_SIZE);
    verticalOffset = verticalOffset + Y_OFFSET;

    % Add Data Store Reads
    if ~isempty(dataStoreReads(~cellfun('isempty', dataStoreReads)))
        add_block('built-in/Note', [address '/Data Store Reads'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, dataStoreReads, gotoLength, 1);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add scoped Froms
    if ~isempty(fromBlocks(~cellfun('isempty', fromBlocks)))
        add_block('built-in/Note', [address '/Scoped Froms'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, fromBlocks, gotoLength, 1);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add global Froms
    if ~isempty(globalFroms(~cellfun('isempty', globalFroms)))
        add_block('built-in/Note', [address '/Global Froms'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = AddGlobals(address, verticalOffset, globalFroms, gotoLength, 0);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add updates (if enabled)
    if hasUpdates && ~isempty(updateBlocks(~cellfun('isempty', updateBlocks)))
        add_block('built-in/Note', [address '/Updates'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, updateBlocks, gotoLength, 0);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add Outports
    if ~isempty(Outports(~cellfun('isempty', Outports)))
        add_block('built-in/Note', [address '/Outputs'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionOutportSig(outAddress, OutportGoto, OutportFrom, Outports, gotoLength, verticalOffset);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add Data Store Writes
    if ~isempty(dataStoreWrites(~cellfun('isempty', dataStoreWrites)))
        add_block('built-in/Note', [address '/Data Store Writes'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, dataStoreWrites, gotoLength, 0);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add scoped Gotos
    if ~isempty(gotoBlocks(~cellfun('isempty', gotoBlocks)))
        add_block('built-in/Note', [address '/Scoped Gotos'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, gotoBlocks, gotoLength, 0);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add global Gotos
    if ~isempty(globalGotosx(~cellfun('isempty', globalGotosx)))
        add_block('built-in/Note', [address '/Global Gotos'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = AddGlobals(address, verticalOffset, globalGotosx, gotoLength, 1);
        verticalOffset = verticalOffset + Y_OFFSET;
    end

    % Add Data Store declarations (i.e. Memory blocks)
    dataDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    tagDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    if ~isempty(dataDex(~cellfun('isempty', dataDex))) || ~isempty(tagDex(~cellfun('isempty', tagDex)))
        add_block('built-in/Note', [address '/Declarations'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = MoveDataStoreDex(address, verticalOffset);
    end

    % Get all blocks, but remove the current address
    allBlocks = find_system(address, 'SearchDepth', 1);
    allBlocks = setdiff(allBlocks, address);
    
    % For every block
    for z = 1:length(allBlocks)
        % If it is a subsystem
        if strcmp(get_param(allBlocks{z}, 'BlockType'), 'SubSystem')  
            % Recurse into the subsystem
            if strcmp(get_param(allBlocks{z}, 'IsSubsystemVirtual'), 'on')
                TieIn(allBlocks{z}, 1, carryUp{2}, carryUp{1}, carryUp{4}, carryUp{3}, globalFroms, globalGotosx, hasUpdates);
            else
                TieIn(allBlocks{z}, 1, {}, {}, carryUp{4}, carryUp{3}, {}, {}, hasUpdates);
            end
        end
    end
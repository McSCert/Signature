function TieIn(address, num, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd,...
    dataStoreReadAdd, globalFroms, globalGotos, hasUpdates, sys)
%  TIEIN Find the weak signature recursively and insert it into the model. 
%  
%	Inputs:
%       address             Simulink model name.
%
%       num                 Zero if not be recursed, one for recursed.
%
%		scopeGotoAdd        List of scoped Goto Tags that need to be added 
%                           to the signature.
%
%		scopeFromAdd        List of Scoped From Tags to be added to the signature.
%
%		dataStoreWriteAdd   List of Data Store Writes to be added to the
%                           signature.
%
%       dataStoreReadAdd    List of Data Store Reads to be added to the 
%                           signature.
%
%       globalFroms         Tags of global Froms to be added in recursion.
%
%		globalGotos         Tags of global Gotos to be added in recursion.
%
%       hasUpdates          Number indicating whether reads and writes in the same
%                           same subsystem are kept separate (0), or combined 
%                           and listed as an update (1).
%
%       sys                 Name of the system to generate the documentation
%                           for. It can be a specific subsystem name, or 'All'
%                           to get documentation for the entire hierarchy.
%
%   Outputs:
%       N/A

    % Constants: 
    FONT_SIZE = getSignatureConfig('heading_size', 14); % Heading font size
    Y_OFFSET = 25;  % Vertical spacing between signature sections
    
    verticalOffset = 30;
    gotoLength = 15;
    addSignatureAtThisLevel = strcmp(sys, 'All') || strcmp(sys, address);
    
    % Get signature for Inports
    Inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    % Get signature for Outports
    Outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');
    
    if addSignatureAtThisLevel
        
        % Move all blocks to make room for the Signature
        moveAll(address, 300, 0);

        % Add blocks to model
        add_block('built-in/Note', [address '/Inputs'], 'Position', [90 10], 'FontSize', FONT_SIZE);
        [InportGoto, InportFrom, inGotoLength] = InportSig(address, Inports);
        [OutportGoto, OutportFrom, outGotoLength] = OutportSig(address, Outports);
        
        % Organize blocks
        gotoLength = max([inGotoLength outGotoLength]);
        if gotoLength == 0
            gotoLength = 15;
        end
        verticalOffset = RepositionInportSig(address, InportGoto, InportFrom, Inports, gotoLength);
        verticalOffset = verticalOffset + Y_OFFSET;
    else
        InportGoto = {};
        OutportGoto = {};        
    end
    
    % If at the appropriate level, include the global Gotos
    if num == 0
        globalGotos = unique(FindGlobals(address));
        globalFroms = globalGotos;
    end
    
    % Find the implicit interface
    [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, ...
        updateBlocks] = AddImplicits(address, scopeGotoAdd, scopeFromAdd, ...
        dataStoreWriteAdd, dataStoreReadAdd, hasUpdates, sys);

    removableGotos = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    removableGotosNames = {};
    for i = 1:length(removableGotos)
        removableGotosNames{end + 1} = get_param(removableGotos{i}, 'GotoTag');
    end
    globalGotosx = setdiff(globalGotos, removableGotosNames);
    
    if addSignatureAtThisLevel

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
            verticalOffset = RepositionOutportSig(address, OutportGoto, OutportFrom, Outports, gotoLength, verticalOffset);
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
            add_block('built-in/Note', [address '/Declarations'], ...
                'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = MoveDataStoreDex(address, verticalOffset);
        end
    end

    % Recurse into other subsystems
    subsystems = find_system(address, 'SearchDepth', 1, 'BlockType', 'SubSystem');
    subsystems = setdiff(subsystems, address);
    for z = 1:length(subsystems)
        if strcmp(get_param(subsystems{z}, 'IsSubsystemVirtual'), 'on')
            TieIn(subsystems{z}, 1, carryUp{2}, carryUp{1}, carryUp{4}, ...
                carryUp{3}, globalFroms, globalGotosx, hasUpdates, sys);
        else
            % Atomic subsystems (i.e. non-virtual) are handled differently
            % because Goto/Froms can't cross their boundaries
            TieIn(subsystems{z}, 1, {}, {}, carryUp{4}, ...
                carryUp{3}, {}, {}, hasUpdates, sys);
        end
    end
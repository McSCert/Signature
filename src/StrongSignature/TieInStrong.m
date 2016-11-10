function [scopedGotoAddOut, dataStoreWriteAddOut, dataStoreReadAddOut ...
    scopedFromAddOut, globalGotosAddOut, globalFromsAddOut] = ...
    TieInStrong(address, hasUpdates, sys)
% TIEINSTRONG Find the strong signature recursively and insert it into the model. 
%
%   Function:
%       TIEINSTRONG(address, hasUpdates, sys)
%
%   Inputs:
%       address     Simulink system path.
%
%       hasUpdates  Boolean indicating whether updates are included in the 
%                   signature.
%
%       sys         Name of the system to generate the documentation for. 
%                   One can use a specific system name, or use 'All' to get 
%                   documentation of the entire hierarchy.
%
%   Outputs:
%       scopedGotoAddOut        List of scoped gotos that the function will pass out.
%       dataStoreWriteAddOut    List of data store writes that the function will pass out.
%       dataStoreReadAddOut     List of data store reads that the function will pass out.
%       scopedFromAddOut        List of scoped froms that the function will pass out.
%       globalGotosAddOut       List of global gotos being passed out.
%       globalFromsAddOut       List of global froms being passed out.
    
    % Constants: 
    FONT_SIZE = 14; % Heading font size
    Y_OFFSET = 25;  % Vertical offset in pixels for spacing signature elements
    
    % Elements in the signature being carried up from the signatures of lower levels
	sGa     = {};   % Scoped Gotos
	sFa     = {};   % Scoped Froms
	dSWa    = {};   % Data Store Writes
    dSRa    = {};   % Data Store Reads
    gGa     = {};   % Global Gotos
    gFa     = {};   % Global Froms
    
    % 1a) Add Inports
    [inAddress, InportGoto, InportFrom, Inports, inGotoLength] = InportSig(address);
    
    % Add Outports now, to get gotoLength. Resposition Outport blocks later
    % because they come later in the signature model format
    [outAddress, OutportGoto, OutportFrom, Outports, outGotoLength] = OutportSig(address); 
    gotoLength = max([inGotoLength outGotoLength]);
    if gotoLength == 0
        gotoLength = 15;
    end

    % 1b) Move/format Inport blocks
    verticalOffset = RepositionInportSig(inAddress, InportGoto, InportFrom, Inports, gotoLength); 
    add_block('built-in/Note', [address '/Inputs'], 'Position', [90 30], 'FontSize', FONT_SIZE);
    
    % Get all blocks, but remove the current address
    allBlocks = find_system(address, 'SearchDepth', 1); 
    allBlocks = setdiff(allBlocks, address);
    
    % For every block
    for z = 1:length(allBlocks)
        % If it is a subsystem
        if strcmp(get_param(allBlocks{z}, 'BlockType'), 'SubSystem')
            
            % Disable link
            if strcmp(get_param(allBlocks{z}, 'LinkStatus'), 'resolved')
                set_param(allBlocks{z}, 'LinkStatus', 'inactive');
            end
            
            % Recurse into the subsystem
            [scopedGotoAddOutx, dataStoreWriteAddOutx, dataStoreReadAddOutx, ...
                scopedFromAddOutx, globalGotosAddOutx, globalFromsAddOutx] = ...
                TieInStrong(allBlocks{z}, hasUpdates, sys); 
            
            % Append blocks found in subsystem
            sGa     = [sGa scopedGotoAddOutx];
            sFa     = [sFa scopedFromAddOutx];
            dSWa    = [dSWa dataStoreWriteAddOutx];
            dSRa    = [dSRa dataStoreReadAddOutx];
            gGa     = [gGa globalGotosAddOutx];
            gFa     = [gFa globalFromsAddOutx];
        end
    end
    
    % Remove duplicates
    sGa     = unique(sGa);
    sFa     = unique(sFa);
    dSWa    = unique(dSWa);
    dSRa    = unique(dSRa);
    gGa     = unique(gGa);
    gFa     = unique(gFa);

    % Get ports and names
    inputPorts      = {};
    outputPorts     = {};
    inputPortsTags  = {};
    outputPortsTags = {};

    for k = 1:length(Inports)
        inputPorts{end + 1} = get_param(Inports{k}, 'Name');
    end

    for l = 1:length(Outports)
        outputPorts{end + 1} = get_param(Outports{l}, 'Name');
    end
    
    for i = 1:length(InportGoto)
        inputPortsTags{end + 1} = get_param(InportGoto{i}, 'GotoTag');
    end

    for j = 1:length(OutportGoto)
        outputPortsTags{end + 1} = get_param(OutportGoto{j}, 'GotoTag');
    end
    
    portTags = [inputPortsTags outputPortsTags];

    % Find implicit interface
    [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, ...
        updateBlocks, globalFroms, globalGotos] = ...
        AddImplicitsStrong(address, sGa, sFa, dSWa, dSRa, gGa, gFa, portTags, hasUpdates);

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
        verticalOffset = RepositionImplicits(verticalOffset, globalFroms, gotoLength, 0);
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
    if ~isempty(globalGotos(~cellfun('isempty', globalGotos)))
        add_block('built-in/Note', [address '/Global Gotos'], 'Position', [90 verticalOffset + 20], 'FontSize', FONT_SIZE);
        verticalOffset = verticalOffset + Y_OFFSET;
        verticalOffset = RepositionImplicits(verticalOffset, globalGotos, gotoLength, 1);
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

    % Set output information
    scopedFromAddOut    = carryUp{1};
    scopedGotoAddOut    = carryUp{4};
    dataStoreReadAddOut	= carryUp{2};
    dataStoreWriteAddOut = carryUp{3};
    globalFromsAddOut   = carryUp{5};
    globalGotosAddOut   = carryUp{6};
end
function [scopedGotoAddOut, dataStoreWriteAddOut, dataStoreReadAddOut ...
    scopedFromAddOut, globalGotosAddOut, globalFromsAddOut] = ...
    TieInStrong(address, hasUpdates, sys)
% TIEINSTRONG Find the strong signature recursively and insert it into the model. 
%
%   Function:
%       TIEINSTRONG(address, hasUpdates, sys)
%
%   Inputs:
%       address
%       hasUpdates  Boolean indicating whether updates are included in the signature.
%       sys
%
%   Outputs:
%       scopedGotoAddOut    List of scoped gotos that the function will pass out.
%       dataStoreWriteAddOut List of data store writes that the function will pass out.
%       dataStoreReadAddOut List of data store reads that the function will pass out.
%       scopedFromAddOut    List of scoped froms that the function will pass out.
%       globalGotos         List of global gotos being passed in.
%       gGotoLength         Length of the global goto blocks being added.
    
    % Elements in the signature being carried up from the signatures of lower levels
	sGa     = {};   % Scoped Gotos
	sFa     = {};   % Scoped Froms
	dSWa    = {};   % Data Store Writes
    dSRa    = {};   % Data Store Reads
    gGa     = {};   % Global Gotos
    gFa     = {};   % Global Froms
    
    % Get info on inports and outports
    [inAddress, InportGoto, InportFrom, Inports, inGotoLength] = InportSig(address);
    [outAddress, OutportGoto, OutportFrom, Outports, outGotoLength] = OutportSig(address); 

    headingSize = 14; % For headings
    gotoLength = max([inGotoLength outGotoLength]);

    % Move the inputs into proper position
    verticalOffset = RepositionInportSig(inAddress, InportGoto, InportFrom, Inports, gotoLength); 
    
    % Add header
    add_block('built-in/Note', [address '/Inputs'], 'Position', [90 30], 'FontSize', headingSize);
    
    % Get all blocks, but remove the current address
    allBlocks = find_system(address, 'SearchDepth', 1); 
    allBlocks = setdiff(allBlocks, address);
    
    % For every block
    for z = 1:length(allBlocks)
        if strcmp(get_param(allBlocks{z}, 'BlockType'), 'SubSystem') % If it is a subsystem
            if strcmp(get_param(allBlocks{z}, 'LinkStatus'), 'resolved')
                set_param(allBlocks{z}, 'LinkStatus', 'inactive');
            end
            
            % Recurse
            [scopedGotoAddOutx, dataStoreWriteAddOutx, dataStoreReadAddOutx, ...
                scopedFromAddOutx, globalGotosAddOutx, globalFromsAddOutx] = ...
                TieInStrong(allBlocks{z}, hasUpdates, sys); 
            
            % Append blocks found in subsystems
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

    % verticalOffset is a value of the vertical offset between each block
    % added to the model. The Reposition functions are called to Reposition
    % their respective blocks, which pass in the current vertical position,
    % and pass out the vertical position after adding blocks.
    verticalOffset = verticalOffset + 25;
    
    if gotoLength == 0
        gotoLength = 15;
    end
    
    % Add data store reads
    if ~isempty(dataStoreReads(~cellfun('isempty', dataStoreReads)))
        add_block('built-in/Note', [address '/Data Store Reads'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, dataStoreReads, gotoLength, 1);
        verticalOffset = verticalOffset + 25;
    end

    % Add scoped froms
    if ~isempty(fromBlocks(~cellfun('isempty', fromBlocks)))
        add_block('built-in/Note', [address '/Scoped Froms'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, fromBlocks, gotoLength, 1);
        verticalOffset = verticalOffset + 25;
    end

    % Add global froms
    if ~isempty(globalFroms(~cellfun('isempty', globalFroms)))
        add_block('built-in/Note', [address '/Global Froms'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, globalFroms, gotoLength, 0);
        verticalOffset = verticalOffset + 25;
    end

    % Add updates, if enabled
    if hasUpdates && ~isempty(updateBlocks(~cellfun('isempty', updateBlocks)))
        add_block('built-in/Note', [address '/Updates'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, updateBlocks, gotoLength, 0);
        verticalOffset = verticalOffset + 25;
    end

    % Add outports
    if ~isempty(Outports(~cellfun('isempty', Outports)))
        add_block('built-in/Note', [address '/Outputs'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionOutportSig(outAddress, OutportGoto, OutportFrom, Outports, gotoLength, verticalOffset);
        verticalOffset = verticalOffset + 25;
    end

    % Add data store writes
    if ~isempty(dataStoreWrites(~cellfun('isempty', dataStoreWrites)))
        add_block('built-in/Note', [address '/Data Store Writes'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, dataStoreWrites, gotoLength, 0);
        verticalOffset = verticalOffset + 25;
    end

    % Add scoped gotos
    if ~isempty(gotoBlocks(~cellfun('isempty', gotoBlocks)))
        add_block('built-in/Note',[address '/Scoped Gotos'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, gotoBlocks, gotoLength, 0);
        verticalOffset = verticalOffset + 25;
    end

    % Add global gotos
    if ~isempty(globalGotos(~cellfun('isempty', globalGotos)))
        add_block('built-in/Note', [address '/Global Gotos'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = RepositionImplicits(verticalOffset, globalGotos, gotoLength, 1);
        verticalOffset = verticalOffset + 25;
    end

    % Add data store declarations
    dataDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    tagDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    if ~isempty(dataDex(~cellfun('isempty', dataDex))) || ~isempty(tagDex(~cellfun('isempty', tagDex)))
        add_block('built-in/Note',[address '/Declarations'], 'Position', [90 verticalOffset + 20], 'FontSize', headingSize);
        verticalOffset = verticalOffset + 25;
        verticalOffset = MoveDataStoreDex(address, verticalOffset);
    end

    % Set information to be passed out
    scopedFromAddOut    = carryUp{1};
    scopedGotoAddOut    = carryUp{4};
    dataStoreReadAddOut	= carryUp{2};
    dataStoreWriteAddOut = carryUp{3};
    globalFromsAddOut   = carryUp{5};
    globalGotosAddOut   = carryUp{6};
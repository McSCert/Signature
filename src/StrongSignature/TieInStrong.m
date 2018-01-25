function [scopedGotoAddOut, dataStoreWriteAddOut, dataStoreReadAddOut ...
    scopedFromAddOut, globalGotosAddOut, globalFromsAddOut] = ...
    TieInStrong(address, hasUpdates, sys)
% TIEINSTRONG Find the strong signature recursively and insert it into the model.
%
%   Inputs:
%       address     Simulink model name or path.
%
%       hasUpdates  Number indicating whether reads and writes in the same
%                   subsystem are kept separate(0), or combined and listed as
%                   an update(1).
%
%       sys         Name of the system to generate the documentation for.
%                   It can be a specific subsystem name, or 'All' to get
%                   documentation for the entire hierarchy.
%
%   Outputs:
%       scopedGotoAddOut        List of scoped gotos that the function will pass out.
%       dataStoreWriteAddOut    List of data store writes that the function will pass out.
%       dataStoreReadAddOut     List of data store reads that the function will pass out.
%       scopedFromAddOut        List of scoped froms that the function will pass out.
%       globalGotosAddOut       List of global gotos being passed out.
%       globalFromsAddOut       List of global froms being passed out.

    % Constants:
    FONT_SIZE = getSignatureConfig('heading_size', 12); % Heading font size
    FONT_SIZE_LARGER = str2num(FONT_SIZE) + 2;
    X_OFFSET_HEADING = 75;
    Y_OFFSET = 25;  % Vertical spacing between signature sections

    % Elements in the signature being carried up from the signatures of lower levels
    sGa     = {};   % Scoped Gotos
    sFa     = {};   % Scoped Froms
    dSWa    = {};   % Data Store Writes
    dSRa    = {};   % Data Store Reads
    gGa     = {};   % Global Gotos
    gFa     = {};   % Global Froms

    % Defining containers for moving blocks over
    dontMoveNote = {};
    dontMoveBlocks = [];

    % Get signature for Inports
    Inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    % Get signature for Outports
    Outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');

    verticalOffset = 30;
    gotoLength = 15;

    addSignatureAtThisLevel = strcmp(sys, 'All') || strcmp(sys, address);

    InportGoto = {};
    OutportGoto = {};
    if addSignatureAtThisLevel

        % Add blocks to model
        inGotoLength = 0;
        outGotoLength = 0;
        if ~isempty(Inports)
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Inputs'], 'Position', [X_OFFSET_HEADING 15], 'FontSize', FONT_SIZE_LARGER, 'FontWeight', 'Bold');
            [InportGoto, InportFrom, inGotoLength] = InportSig(address, Inports);
            for i = 1:length(Inports)
                dontMoveBlocks(end+1) = get_param(Inports{i}, 'Handle');
                dontMoveBlocks(end+1) = get_param(InportGoto{i}, 'Handle');
            end
        end
        if ~isempty(Outports)
            [OutportGoto, OutportFrom, outGotoLength] = OutportSig(address, Outports);
            for i = 1:length(Outports)
                dontMoveBlocks(end+1) = get_param(Outports{i}, 'Handle');
                dontMoveBlocks(end+1) = get_param(OutportFrom{i}, 'Handle');
            end
        end

        % Organize blocks
        gotoLength = max([inGotoLength outGotoLength]);
        if gotoLength == 0
            gotoLength = 15;
        end
        if ~isempty(Inports)
            verticalOffset = RepositionInportSig(address, InportGoto, InportFrom, Inports, gotoLength);
            verticalOffset = verticalOffset + Y_OFFSET;
        end
    end

    % Recurse into other Subsystems
    subsystems = find_system(address, 'SearchDepth', 1, 'BlockType', 'SubSystem');
    subsystems = setdiff(subsystems, address);
    for z = 1:length(subsystems)
        % Disable link
        if strcmp(get_param(subsystems{z}, 'LinkStatus'), 'resolved')
            set_param(subsystems{z}, 'LinkStatus', 'inactive');
        end

        [scopedGotoAddOutx, dataStoreWriteAddOutx, dataStoreReadAddOutx, ...
            scopedFromAddOutx, globalGotosAddOutx, globalFromsAddOutx] = ...
            TieInStrong(subsystems{z}, hasUpdates, sys);

        % Append blocks found in Subsystem
        sGa     = [sGa scopedGotoAddOutx];
        sFa     = [sFa scopedFromAddOutx];
        dSWa    = [dSWa dataStoreWriteAddOutx];
        dSRa    = [dSRa dataStoreReadAddOutx];
        gGa     = [gGa globalGotosAddOutx];
        gFa     = [gFa globalFromsAddOutx];
    end

    % Remove duplicates
    sGa     = unique(sGa);
    sFa     = unique(sFa);
    dSWa    = unique(dSWa);
    dSRa    = unique(dSRa);
    gGa     = unique(gGa);
    gFa     = unique(gFa);

    % Get the names of added Inports/Outport Goto/Froms
    inputPortsTags = {};
    if ~isempty(InportGoto)
        for i = 1:length(InportGoto)
            inputPortsTags{end + 1} = get_param(InportGoto{i}, 'GotoTag');
        end
    end

    outputPortsTags = {};
    if ~isempty(OutportGoto)
        for j = 1:length(OutportGoto)
            outputPortsTags{end + 1} = get_param(OutportGoto{j}, 'GotoTag');
        end
    end

    portTags = [inputPortsTags outputPortsTags];

    % Find the implicit interface
    [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, ...
        updateBlocks, globalFroms, globalGotos] = ...
        AddImplicitsStrong(address, sGa, sFa, dSWa, dSRa, gGa, gFa, portTags, hasUpdates, sys);

     if addSignatureAtThisLevel

        % Add Data Store Reads
        if ~isempty(dataStoreReads(~cellfun('isempty', dataStoreReads)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Data Store Reads'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, dataStoreReads, gotoLength, 1);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks dataStoreReads{1}];
            dontMoveBlocks = [dontMoveBlocks dataStoreReads{2}];
        end

        % Add scoped Froms
        if ~isempty(fromBlocks(~cellfun('isempty', fromBlocks)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Scoped Froms'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, fromBlocks, gotoLength, 1);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks fromBlocks{1}];
            dontMoveBlocks = [dontMoveBlocks fromBlocks{2}];
        end

        % Add global Froms
        if ~isempty(globalFroms(~cellfun('isempty', globalFroms)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Global Froms'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, globalFroms, gotoLength, 0);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks globalFroms{1}];
            dontMoveBlocks = [dontMoveBlocks globalFroms{2}];
        end

        % Add updates (if enabled)
        if hasUpdates && ~isempty(updateBlocks(~cellfun('isempty', updateBlocks)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Updates'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE_LARGER, 'FontWeight', 'Bold');
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, updateBlocks, gotoLength, 0);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks updateBlocks{1}];
            dontMoveBlocks = [dontMoveBlocks updateBlocks{2}];
        end

        % Add Outports
        if ~isempty(Outports(~cellfun('isempty', Outports)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Outputs'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE_LARGER, 'FontWeight', 'Bold');
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionOutportSig(address, OutportGoto, OutportFrom, Outports, gotoLength, verticalOffset);
            verticalOffset = verticalOffset + Y_OFFSET;
        end

        % Add Data Store Writes
        if ~isempty(dataStoreWrites(~cellfun('isempty', dataStoreWrites)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Data Store Writes'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, dataStoreWrites, gotoLength, 0);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks dataStoreWrites{1}];
            dontMoveBlocks = [dontMoveBlocks dataStoreWrites{2}];
        end

        % Add scoped Gotos
        if ~isempty(gotoBlocks(~cellfun('isempty', gotoBlocks)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Scoped Gotos'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, gotoBlocks, gotoLength, 0);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks gotoBlocks{1}];
            dontMoveBlocks = [dontMoveBlocks gotoBlocks{2}];
        end

        % Add global Gotos
        if ~isempty(globalGotos(~cellfun('isempty', globalGotos)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Global Gotos'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE);
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionImplicits(verticalOffset, globalGotos, gotoLength, 1);
            verticalOffset = verticalOffset + Y_OFFSET;
            dontMoveBlocks = [dontMoveBlocks globalGotos{1}];
            dontMoveBlocks = [dontMoveBlocks globalGotos{2}];
        end

        % Add declarations (i.e. Data Store Memory or Goto Tag Visibility)
        dataDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
        tagDex = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
        if ~isempty(dataDex(~cellfun('isempty', dataDex))) || ~isempty(tagDex(~cellfun('isempty', tagDex)))
            dontMoveNote{end+1} = add_block('built-in/Note', [address '/Declarations'], 'Position', [X_OFFSET_HEADING verticalOffset + 20], 'FontSize', FONT_SIZE_LARGER, 'FontWeight', 'Bold');
            verticalOffset = verticalOffset + Y_OFFSET;
            verticalOffset = RepositionDataStoreDex(address, verticalOffset);
        end

        for i = 1:length(dataDex)
            dontMoveBlocks = [dontMoveBlocks get_param(dataDex{i}, 'Handle')];
        end

        for i = 1:length(tagDex)
            dontMoveBlocks = [dontMoveBlocks get_param(tagDex{i}, 'Handle')];
        end

        % Move all blocks to make room for the Signature
        moveUnselected(address, 100, 0, dontMoveBlocks, dontMoveNote);

     end

    % Set output information
    scopedFromAddOut     = carryUp{1};
    scopedGotoAddOut     = carryUp{4};
    dataStoreReadAddOut  = carryUp{2};
    dataStoreWriteAddOut = carryUp{3};
    globalFromsAddOut    = carryUp{5};
    globalGotosAddOut    = carryUp{6};
end
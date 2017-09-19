function TestHarness(system)
% TESTHARNESS Augment a subsystem with Inports for hidden data flow
%   (Data Stores Reads and Froms) so that testing will generate test inputs
%   and exercise them. Also augments the subsystem with Outports for
%   Data Store Writes and Gotos so that testing can record this data.
%
%   Inputs:
%       system      Simulink model name to generate the harness for.
%
%   Outputs:
%       N/A

    % Constants:
    FONT_SIZE = str2num(getSignatureConfig('heading_size', 12)); % Heading font size
    FONT_SIZE_LARGER = FONT_SIZE + 2;
    X_OFFSET_HEADING = 150;

    addedBlocks = {};
    dataTypes = {};

    sysSplit = strsplit(system, '/');
    topLevelSys = sysSplit{1};
    typeMap = mapDataTypes(topLevelSys);

    % Add Inport and Goto to supply test info to Froms
    froms = find_system(system, 'SearchDepth', 1, 'BlockType', 'From');
    fromscheck = strfind(froms, 'FromSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(fromscheck{i}) && (fromscheck{i}(1) == (length(system) + 2))
            % Inport
            inport = add_block('built-in/Inport', [system '/HarnessGotoInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            resizeInOutPort(inport);

            % Goto
            goto = add_block('built-in/Goto', [system  '/HarnessGoto' num2str(num)], ...
                'GotoTag', get_param(froms{i}, 'GotoTag'));
            addedBlocks{end + 1} = goto;
            resizeGotoFrom(goto);

            % Type info
            dtype = typeMap(froms{i});
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            dataTypes{end + 1} = dtype;

            % Connect
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            gotoPort = get_param(goto, 'PortHandles');
            gotoPort = gotoPort.Inport;
            add_line(system, inportPort, gotoPort);

            num = num + 1;
        end
    end

    % Add Inport and Data Store Write to supply test info to Data Store Reads
    reads = find_system(system, 'SearchDepth', 1, 'BlockType', 'DataStoreRead');
    readscheck = strfind(reads, 'DataReadSig');
    readscheck2 = strfind(reads, 'dataStoreReadAdd');
    num = 0;
    for i = 1:length(reads)
        if ~isempty(readscheck{i}) && (readscheck{i}(1) == (length(system) + 2))
            % Inport
            inport = add_block('built-in/Inport', [system '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            resizeInOutPort(inport);

            % Write
            dataStore = add_block('built-in/dataStoreWrite', [system '/HarnessWrite' num2str(num)], ...
                'DataStoreName', get_param(reads{i}, 'DataStoreName'));
            addedBlocks{end + 1} = dataStore;
            resizeDataStore(dataStore);

            % Type info
            dtype = typeMap(reads{i});
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            dataTypes{end + 1} = dtype;

            try
                set_param(inport, 'OutDataTypeStr', dtype);
            catch
                % Do nothing
            end

            % Connect
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            writePort = get_param(dataStore, 'PortHandles');
            writePort = writePort.Inport;
            add_line(system, inportPort, writePort);

            num = num + 1;
        end
        if ~isempty(readscheck2{i}) && (readscheck2{i}(1) == (length(system) + 2))
            % Inport
            inport = add_block('built-in/Inport', [system '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            resizeInOutPort(inport);

            % Write
            dataStore = add_block('built-in/dataStoreWrite', [system '/HarnessWrite' num2str(num)], ...
                'DataStoreName', get_param(reads{i}, 'DataStoreName'));
            addedBlocks{end + 1} = dataStore;
            resizeDataStore(dataStore);

            % Type info
            dtype = typeMap(reads{i});
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            dataTypes{end + 1} = dtype;

            try
                set_param(inport, 'OutDataTypeStr', dtype);
            catch
                % Do nothing
            end

            % Connect
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            writePort = get_param(dataStore, 'PortHandles');
            writePort = writePort.Inport;
            add_line(system, inportPort, writePort);

            num = num + 1;
        end
    end

    % Save the number of Inports that were added
    % Divided by 2 because for every Inport added, a Goto or Write was also added
    numIns = length(addedBlocks)/2;

    % Add Outport and Goto
    % Note: For Reactis, if the scoped Goto stays in the model after
    % subsystem ectraction, this may not work
    gotos = find_system(system, 'SearchDepth', 1, 'BlockType', 'Goto');
    gotoscheck = strfind(froms, 'GotoSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(gotoscheck{i}) && (gotoscheck{i}(1) == (length(system) + 2))
            % From
            from = add_block('built-in/Goto', [system '/HarnessFrom' num2str(num)], ...
                'GotoTag', get_param(gotos{i}, 'GotoTag'));
            addedBlocks{end + 1} = goto;
            resizeGotoFrom(from);

            % Outport
            outport = add_block('built-in/Outport', [system '/HarnessFromOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            resizeInOutPort(outport);

            % Connect
            fromPort = get_param(from, 'PortHandles');
            fromPort = fromPort.Outport;
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            add_line(system, fromPort, outportPort);

            num = num + 1;
        end
    end

    % Add Outport and Data Store Read to output Data Store Write info
    writes = find_system(system, 'SearchDepth', 1, 'BlockType', 'DataStoreRead');
    writescheck = strfind(writes, 'DataWriteSig');
    writescheck2 = strfind(writes, 'dataStoreWriteAdd');
    num = 0;
    for i = 1:length(writes)
        if ~isempty(writescheck{i}) && (writescheck{i}(1) == (length(system) + 2))
            % Read
            dataStore = add_block('built-in/dataStoreRead', [system '/HarnessRead' num2str(num)], ...
                 'DataStoreName', get_param(writes{i}, 'DataStoreName'));
            addedBlocks{end + 1} = dataStore;
            resizeDataStore(dataStore);

            % Outport
            outport = add_block('built-in/Outport', [system '/HarnessReadOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            resizeInOutPort(outport);

            % Connect
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            add_line(system, readPort, outportPort);

            num = num + 1;
        end
        if ~isempty(writescheck2{i}) && (writescheck2{i}(1) == (length(system) + 2))
            % Read
            dataStore = add_block('built-in/dataStoreRead', [system '/HarnessRead' num2str(num)], ...
                'DataStoreName', get_param(writes{i}, 'DataStoreName'));
            addedBlocks{end + 1} = dataStore;
            resizeDataStore(dataStore);

            % Outport
            outport = add_block('built-in/Outport', [system '/HarnessWriteOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            resizeInOutPort(outport);

            % Connect
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            add_line(system, readPort, outportPort);

            num = num + 1;
        end
    end

   % Save the number of Outports that were added
    numOuts = length(addedBlocks)/2 - numIns;

    %% Reposition all elements in the model
    numBlock = length(addedBlocks);
    if numBlock > 0
        rowNum = ceil(numBlock/2);

        % Get model info
        mdlLines    = find_system(system, 'Searchdepth', 1, 'FollowLinks', ...
            'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
        allBlocks   = find_system(system, 'SearchDepth', 1);
        annotations = find_system(system, 'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');

        % Shift all lines downward
        for i = 1:length(mdlLines)
            lPint = get_param(mdlLines(i), 'Points');
            xPint = lPint(:, 1); % First position integer
            yPint = lPint(:, 2); % Second position integer
            yPint = yPint + 40*rowNum + 30;
            newPoint = [xPint yPint];
            set_param(mdlLines(i), 'Points', newPoint);
        end

        % Shift all blocks downward
        for i = 2:length(allBlocks) % Starts at 2 in order to skip the root block diagram
                bPosition = get_param(allBlocks{i}, 'Position');
                bPosition(1) = bPosition(1);
                bPosition(2) = bPosition(2) + 40*rowNum + 30;
                bPosition(3) = bPosition(3);
                bPosition(4) = bPosition(4) + 40*rowNum + 30;
                set_param(allBlocks{i}, 'Position', bPosition);
        end

        % Shift all annotations downward
        for i = 1:length(annotations)
            bPosition = get_param(annotations(i), 'Position');
            bPosition(1) = bPosition(1);
            bPosition(2) = bPosition(2) + 40*rowNum + 30;
            set_param(annotations(i), 'Position', bPosition);
        end

        % Resposition new test harness blocks
        startTop = 10;
        startLeft = 50;

        % Add heading for test harness specific blocks
        add_block('built-in/Note', [system '/Inputs for Harness'], ...
            'Position', [X_OFFSET_HEADING startTop], 'FontSize', FONT_SIZE_LARGER, 'FontWeight', 'Bold')

        startTop = startTop + 30;

        for j = 1:length(addedBlocks)
            if(ceil(j/2) > 1) % Not first row
                startTop = 40 + 40*(ceil(j/2) - 1); % Compute next row placement
            end
            if(mod(j,2) == 1) % First block in the row
                blockpos = get_param(addedBlocks{j}, 'Position');
                newPos(1) = startLeft;
                newPos(2) = startTop;
                newPos(3) = startLeft + (blockpos(3) - blockpos(1));
                newPos(4) = startTop + (blockpos(4) - blockpos(2));
                set_param(addedBlocks{j}, 'Position', newPos);

                newPos = [];
            else
                % Position it w.r.t. the last one added
                moveToBlock(addedBlocks{j}, addedBlocks{j-1}, 0);
            end
        end
    end

    %% Add Inport/Outport blocks to all higher levels
    sysSplit = strsplit(system, '/');
    sysName = strjoin(sysSplit, '/');
    subsystemLevels = length(sysSplit) - 1;

    for i = 1:subsystemLevels
        ins = find_system(sysName, 'SearchDepth', 1, 'BlockType', 'Inport');
        outs = find_system(sysName, 'SearchDepth', 1, 'BlockType', 'Outport');
        sysIns = length(ins) - numIns;
        sysOuts = length(outs) - numOuts;
        nextSys = sysSplit;
        nextSys(end) = [];
        nextSys = strjoin(nextSys, '/');
        ports = get_param(sysName, 'PortHandles');

        % Add Inports
        num = 0;
        for j = 1:numIns
            % Add
            inport = add_block('built-in/Inport', [nextSys '/HarnessInport' num2str(num)]);
            try
                set_param(inport, 'OutDataTypeStr', dataTypes{j});
            catch
                % Do nothing
            end

            % Connect
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            subInports = ports.Inport;

            moveToPort(inport, subInports(sysIns + j), 1);
            resizeInOutPort(inport);
            add_line(nextSys, inportPort, subInports(sysIns + j));
            num = num + 1;
        end

        % Add Outports
        num = 0;
        for j = 1:numOuts
            % Add
            outport = add_block('built-in/Outport', [nextSys '/HarnessOutport' num2str(num)]);

            % Connect
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            subOutports = ports.Outport;
            moveToPort(outport, subOutports(sysOuts + j), 0)
            resizeInOutPort(outport);
            add_line(nextSys, subOutports(sysOuts + j), outportPort);
            num = num + 1;
        end
        sysSplit = strsplit(nextSys, '/');
        sysName = nextSys;
    end
end

function resizeGotoFrom(block)
%% resizeDataStore Resize a Goto/From block to their default values.
%
%   Inputs:
%       block   Handle of the block to be resized.
%
%   Outputs:
%       N/A
    resizeBlock(block, 125, 14);
end

function resizeInOutPort(block)
%% resizeInOutPort Resize an Inport or Outport block to their default values.
%
%   Inputs:
%       block   Handle of the block to be resized.
%
%   Outputs:
%       N/A
    resizeBlock(block, 30, 14);
end

function resizeDataStore(block)
%% resizeDataStore Resize a Data Store Memory/Read/Write block to their default values.
%
%   Inputs:
%       block   Handle of the block to be resized.
%
%   Outputs:
%       N/A
    resizeBlock(block, 90, 14);
end
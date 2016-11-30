function TestHarness(system)
% TESTHARNESS Augment a system with a test harness which accounts for
%   hidden data flow of data stores.
%
%   Inputs:
%       system      Simulink subsystem path to generate the harness for.
%
%   Outputs:
%       N/A

    % Extract signature of the subsystem
    addedBlocks = {};
    dataTypes = {};
    
    sysSplit = strsplit(system, '/');
    topLevelSys = sysSplit{1};
    typeMap = mapDataTypes(topLevelSys);
%     StrongSignature(topLevelSys, 0, 0, sys);
%     topLevelSys = [topLevelSys '_STRONG_SIGNATURE'];
%     sysSplit{1} = topLevelSys;
%     sys = strjoin(sysSplit, '/');
    
    % Add Inport and Goto to supply test info to Froms
    froms = find_system(system, 'SearchDepth', 1, 'BlockType', 'From');
    fromscheck = strfind(froms, 'FromSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(fromscheck{i}) && (fromscheck{i}(1) == (length(system) + 2))
            inport = add_block('built-in/Inport', [system '/HarnessGotoInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            GotoTag = get_param(froms{i}, 'GotoTag');
            goto = add_block('built-in/Goto', [system  '/HarnessGoto' num2str(num)]);
            addedBlocks{end + 1} = goto;
            dtype = typeMap(froms{i});
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            dataTypes{end + 1} = dtype;
            set_param(goto, 'GotoTag', GotoTag);
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
            inport = add_block('built-in/Inport', [system '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            DataStoreName = get_param(reads{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreWrite', [system '/HarnessWriter' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            dtype = typeMap(reads{i});

            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end

            dataTypes{end + 1} = dtype;
            try 
                set_param(inport, 'OutDataTypeStr', dtype);
            catch 
            end
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            writePort = get_param(dataStore, 'PortHandles');
            writePort = writePort.Inport;
            add_line(system, inportPort, writePort);
            num = num + 1;
        end
        if ~isempty(readscheck2{i}) && (readscheck2{i}(1) == (length(system) + 2))
            inport = add_block('built-in/Inport', [system '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            DataStoreName = get_param(reads{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreWrite', [system '/HarnessWriter' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            dtype = typeMap(reads{i});
            
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            
            dataTypes{end + 1} = dtype;
            try
                set_param(inport, 'OutDataTypeStr', dtype);
            catch
            end
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            writePort = get_param(dataStore, 'PortHandles');
            writePort = writePort.Inport;
            add_line(system, inportPort, writePort);
            num = num + 1;
        end
    end
    
    % Save the number of Inports that were added
    % Divided by 2 beause for every Inport added, a Goto or Write was also added
    numIns = length(addedBlocks)/2;
    
    % Add Outport and Goto
    % Note: For Reactis, if the scoped Goto stays in the model after 
    % subsystem ectraction, this may not work
    gotos = find_system(system, 'SearchDepth', 1, 'BlockType', 'Goto');
    gotoscheck = strfind(froms, 'GotoSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(gotoscheck{i}) && (gotoscheck{i}(1) == (length(system) + 2))
            GotoTag = get_param(gotos{i}, 'GotoTag');
            from = add_block('built-in/Goto', [system '/HarnessFrom' num2str(num)]);
            addedBlocks{end + 1} = goto;
            outport = add_block('built-in/Outport', [system '/HarnessFromOutport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            set_param(from, 'GotoTag', GotoTag);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            fromPort = get_param(from, 'PortHandles');
            fromPort = fromPort.Outport;
            add_line(system, inportPort, fromPort);
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
            DataStoreName = get_param(writes{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreRead', [system '/HarnessReader' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            outport = add_block('built-in/Outport', [system '/HarnessReadOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            add_line(system, readPort, outportPort);
            num = num + 1;
        end
        if ~isempty(writescheck2{i}) && (writescheck2{i}(1) == (length(system) + 2))
            DataStoreName = get_param(writes{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreRead', [system '/HarnessWriter' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            outport = add_block('built-in/Outport', [system '/HarnessWriteOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            add_line(system, readPort, outportPort);
            num = num + 1;
        end
    end

   % Save the number of Outports that were added
    numOuts = length(addedBlocks)/2 - numIns;

    %% Reposition all elements in the model
    numBlock = length(addedBlocks);
    if numBlock > 0
    
        start = 30;
        top = 30;
        rowNum = ceil(numBlock/2);
        colNum = 10;

        % Get model info
        mdlLines    = find_system(system, 'Searchdepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
        allBlocks   = find_system(system, 'SearchDepth', 1);
        annotations = find_system(system, 'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');
        
        % Shift all lines downward
        for zm = 1:length(mdlLines)
            lPint = get_param(mdlLines(zm), 'Points');
            xPint = lPint(:, 1); % First position integer
            yPint = lPint(:, 2); % Second position integer
            yPint = yPint + 50*rowNum + 30;
            newPoint = [xPint yPint];
            set_param(mdlLines(zm), 'Points', newPoint);
        end
        
        % Shift all blocks downward
        for z = 2:length(allBlocks) % Starts at 2 in order to skip the root block diagram
                bPosition = get_param(allBlocks{z}, 'Position');
                bPosition(1) = bPosition(1);
                bPosition(2) = bPosition(2) + 50*rowNum + 30;
                bPosition(3) = bPosition(3);
                bPosition(4) = bPosition(4) + 50*rowNum + 30;
                set_param(allBlocks{z}, 'Position', bPosition);
        end
        
        % Shift all annotations downward
        for gg = 1:length(annotations)
            bPosition = get_param(annotations(gg), 'Position');
            bPosition(1) = bPosition(1);
            bPosition(2) = bPosition(2) + 50*rowNum + 30;
            set_param(annotations(gg), 'Position', bPosition);
        end
       
        % Resposition new test harness blocks
        for j = 1:length(addedBlocks)
            if(ceil(j/2) > 1)
                top = 30 + 50*(ceil(j/2) - 1);
                if(mod(j,2) == 1)
                    start = 30;
                end
            end
            blockpos = get_param(addedBlocks{j}, 'Position');
            newPos(1) = start;
            newPos(2) = top;
            newPos(3) = start + (blockpos(3) - blockpos(1))*5;
            newPos(4) = top + (blockpos(4) - blockpos(2));
            start = newPos(3) + 20;
            set_param(addedBlocks{j}, 'Position', newPos);
            newPos = [];
        end
    end

    % Add heading for test harness specific blocks
    if numBlock > 0
        add_block('built-in/Note', [system '/Inputs for Harness'], 'Position', [100 10], 'FontSize', 12)
    end

    %% Add Inport/Outport blocks to all higher levels
    sysSplit = strsplit(system, '/');
    sysName = strjoin(sysSplit, '/');
    iterations = length(sysSplit) - 1;
    
    for i = 1:iterations
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
            inport = add_block('built-in/Inport', [nextSys '/HarnessInport' num2str(num)]);
            try
                set_param(inport, 'OutDataTypeStr', dataTypes{j});
            catch
            end
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            subInports = ports.Inport;
            add_line(nextSys, inportPort, subInports(sysIns + j));
            num = num + 1;
        end

        % Add Outports
        num = 0;
        for j = 1:numOuts
            outport = add_block('built-in/Outport', [nextSys '/HarnessOutport' num2str(num)]);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            subOutports = ports.Outport;
            add_line(nextSys, subOutports(sysOuts + j), outportPort);
            num = num + 1;
        end
        sysSplit = strsplit(nextSys, '/');
        sysName = nextSys; 
    end 
end
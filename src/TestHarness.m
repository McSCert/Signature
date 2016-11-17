function TestHarness(sys)
% TESTHARNESS Augments a system with a test harness which accounts for
% hidden data flow of data stores.
%
%   Inputs:
%       sys      Simulink system path to generate the harness for
%
%   Outputs:
%       N/A

    % Extract signature of the subsystem
    addedBlocks = {};
    dataTypes = {};
    
    sysSplit = strsplit(sys, '/');
    topLevelSys = sysSplit{1};
    typeMap = mapDataTypes(topLevelSys);
%     StrongSignature(topLevelSys, 0, 0, sys);
%     topLevelSys = [topLevelSys '_STRONG_SIGNATURE'];
%     sysSplit{1} = topLevelSys;
%     sys = strjoin(sysSplit, '/');
    
    froms = find_system(sys, 'SearchDepth', 1, 'BlockType', 'From');
    fromscheck = strfind(froms, 'FromSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(fromscheck{i}) && (fromscheck{i}(1) == (length(sys) + 2))
            inport = add_block('built-in/Inport', [sys '/HarnessGotoInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            GotoTag = get_param(froms{i}, 'GotoTag');
            goto = add_block('built-in/Goto', [sys  '/HarnessGoto' num2str(num)]);
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
            add_line(sys, inportPort, gotoPort);
            num = num + 1;
        end
    end
    
    reads = find_system(sys, 'SearchDepth', 1, 'BlockType', 'DataStoreRead');
    readscheck = strfind(reads, 'DataReadSig');
    readscheck2 = strfind(reads, 'dataStoreReadAdd');
    num = 0;
    for i = 1:length(reads)
        if ~isempty(readscheck{i}) && (readscheck{i}(1) == (length(sys) + 2))
            inport = add_block('built-in/Inport', [sys '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            DataStoreName = get_param(reads{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreWrite', [sys  '/HarnessWriter' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            dtype = typeMap(reads{i});
            if strcmp(dtype, 'No type')
                dtype = 'Inherit: auto';
            end
            dataTypes{end + 1} = dtype;
            set_param(inport, 'OutDataTypeStr', dtype);
            inportPort = get_param(inport, 'PortHandles');
            inportPort = inportPort.Outport;
            writePort = get_param(dataStore, 'PortHandles');
            writePort = writePort.Inport;
            add_line(sys, inportPort, writePort);
            num = num + 1;
        end
        if ~isempty(readscheck2{i}) && (readscheck2{i}(1) == (length(sys) + 2))
            inport = add_block('built-in/Inport', [sys '/HarnessWriteInport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            DataStoreName = get_param(reads{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreWrite', [sys  '/HarnessWriter' num2str(num)]);
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
            add_line(sys, inportPort, writePort);
            num = num + 1;
        end
        
    end
    
    numIns = length(addedBlocks)/2;
    
    % If the scoped goto stays in the model for reactis, this may not work
    gotos = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Goto');
    gotoscheck = strfind(froms, 'GotoSigScope');
    num = 0;
    for i = 1:length(froms)
        if ~isempty(gotoscheck{i}) && (gotoscheck{i}(1) == (length(sys) + 2))
            GotoTag = get_param(gotos{i}, 'GotoTag');
            from = add_block('built-in/Goto', [sys  '/HarnessFrom' num2str(num)]);
            addedBlocks{end + 1} = goto;
            outport = add_block('built-in/Outport', [sys '/HarnessFromOutport' num2str(num)]);
            addedBlocks{end + 1} = inport;
            set_param(from, 'GotoTag', GotoTag);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            fromPort = get_param(from, 'PortHandles');
            fromPort = fromPort.Outport;
            add_line(sys, inportPort, fromPort);
            num = num + 1;
        end
    end
    
    writes = find_system(sys, 'SearchDepth', 1, 'BlockType', 'DataStoreRead');
    writescheck = strfind(writes, 'DataWriteSig');
    writescheck2 = strfind(writes, 'dataStoreWriteAdd');
    num = 0;
    for i = 1:length(writes)
        if ~isempty(writescheck{i}) && (writescheck{i}(1) == (length(sys) + 2))
            DataStoreName = get_param(writes{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreRead', [sys  '/HarnessReader' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            outport = add_block('built-in/Outport', [sys '/HarnessReadOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            add_line(sys, readPort, outportPort);
            num = num + 1;
        end
        
        if ~isempty(writescheck2{i}) && (writescheck2{i}(1) == (length(sys) + 2))
            DataStoreName = get_param(writes{i}, 'DataStoreName');
            dataStore = add_block('built-in/dataStoreRead', [sys  '/HarnessWriter' num2str(num)]);
            addedBlocks{end + 1} = dataStore;
            outport = add_block('built-in/Outport', [sys '/HarnessWriteOutport' num2str(num)]);
            addedBlocks{end + 1} = outport;
            set_param(dataStore, 'DataStoreName', DataStoreName);
            outportPort = get_param(outport, 'PortHandles');
            outportPort = outportPort.Inport;
            readPort = get_param(dataStore, 'PortHandles');
            readPort = readPort.Outport;
            add_line(sys, readPort, outportPort);
            num = num + 1;
        end
    end
    
    numOuts = length(addedBlocks)/2 - numIns;
    
%     add_block('built-in/Note',[address '/Inputs for Harness'], 'Position', [90 10], 'FontSize', 10)
    start = 30;
    top = 30;
    numBlock = length(addedBlocks);
    rowNum = ceil(numBlock/2);
    colNum = 10;
    mdlLines = find_system(sys,'Searchdepth',1, 'FollowLinks', 'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
    allBlocks = find_system(sys, 'SearchDepth', 1);
    annotations = find_system(sys,'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');
    
    for zm = 1:length(mdlLines)
        lPint = get_param(mdlLines(zm), 'Points');
        xPint = lPint(:,1); % first position integer
        yPint = lPint(:,2); % second position integer
        yPint = yPint + 50*rowNum + 30;
        newPoint = [xPint yPint];
        set_param(mdlLines(zm), 'Points', newPoint);
    end
    
    for z = 2:length(allBlocks) % 2 in order to skip the block diagram (it has no position)
            bPosition = get_param(allBlocks{z}, 'Position'); % blockposition
            bPosition(1) = bPosition(1);
            bPosition(2) = bPosition(2) + 50*rowNum + 30;
            bPosition(3) = bPosition(3);
            bPosition(4) = bPosition(4) + 50*rowNum + 30;
            set_param(allBlocks{z}, 'Position', bPosition);
    end
    
    for gg = 1:length(annotations)
        bPosition = get_param(annotations(gg), 'Position'); % annotations position
        bPosition(1) = bPosition(1);
        bPosition(2) = bPosition(2) + 50*rowNum + 30;
        set_param(annotations(gg), 'Position', bPosition);
    end
   
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
        set_param(addedBlocks{j},'Position', newPos);
        newPos = [];
    end
    
    sysSplit = strsplit(sys, '/');
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
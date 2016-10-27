function dataTypeMap = mapDataTypes(address)
%mapDataTypes find the data types for blocks in a system
%   The results are returned in a map object with blocks as the keys and
%   their output types as the values.
%
%   For further information on using the map please refer to:
%   http://www.mathworks.com/help/matlab/matlab_prog/description-of-the-map-class.html

RecurseCell={};
mapPrevBlocks=containers.Map();
dataTypeMap=containers.Map();

[RecurseCell,mapPrevBlocks]=addStartBlocks(address,RecurseCell,mapPrevBlocks);

while ~isempty(RecurseCell)
    currentBlock=RecurseCell{end};
    RecurseCell=RecurseCell(1:end-1);
    
    type=getBlockType(currentBlock, mapPrevBlocks, dataTypeMap);
    dataTypeMap(currentBlock)=type;
    
    dstBlocks=getDstBlocks(address,currentBlock);
    [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,dstBlocks,currentBlock);
end
dataTypeMap=typeDSMs(address, RecurseCell, mapPrevBlocks, dataTypeMap);
end

function dataTypeMap=typeDSMs(address, RecurseCell, mapPrevBlocks, dataTypeMap)
DSMs=find_system(address, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreMemory');
for i=1:length(DSMs)
    label=get_param(DSMs{i}, 'DataStoreName');
    DSWs=find_system(address,'BlockType','DataStoreWrite','DataStoreName',label);
    hasPrev = false;
    for j=1:length(DSWs)
        if isKey(mapPrevBlocks, DSWs{j})
            [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell, mapPrevBlocks, DSMs{i}, DSWs{j});
            hasPrev = true;
        end
    end
    if ~hasPrev
        [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell, mapPrevBlocks, DSMs{i}, true);
    end
    type=getBlockType(DSMs{i}, mapPrevBlocks, dataTypeMap);
    dataTypeMap(DSMs{i})=type;
end
end

function [RecurseCell,mapPrevBlocks]=addStartBlocks(address,RecurseCell,mapPrevBlocks)
%Finds initial blocks in the system with no signal feeding in

%Add Top-Level Inports, Enable Ports, Trigger Ports, State Ports, and Action Ports
for i={'Inport','EnablePort','TriggerPort','StatePort','ActionPort'}
    startBlocks=find_system(address, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', char(i));
    [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,startBlocks,true);
end

startBlocks=find_system(address, 'LookUnderMasks', 'all', 'BlockType', 'Constant');
[RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,startBlocks,true);  %Add Constants

%Add Data Store Reads with no associated Write
startBlocks=find_system(address, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreRead');
for i=1:length(startBlocks)
    dsName=get_param(startBlocks(i),'DataStoreName');
    prevBlocks=find_system(address,'BlockType','DataStoreWrite','DataStoreName',char(dsName));
    if isempty(prevBlocks)
        [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,startBlocks{i},true);
    end
end

%Add Froms with no associated Goto
startBlocks=find_system(address, 'LookUnderMasks', 'all', 'BlockType', 'From');
for i=1:length(startBlocks)
    gotoTag=get_param(startBlocks(i),'GotoTag');
    parent=get_param(startBlocks(i),'Parent');
    
    gotoVisibility=find_system(address,'BlockType','GotoTagVisibility','GotoTag',char(gotoTag));
    scopedGoto=[];
    if ~isempty(gotoVisibility)
        scopeLevel=get_param(gotoVisibility,'Parent');
        scopedGoto=find_system(scopeLevel,'BlockType','Goto','GotoTag',char(gotoTag),'TagVisibility','scoped');
    end
    
    localGoto=find_system(parent,'SearchDepth',1,'BlockType','Goto','GotoTag',char(gotoTag),'TagVisibility','local');
    globalGoto=find_system(address,'BlockType','Goto','GotoTag',char(gotoTag),'TagVisibility','global');
    
    if (isempty(scopedGoto) && isempty(localGoto) && isempty(globalGoto))
        [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,startBlocks{i},true);
    end
end

%For SubSystem ports with no input signal, add the associated block within the SubSystem
subsystems=find_system(address, 'LookUnderMasks', 'all', 'BlockType', 'SubSystem');
for i=1:length(subsystems)
    subPorts=get_param(subsystems{i},'PortHandles');
    
    tmpPorts=subPorts.Inport;
    [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystems{i});
    
    tmpPorts=subPorts.Enable;
    [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystems{i});
    
    tmpPorts=subPorts.Trigger;
    [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystems{i});
    
    tmpPorts=subPorts.State;
    [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystems{i});
    
    tmpPorts=subPorts.Ifaction;
    [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystems{i});
end
end

function [RecurseCell,mapPrevBlocks]=addStartSubBlocks(RecurseCell,mapPrevBlocks,tmpPorts,subsystem)
for i=1:length(tmpPorts)
    addTmpPorts=0;
    tmpLine=get_param(tmpPorts(i),'Line');
    if tmpLine == -1
        addTmpPorts=1;
    elseif tmpLine ~= -1
        tmpSrc=get_param(tmpLine,'Srcblockhandle');
        if tmpSrc == -1
            addTmpPorts=1;
        end
    end
    if addTmpPorts
        tmpPort=get(tmpPorts(i));
        prevBlock=true;
        nextBlock=getSubPortDst(subsystem,tmpPort);
        [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,nextBlock,prevBlock);
    end
end
end

function blockDataType=getBlockType(block, mapPrevBlocks, dataTypeMap)
if isKey(dataTypeMap, getfullname(block))
    blockDataType=dataTypeMap(getfullname(block));
    return
end
try
    blockDataType=get_param(block, 'OutDataTypeStr');
    if ~strcmp(blockDataType, 'Inherit: auto')
        return
    end
end
if ~strcmp(mapPrevBlocks(block), block)
    blockDataType=getBlockType(mapPrevBlocks(block), mapPrevBlocks, dataTypeMap);
    return
end
if exist('blockDataType')~=1
    blockDataType='No type';
end
end

function dstBlocks=getDstBlocks(address,block)
%Finds the destination blocks for a given block
%The destination block is considered to skip subsystem blocks along with bus creator/selector pairs
%i.e. A block which leads into an inport of a subsystem will give the corresponding inport within the subsystem as its destination

blockType=get_param(block, 'BlockType');
if iscell(blockType)
    blockType=blockType{1};
end
switch blockType
    %To maintain consistency with the way subsystems are handled, it might
    %make sense to skip from and data store read blocks in the same way and
    %then to add later with a different function in the same way as
    %subsystems
    case 'Goto'
        label=get_param(block, 'GotoTag');
        visibility=get_param(block, 'TagVisibility');
        
        if strcmp(visibility,'global')
            dstBlocks=find_system(address,'BlockType','From','GotoTag',label);
        elseif strcmp(visibility,'local')
            parent=get_param(block,'Parent');
            dstBlocks=find_system(parent,'SearchDepth',1,'BlockType','From','GotoTag',label);
        elseif strcmp(visibility,'scoped')
            gotoVisibility=find_system(address,'BlockType','GotoTagVisibility','GotoTag',label);
            dstBlocks=[];
            if ~isempty(gotoVisibility)
                scopeLevel=get_param(gotoVisibility,'Parent');
                dstBlocks=find_system(scopeLevel,'BlockType','From','GotoTag',label);
            end
        end
    case 'DataStoreWrite'
        label=get_param(block, 'DataStoreName');
        dstBlocks=find_system(address,'BlockType','DataStoreRead','DataStoreName',label);
    otherwise
        dstBlocks=[];
        srcPorts=getSrcPorts(address,block);    %(block is the source)
        if ~isempty(srcPorts)
            for i=1:length(srcPorts)
                dstBlocks=[dstBlocks;getPortDst(address,srcPorts(i))];
            end
        end
end
end

function [RecurseCell,mapPrevBlocks]=addNextBlocks(RecurseCell,mapPrevBlocks,nextBlocks,prevBlock)
%Adds blocks to RecurseCell, and mapPrevBlocks if they have not yet been added

if ~isempty(nextBlocks)
    if ~ischar(nextBlocks)
        for i=1:length(nextBlocks)
            if iscell(nextBlocks)
                
                %This section covers the main functionality of addNextBlocks,
                %however it gets repeated for variations in the
                %form the inputs are given in
                if ~isKey(mapPrevBlocks,getfullname(nextBlocks{i}))
                    if prevBlock==true
                        mapPrevBlocks(getfullname(nextBlocks{i}))=getfullname(nextBlocks{i});
                    else
                        mapPrevBlocks(getfullname(nextBlocks{i}))=prevBlock;
                    end
                    RecurseCell=[getfullname(nextBlocks{i}); RecurseCell];
                end
                
            else
                if ~isKey(mapPrevBlocks,getfullname(nextBlocks(i)))
                    if prevBlock==true
                        mapPrevBlocks(getfullname(nextBlocks(i)))=getfullname(nextBlocks(i));
                    else
                        mapPrevBlocks(getfullname(nextBlocks(i)))=prevBlock;
                    end
                    RecurseCell=[getfullname(nextBlocks(i)); RecurseCell];
                end
            end
        end
    else
        if ~isKey(mapPrevBlocks,nextBlocks)
            if prevBlock==true
                mapPrevBlocks(nextBlocks)=nextBlocks;
            else
                mapPrevBlocks(nextBlocks)=prevBlock;
            end
            RecurseCell=[nextBlocks; RecurseCell];
        end
    end
end
end

function srcPorts=getSrcPorts(address,block)
%Finds handles of relevant outports to find the dstBlocks

srcPorts=[];
blockType=get_param(block, 'BlockType');
if iscell(blockType)
    blockType=blockType{1};
end
switch blockType
    case 'Outport'
        parent=get_param(block,'Parent');
        if ~strcmp(parent,address)
            subPorts=get_param(parent, 'PortHandles');
            subOutports=subPorts.Outport;
            for i=1:length(subOutports)
                tmpOutport=get(subOutports(i));
                if str2num(get_param(block,'Port'))==tmpOutport.PortNumber
                    srcPorts=[srcPorts;subOutports(i)];
                end
            end
        end
    otherwise
        if iscell(block)
            block=block{1};
        end
        ports=get_param(block, 'PortHandles');
        srcPorts=ports.Outport;
end
end

function dstBlocks=getPortDst(address,srcPort)
%Returns destination blocks for a given outport

dstBlocks=[];
srcLines=get_param(srcPort,'Line');
for i=1:length(srcLines)
    if iscell(srcLines)
        tmpLine=srcLines{i};
    else
        tmpLine=srcLines(i);
    end
    
    if tmpLine == -1
        continue
    else
        if get_param(tmpLine,'Dstporthandle') == -1
            continue
        else
            dstPorts=get(get_param(tmpLine,'Dstporthandle'));
            for j=1:length(dstPorts)
                tmpDstBlock=dstPorts(j).Parent;
                blockType=get_param(tmpDstBlock, 'BlockType');
                switch blockType
                    case 'SubSystem'
                        dstBlocks=[dstBlocks;getSubPortDst(tmpDstBlock,dstPorts(j))];
                    case 'BusCreator'
                        dstBlocks=[dstBlocks;getBCPortDst(address,tmpDstBlock,dstPorts(j))];
                    otherwise
                        dstBlocks=[dstBlocks;{tmpDstBlock}];
                end
            end
        end
    end
end
end

function dstBlock=getSubPortDst(subsystem,subPort)
%Determines next block for a signal going into a subsystem block
%Returns an empty array for an outport signal

portType=subPort.PortType;
switch portType
    case 'outport'
        dstBlock=[];
    case 'enable'
        dstBlock=getSpecialPortDst(subsystem,'EnablePort');
    case 'trigger'
        dstBlock=getSpecialPortDst(subsystem,'TriggerPort');
        %Test 'state' case
    case 'state'
        dstBlock=getSpecialPortDst(subsystem,'StatePort');
    case 'ifaction'
        dstBlock=getSpecialPortDst(subsystem,'ActionPort');
        %%%case 'lconn'
        %%%case 'rconn'
    case 'inport'
        dstBlock=find_system(subsystem, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'Inport','Port',num2str(subPort.PortNumber));
        
        if length(dstBlock) > 1
            %This case should not occur as one matching Inport should be in the subsystem
            error('mapDataTypes found too many matching inports. Something went wrong.');
        elseif length(dstBlock) < 1
            %This case may happen in some cases where the port is on a masked SubSystem, the precise cause was not clear
            
            %%%error('mapDataTypes found no matching inports. Something went wrong.'); % This could be removed now, but may be put back in if a better fix is put in place for the masked SubSystem issue%
            dstBlock=[];
        end
end
end
function dstBlock=getSpecialPortDst(subsystem,blockType)
%For use in getSubPortDst, returns the *only* block of blockType in subsystem
%Throws an exception if there was more than one block of blockType in subsystem

%BlockTypes this is intended to be used with include:
%EnablePort, TriggerPort, StatePort, and ActionPort

dstBlock=find_system(subsystem, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', blockType);

%The following exceptions should only occur if getSpecialPortDst is used improperly,
%as the types it is intended to be used with should only appear once per subsystem.
if length(dstBlock) > 1
    exceptionStr = ['Multiple blocks of type ',blockType,' were not expected.'];
    error(exceptionStr);
elseif length(dstBlock) < 1
    exceptionStr = ['One block of type ',blockType,' was expected, 0 found.'];
    error(exceptionStr);
end
end

function dstBlocks=getBCPortDst(address,busCreator,bcPort)
%Determines next block for a signal going into a bus creator block
%Returns an empty array for an outport signal

portType=bcPort.PortType;
switch portType
    case 'outport'
        dstBlocks=[];
    case 'inport'
        dstBlocks=[];
        busSelectors=findBusSelectors(address,busCreator);
        if ~isempty(busSelectors)
            busSelectors=cellstr(busSelectors);
        end
        for i=1:length(busSelectors)
            bsOutports=getSrcPorts(address,busSelectors(i));
            if ~isempty(bsOutports)
                for j=1:length(bsOutports)
                    %Following should be true once at most for a Bus Selector's outports
                    tmpOutport=get(bsOutports(j));
                    
                    inSigs=get_param(busSelectors(i),'InputSignals');
                    inSigs=inSigs{1};
                    if isempty(inSigs)
                        isRightPort=0;
                    else
                        inPortNum=inSigs(bcPort.PortNumber);
                        outSigs=strsplit(get_param(busSelectors{i},'OutputSignals'),',');
                        outPortNum=outSigs(tmpOutport.PortNumber);
                        isRightPort=tmpOutport.PortNumber == bcPort.PortNumber;
                    end
                    if isRightPort
                        dstBlocks=[dstBlocks;getPortDst(address,bsOutports(j))];
                    end
                end
            end
        end
    otherwise
        exceptionStr = 'PortType was expected to be outport or inport.';
        error(exceptionStr);
end
end

function busSelectors=findBusSelectors(address,block)
%Recursively finds bus selectors corresponding to an initial bus creator

busSelectors=[];
tmpBlocks=getDstBlocks(address,block);
if isempty(tmpBlocks)
    busSelectors=[];
else
    for i=1:length(tmpBlocks)
        if iscell(tmpBlocks)
            if strcmp(get_param(tmpBlocks{i},'BlockType'),'BusSelector')
                busSelectors=[busSelectors;tmpBlocks{i}];
            else
                tmpSelectors=findBusSelectors(address,tmpBlocks{i});
                if ischar(tmpSelectors)
                    tmpSelectors=cellstr(tmpSelectors);
                end
                busSelectors=[busSelectors;tmpSelectors];
            end
        else
            if strcmp(get_param(tmpBlocks(i),'BlockType'),'BusSelector')
                busSelectors=[busSelectors;tmpBlocks(i)];
            else
                tmpMap(getfullname(tmpBlocks(i)))=true;
                tmpSelectors=findBusSelectors(address,tmpBlocks(i),tmpMap);
                if ischar(tmpSelectors)
                    tmpSelectors=cellstr(tmpSelectors);
                end
                busSelectors=[busSelectors;tmpSelectors];
            end
        end
    end
end
end

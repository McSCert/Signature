function [metrics, signatures] = TieInData(address, num, scopeGotoAdd, ...
    scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, globalGotos, ...
    globalFroms, sys, metrics, signatures, hasUpdates, txt, dataTypeMap)
%  TIEINDATA Tie in all the files responsible for signature documentation.
%  
%   Inputs:
%
%       address         Simulink system path.
%
%		scopeGotoAdd    Scoped gotos that need to be added to the
%                       list of scoped gotos in the signature.
%
%       scopeFromAdd    Scoped froms that need to be added to the
%                       list of scoped froms in the signature.
%
%		dataStoreWriteAdd Data store writes that need to be added to the
%                         list of data store writes in the model.
%
%		dataStoreReadAdd  Data store reads that need to be added to the
%                         list of data store reads in the model.
%
%		num             Zero if not to be recursed, one for recursed.
%
%		globalGotos     Global gotos to be added to the list of global
%                       gotos in the model.
%
%		globalFroms     Global froms to be added to the list of global
%                       froms in the model.
%
%       sys             Name of the system to generate the documentation for. 
%                       One can use a specific system name, or use 'All' to 
%                       get documentation of the entire hierarchy.
%
%       metrics         A list of structs that contain the names of systems
%                       and the size of their respective signature. (fields
%                       are Subsystem and Size)
%
%       signatures      A list of structs that contain the names of systems
%                       and the size of their respective signature as well
%                       as all of the blocks in the signature. (fields are
%                       Subsystem, Size, Inports, Outports, GlobalFroms,
%                       GlobalGotos, ScopedFromTags, ScopedGotoTags,
%                       DataStoreReads, DataStoreWrites, Updates,
%                       GotoTagVisibilities, and DataStoreMemories)
%
%       hasUpdates      Boolean indicating whether updates are included in 
%                       the signature.
%
%	The function first calls inportSig and outportSig which add and 
%	connect the appropriate blocks for the inport and outport,
%	according to the Signature format. If in the appropriate level, it
%	also calls FindGlobals which outputs the globalGotos in the model.
%	addDataStoreGoto adds the appropriate scoped Gotos and dataStores
%	to the level. repositionInportSig, 
    
    % Get signature for Inports and Outports 
    [inaddress, Inports] = InportSigData(address);
    [outaddress, Outports] = OutportSigData(address);
    
    if num == 0
        globalGotos = FindGlobals(address);
        globalGotos = unique(globalGotos);
        globalFroms = globalGotos;
    end
    [address, scopedGoto, scopedFrom, DataStoreW, DataStoreR, removableDS,...
        removableTags, updates] = AddImplicitsData(address, scopeGotoAdd,...
        scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, hasUpdates);

    removableGotos = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    removableGotosNames = {};
    for i = 1:length(removableGotos)
        removableGotosNames{end + 1} = get_param(removableGotos{i}, 'GotoTag');
    end
    globalGotosx = setdiff(globalGotos, removableGotosNames);
    scopedGotoTags = setdiff(setdiff(scopedGoto, removableTags),updates);
    dataStoreWrites = setdiff(setdiff(DataStoreW, updates), removableDS);
    dataStoreReads = setdiff(setdiff(DataStoreR, updates), removableDS);
    scopedFromTags = setdiff(setdiff(scopedFrom, removableTags), updates);
    updates = setdiff(updates, removableDS);

    % Get declarations for the signature
    [tagDex, dsDex] = ImposedData(address);

    % Make the documentation for the designated subsystem indicated in sys
    if strcmp(sys, address) || strcmp(sys, 'All')
        DataMaker(address, Inports, Outports, scopedGotoTags, scopedFromTags,...
            dataStoreWrites, dataStoreReads, updates, globalGotos, ...
            globalFroms, tagDex, dsDex, hasUpdates, txt, dataTypeMap);
    end

    % Get the metric
    size = length(Inports) + length(Outports) + length(globalFroms) + ...
        length(globalGotosx) + length(scopedGotoTags) + length(scopedFromTags) + ...
        length(dataStoreReads) + length(dataStoreWrites) + 2*length(updates) + ...
        length(tagDex) + length(dsDex);
    size = num2str(size);
    system = strrep(address,'_WEAK_SIGNATURE','');
    metrics{end + 1} = struct('Subsystem', system, 'Size', size);
    
    % Get the signature
    signatures{end + 1} = struct(...
        'Subsystem', system, ...
        'Size', size, ...
        'Inports', {Inports}, ...
        'Outports', {Outports}, ...
        'GlobalFroms', {globalFroms}, ...
        'GlobalGotos', {globalGotosx}, ...
        'ScopedFromTags', {scopedFromTags}, ...
        'ScopedGotoTags', {scopedGotoTags}, ...
        'DataStoreReads', {dataStoreReads}, ...
        'DataStoreWrites',{dataStoreWrites}, ...
        'Updates', {updates}, ...
        'GotoTagVisibilities', {tagDex}, ...
        'DataStoreMemories', {dsDex});

    % Get list of all blocks so it can search and find the subsystems
    allBlocks = find_system(address, 'SearchDepth', 1);
    allBlocks = setdiff(allBlocks, address);
    for z = 1:length(allBlocks)
        BlockType = get_param(allBlocks{z}, 'BlockType');
        if strcmp(BlockType, 'SubSystem')
            isVirtual = get_param(allBlocks{z}, 'IsSubsystemVirtual'); % checks if subsystem is virtual
            % recurse the file through subsystems
            if strcmp(isVirtual, 'on')
                [metrics signatures] = TieInData(allBlocks{z}, 1, ...
                    scopedGoto, scopedFrom, DataStoreW, DataStoreR, ...
                    globalGotosx, globalFroms, sys, metrics, signatures, ...
                    hasUpdates, txt, dataTypeMap);
            else
               [metrics signatures] = TieInData(allBlocks{z}, 1, {}, {}, ...
                   DataStoreW, DataStoreR, {}, {}, sys, metrics, signatures, ...
                   hasUpdates, txt, dataTypeMap, signatures);
            end
        end
    end
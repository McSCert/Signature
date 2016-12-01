function [metrics, signatures] = TieInData(address, num, scopeGotoAdd, ...
    scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, globalGotos, ...
    globalFroms, sys, metrics, signatures, hasUpdates, docFormat, dataTypeMap)
%  TIEINDATA Find the weak signature recursively and output as documentation.
%  
%   Inputs:
%       address         Simulink system path.
%
%       num             Zero if not to be recursed, one for recursed.
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
%       metrics         Cell array listing the system and its subsystems, with
%                       the size of their signature (i.e. number of elements in 
%                       the signature).
%
%       signatures      Cell array of signature data for the system and its 
%                       subsystems. Signature data includes: Subsystem, Size, 
%                       Inports, Outports, GlobalFroms, GlobalGotos, 
%                       ScopedFromTags, ScopedGotoTags, DataStoreReads, 
%                       DataStoreWrites, Updates, GotoTagVisibilities, and 
%                       DataStoreMemories.
%
%       hasUpdates      Boolean indicating whether updates are included in 
%                       the signature.
%
%       docFormat       Number indicating which docmentation type to 
%                       generate: .txt(0) or .tex(1).
%
%       dataTypeMap     Map of blocks and their corresponding data type.
%
%   Outputs:
%       metrics         Cell array listing the system and its subsystems, with
%                       the size of their signature (i.e. number of elements in 
%                       the signature).
%
%       signatures      Cell array of signature data for the system and its 
%                       subsystems. Signature data includes: Subsystem, Size, 
%                       Inports, Outports, GlobalFroms, GlobalGotos, 
%                       ScopedFromTags, ScopedGotoTags, DataStoreReads, 
%                       DataStoreWrites, Updates, GotoTagVisibilities, and 
%                       DataStoreMemories.
    
    % Get signature for Inports and Outports 
    [inaddress, Inports] = InportSigData(address);
    [outaddress, Outports] = OutportSigData(address);
    
    % If at the appropriate level, add the global Gotos in the model
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
    globalGotosx    = setdiff(globalGotos, removableGotosNames);
    scopedGotoTags  = setdiff(setdiff(scopedGoto, removableTags),updates);
    dataStoreWrites = setdiff(setdiff(DataStoreW, updates), removableDS);
    dataStoreReads  = setdiff(setdiff(DataStoreR, updates), removableDS);
    scopedFromTags  = setdiff(setdiff(scopedFrom, removableTags), updates);
    updates         = setdiff(updates, removableDS);

    % Get Data Store declarations and Scoped Gotos for the signature
    [tagDex, dsDex] = ImposedData(address);

    % Make the documentation file for this system
    if strcmp(sys, address) || strcmp(sys, 'All')
        DataMaker(address, Inports, Outports, scopedGotoTags, scopedFromTags,...
            dataStoreWrites, dataStoreReads, updates, globalGotos, ...
            globalFroms, tagDex, dsDex, hasUpdates, docFormat, dataTypeMap);
    end

    % Append this subsystem's metric data to the output
    system = strrep(address, '_WEAK_SIGNATURE', '');
    size = length(Inports) + length(Outports) + length(globalFroms) + ...
        length(globalGotosx) + length(scopedGotoTags) + length(scopedFromTags) + ...
        length(dataStoreReads) + length(dataStoreWrites) + 2*length(updates) + ...
        length(tagDex) + length(dsDex);
    size = num2str(size);
    metrics{end + 1} = struct('Subsystem', system, 'Size', size);
    
    % Append this subsystem's signature data to the output
    signatures{end + 1} = struct(...
        'Subsystem',            system, ...
        'Size',                 size, ...
        'Inports',              {Inports}, ...
        'Outports',             {Outports}, ...
        'GlobalFroms',          {globalFroms}, ...
        'GlobalGotos',          {globalGotosx}, ...
        'ScopedFromTags',       {scopedFromTags}, ...
        'ScopedGotoTags',       {scopedGotoTags}, ...
        'DataStoreReads',       {dataStoreReads}, ...
        'DataStoreWrites',      {dataStoreWrites}, ...
        'Updates',              {updates}, ...
        'GotoTagVisibilities',  {tagDex}, ...
        'DataStoreMemories',    {dsDex});

    % Get all blocks, but remove the current address
    allBlocks = find_system(address, 'SearchDepth', 1);
    allBlocks = setdiff(allBlocks, address);
    
    for z = 1:length(allBlocks)
        BlockType = get_param(allBlocks{z}, 'BlockType');
        if strcmp(BlockType, 'SubSystem')
            isVirtual = get_param(allBlocks{z}, 'IsSubsystemVirtual'); % Checks if subsystem is virtual
            % Recurse through any subsystems
            if strcmp(isVirtual, 'on')
                [metrics signatures] = TieInData(allBlocks{z}, 1, ...
                    scopedGoto, scopedFrom, DataStoreW, DataStoreR, ...
                    globalGotosx, globalFroms, sys, metrics, signatures, ...
                    hasUpdates, docFormat, dataTypeMap);
            else 
                % Atomic subsystems (i.e. non-virtual) are handled differently
                % because Goto/Froms can't cross their boundaries
               [metrics signatures] = TieInData(allBlocks{z}, 1, ...
                    {}, {}, DataStoreW, DataStoreR, ...
                    {}, {}, sys, metrics, signatures, ...
                    hasUpdates, docFormat, dataTypeMap);
            end
        end
    end
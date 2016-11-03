function [scopeGotoAddout, dataStoreWriteAddout, dataStoreReadAddout, ...
    scopeFromAddout, globalGotosAddout, globalFromsAddout, metrics, ...
    signatures] = TieInStrongData(address, sys, hasUpdates, docFormat, dataTypeMap)
% TIEINSTRONGDATA Second to top level in function hierarchy. Recursively 
%   calls itself to find the signature of itself and all subsystems of
%   itself.
%
%   Function:
%       TIEINSTRONGDATA(address, sys, hasUpdates, docFormat, dataTypeMap)
%
%   Inputs:
%       address         The current address.
%       sys             String of the subsystem name or all subsystems to
%                       obtain data for.
%       hasUpdates      Boolean indicating whether updates are included in the signature.
%       docFormat       Boolean indicating which docmentation type to 
%                       generate: .txt(0) or .tex(1).
%       dataTypeMap     ???
%
%   Outputs:
%       scopeGotoAddout         The list of scoped gotos that the function will pass out
%       scopeFromAddOut         The list of scoped froms that the function will pass out
%       dataStoreReadAddout     The list of data store reads that the function will pass out
%       dataStoreWriteAddout    The list of data store writes that the function will pass out
%       metrics                 The data needed for use in the MetricGetter function
%       signatures              The data of all blocks in the signature

    % Initialize output sets
    scopeGotoAddout     = {};
    dataStoreWriteAddout = {};
    dataStoreReadAddout = {};
    scopeFromAddout     = {};
    globalGotosAddout   = {};
    globalFromsAddout   = {};
    id                  = {};
    
    % Elements in the sig
	sGa     = {};   % Scoped Gotos
	sFa     = {};   % Scoped Froms
	dSWa    = {};   % Data Store Writes
    dSRa    = {};   % Data Store Reads
    gGa     = {};   % Global Gotos
    gFa     = {};   % Global Froms
    
    metrics     = {};
    signatures  = {};
	BlockName   = get_param(address,'Name');

    % Get info on inports and outports    
    [inaddress, Inports] = InportSigData(address); 
    [outaddress, Outports] = OutportSigData(address); 
    
    % Get all blocks, but remove the current address
    allBlocks = find_system(address, 'SearchDepth', 1); 
    allBlocks = setdiff(allBlocks, address);
    
    % For every block
    for z = 1:length(allBlocks)
        BlockType = get_param(allBlocks{z}, 'BlockType');
        if strcmp(BlockType, 'SubSystem') % If it is a subsystem
            
            % Recurse into the subsystem
            [scopeGotoAddoutx, dataStoreWriteAddoutx, dataStoreReadAddoutx, ...
                scopeFromAddoutx, globalGotosAddoutx, globalFromsAddoutx, ...
                metricsx, signaturesx] = TieInStrongData(allBlocks{z}, sys, ...
                hasUpdates, docFormat, dataTypeMap); 
           
            % Append blocks found in subsystems
            sGa     = [sGa scopeGotoAddoutx]; 
            sFa     = [sFa scopeFromAddoutx];
            dSWa    = [dSWa dataStoreWriteAddoutx];
            dSRa    =  [dSRa dataStoreReadAddoutx];
            gGa     = [gGa globalGotosAddoutx];
            gFa     = [gFa globalFromsAddoutx];
            
            metrics = [metrics metricsx];
            signatures = [signatures signaturesx];
        end
    end

    % Remove duplicates
    sGa     = unique(sGa);
    sFa     = unique(sFa);
    dSWa    = unique(dSWa);
    dSRa    = unique(dSRa);
    gGa     = unique(gGa);
    gFa     = unique(gFa);

    % Find all data store reads, writes, scoped gotos/froms, and updates
    [address, scopedGoto, scopedFrom, DataStoreW, DataStoreR, Updates, ...
        GlobalGotos, GlobalFroms] = AddImplicitsStrongData(address, sGa, ...
        sFa, dSWa, dSRa,gGa,gFa, hasUpdates); 

    % Ensure block names in the updates list aren't repeated in the
    % inputs and outputs, and that those filtered lists are separate
    % from what is being passed out
    scopeGotoAddout     = scopedGoto;
    scopedGotoTags      = setdiff(scopedGoto, Updates);
    dataStoreWriteAddout = DataStoreW;
    DataStoreWrites     = setdiff(dataStoreWriteAddout, Updates);
    dataStoreReadAddout = DataStoreR;
    DataStoreReads      = setdiff(dataStoreReadAddout, Updates);
    scopeFromAddout     = scopedFrom;
    scopedFromTags      = setdiff(scopedFrom, Updates);
    globalGotosAddout   = GlobalGotos;
    globalFromsAddout   = GlobalFroms;

    % Gets declarations for the signature
    [tagDex, dsDex] = ImposedData(address);

    % For the metrics, returns a struct for each subsystem with the
    % subsystem's name and size
    size = length(Inports) + length(Outports) + length(globalGotosAddout) ... 
        + length(globalFromsAddout) + length(scopedGotoTags) ...
        + length(scopedFromTags) + length(DataStoreReads) ...
        + length(DataStoreWrites) + 2*length(Updates) + length(tagDex) ...
        + length(dsDex);
    size = num2str(size);
    system = strrep(address,'_STRONG_SIGNATURE','');
    metrics{end + 1} = struct('Subsystem', system, 'Size', size);
    % For the signatures, returns a struct for each subsystem with all
    % blocks in the signature as well as subsytem's name and size
    signatures{end + 1} = struct(...
        'Subsystem', system, ...
        'Size', size, ...
        'Inports', {Inports}, ...
        'Outports', {Outports}, ...
        'GlobalFroms', {globalFromsAddout}, ...
        'GlobalGotos', {globalGotosAddout}, ...
        'ScopedFromTags', {scopedFromTags}, ...
        'ScopedGotoTags', {scopedGotoTags}, ...
        'DataStoreReads', {DataStoreReads}, ...
        'DataStoreWrites',{DataStoreWrites}, ...
        'Updates', {Updates}, ...
        'GotoTagVisibilities', {tagDex}, ...
        'DataStoreMemories', {dsDex});
        
    % If in the matching subsystem from the function call, call the
    % function to make the text file for the signature's data
    if strcmp(sys, address) || strcmp(sys, 'All')
        DataMaker(address, Inports, Outports, scopedGotoTags, ...
            scopedFromTags, DataStoreWrites, DataStoreReads, Updates, ...
            globalGotosAddout, globalFromsAddout, tagDex, dsDex, ...
            hasUpdates, docFormat, dataTypeMap, signatures);
    end
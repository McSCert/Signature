function [scopeGotoAddout, dataStoreWriteAddout, dataStoreReadAddout, ...
    scopeFromAddout, globalGotosAddout, globalFromsAddout, metrics, ...
    signatures] = TieInStrongData(address, sys, hasUpdates, docFormat, dataTypeMap)
% TIEINSTRONGDATA Find the strong signature recursively and output as documentation.
%
%   Inputs:
%       address         Simulink model name or path.
%
%       sys             Name of the system to generate the documentation for.
%                       It can be a specific subsystem name, or 'All' to get
%                       documentation for the entire hierarchy.
%
%       hasUpdates      Number indicating whether reads and writes in the same
%                       subsystem are kept separate(0), or combined and listed
%                       as an update(1).
%
%       docFormat       Number indicating which docmentation type to
%                       generate: no doc(0), .txt(1), .tex(2), .doc(3),
%                       else no doc.
%
%       dataTypeMap     Map of blocks and their corresponding data type.
%
%   Outputs:
%       scopeGotoAddout      List of scoped gotos that the function will pass out.
%       dataStoreWriteAddout List of data store reads that the function will pass out.
%       dataStoreReadAddout  List of data store writes that the function will pass out.
%       scopeFromAddOut      List of scoped froms that the function will pass out.
%       globalGotosAddOut    List of global gotos being passed out.
%       globalFromsAddOut    List of global froms being passed out.
%
%       metrics              Cell array listing the system and its subsystems, with
%                            the size of their signature (i.e. number of elements in
%                            the signature).
%
%       signatures           Cell array of signature data for the system and its
%                            subsystems. Signature data includes: Subsystem, Size,
%                            Inports, Outports, GlobalFroms, GlobalGotos,
%                            ScopedFromTags, ScopedGotoTags, DataStoreReads,
%                            DataStoreWrites, Updates, GotoTagVisibilities, and
%                            DataStoreMemories.

    % Initialize output sets
    scopeGotoAddout         = {};
    dataStoreWriteAddout    = {};
    dataStoreReadAddout     = {};
    scopeFromAddout         = {};
    globalGotosAddout       = {};
    globalFromsAddout       = {};
    id                      = {};
    metrics                 = {};
    signatures              = {};

    % Elements in the signature being carried up from the signatures of lower levels
    sGa     = {};   % Scoped Gotos
    sFa     = {};   % Scoped Froms
    dSWa    = {};   % Data Store Writes
    dSRa    = {};   % Data Store Reads
    gGa     = {};   % Global Gotos
    gFa     = {};   % Global Froms

    BlockName = get_param(address,'Name');

    % Get signature for Inports and Outports
    Inports = InportSigData(address);
    Outports = OutportSigData(address);

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
            dSRa    = [dSRa dataStoreReadAddoutx];
            gGa     = [gGa globalGotosAddoutx];
            gFa     = [gFa globalFromsAddoutx];

            % Append subsystem metric and signature info to the outputs
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

    % Find all Data Store Reads, Writes, scoped Gotos/Froms, and updates
    [scopedGoto, scopedFrom, DataStoreW, DataStoreR, Updates, ...
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

    % Get Data Store declarations and Scoped Gotos for the signature
    [tagDex, dsDex] = ImposedData(address);

    % Append this subsystem's metric data to the output
    system = strrep(address, '_STRONG_SIGNATURE', '');
    size = length(Inports) + length(Outports) + length(globalGotosAddout) ...
        + length(globalFromsAddout) + length(scopedGotoTags) ...
        + length(scopedFromTags) + length(DataStoreReads) ...
        + length(DataStoreWrites) + 2*length(Updates) + length(tagDex) ...
        + length(dsDex);
    size = num2str(size);
    metrics{end + 1} = struct('Subsystem', system, 'Size', size);

    % Append this subsystem's signature data to the output
    signatures{end + 1} = struct(...
        'Subsystem',            system, ...
        'Size',                 size, ...
        'Inports',              {Inports}, ...
        'Outports',             {Outports}, ...
        'GlobalFroms',          {globalFromsAddout}, ...
        'GlobalGotos',          {globalGotosAddout}, ...
        'ScopedFromTags',       {scopedFromTags}, ...
        'ScopedGotoTags',       {scopedGotoTags}, ...
        'DataStoreReads',       {DataStoreReads}, ...
        'DataStoreWrites',      {DataStoreWrites}, ...
        'Updates',              {Updates}, ...
        'GotoTagVisibilities',  {tagDex}, ...
        'DataStoreMemories',    {dsDex});

   % Make the documentation file for this system
    if strcmp(sys, address) || strcmp(sys, 'All')
        DataMaker(address, Inports, Outports, scopedGotoTags, ...
            scopedFromTags, DataStoreWrites, DataStoreReads, Updates, ...
            globalGotosAddout, globalFromsAddout, tagDex, dsDex, ...
            hasUpdates, docFormat, dataTypeMap, signatures);
    end
end
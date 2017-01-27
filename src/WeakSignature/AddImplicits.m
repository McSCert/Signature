function [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, ...
    updateBlocks] = AddImplicits(address, scopeGotoAdd, scopeFromAdd, ...
    dataStoreWriteAdd, dataStoreReadAdd, hasUpdates, sys)
%   ADDIMPLICITS Add the implicit inputs and outputs (i.e., scoped Gotos
%    and Data Store Memorys) for the signature of a subsystem.
%  
% 	Inputs:
%       address             Simulink model name.
% 		scopeGotoAdd	    Additional scoped Gotos to add to the address.
%
%       scopeFromAdd        Additional scoped Froms to add to the address.
%
%       dataStoreWriteAdd   Additional Data Store Writes to add to the address.
%
% 		dataStoreReadAdd    Additional Data Store Reads to add to the address.
%
%       hasUpdates          Number indicating whether reads and writes in the
%                           same subsystem are kept separate (0), or combined 
%                           and listed as an update (1).
%                   
%       sys                 Name of the system to generate the documentation for.
%                           It can be a specific subsystem name, or 'All' to get
%                           documentation for the entire hierarchy.
%       
% 	Outputs:
%       carryUp         List of 6 lists that are carried up to the subsystem
%                       above: scoped Froms, scoped Gotos, Data Store
%                       Reads, Data Store Writes, global Froms and global
%                       Gotos.                   
%
%       fromBlocks      Set containing two matrices: that of the scoped
%                       From blocks, and that of the scoped From blocks' 
%                       corresponding terminators.
%
%
%       dataStoreWrites	Set containing two matrices: that of the Data
%                       Store Write blocks, and that of their corresponding 
%                       terminators.
%
%       dataStoreReads  Set containing two matrices: that of the Data
%                       Store Read blocks, and that of their corresponding 
%                       terminators.
%
%       gotoBlocks      Set containing two matrices: that of the scoped
%                       Goto blocks, and that of the scoped From blocks' 
%                       corresponding terminators.
%
%       updateBlocks    Set containing two matrices: that of the update
%                       blocks (represented by reads), and their corresponding
%                       terminators.

    % Initialize sets, matrices, and maps
    fromToRepo = [];
	fromTermToRepo = [];
    gotoToRepo = [];
    gotoTermToRepo = [];
	dSWriteToRepo = [];
	dSWriteTermToRepo = [];
	dSReadToRepo = [];
	dSReadTermToRepo = [];
    mapObjU = containers.Map();
    updateToRepo = [];
    updateTermToRepo = [];
    updatesToAdd = {};
 
    addSignatureAtThisLevel = strcmp(sys, 'All') || strcmp(sys, address);
        
    % Get list of all blocks
    allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);
	
    % Find all visibility tags and declarations, such that their
    % corresponding reads and writes will be added to the weak signature
    for z = 1:length(allBlocks)
        Blocktype = get_param(allBlocks{z}, 'Blocktype');
        switch Blocktype
            case 'GotoTagVisibility'
                scopeGotoAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                scopeFromAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
            case 'DataStoreMemory'
                dataStoreNameR = get_param(allBlocks{z}, 'DataStoreName');
                dataStoreReadAdd{end + 1} = dataStoreNameR;
                dataStoreName = get_param(allBlocks{z}, 'DataStoreName');
                dataStoreWriteAdd{end + 1} = dataStoreName;
        end
    end
    
    % If there is a scoped Goto in the current subsystem, this block removes
    % the Goto from the weak signature of all subsequent subsystems
    gotosRemove = {};
    gTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for g = 1:length(gTags)
        tagVisibility = get_param(gTags{g}, 'TagVisibility');
        gotoTag = get_param(gTags{g}, 'GotoTag');
        if strcmp(tagVisibility, 'scoped')
            gotosRemove{end + 1} = gotoTag;
        end
    end
    scopeGotoAdd = setdiff(scopeGotoAdd, gotosRemove);
     
    % Find blocks that are associated with declarations/visibility tags on
    % the same level that they are declared
    removableDataStoresNames = {};
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end + 1} =  get_param(removableDataStores{rds}, 'DataStoreName');  
    end
 
    removableScopedTagsNames = {};
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end + 1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end
    
    scopeFromAdd = unique(scopeFromAdd);
    scopeGotoAdd = unique(scopeGotoAdd);
    dataStoreReadAdd = unique(dataStoreReadAdd);
    dataStoreWriteAdd = unique(dataStoreReadAdd);
    
    % Make temporary variables of the lists of Data Stores/scoped tags
    % for the signatures that exclude the blocks that are not included due
    % to declarations on this level
    scopeFromAddx = setdiff(scopeFromAdd, removableScopedTagsNames);
    scopeGotoAddx = setdiff(scopeGotoAdd, removableScopedTagsNames);
    dataStoreReadAddx = setdiff(dataStoreReadAdd, removableDataStoresNames);
    dataStoreWriteAddx = setdiff(dataStoreReadAdd, removableDataStoresNames);
    
    if hasUpdates
        % Check for updates in the Data Stores, i.e. that there is a Read and
        % Write that correspond to eachother. If an update exists, it is marked
        % in the map and an update is added to the update list
        for search = 1:length(dataStoreWriteAddx)
            for check = 1:length(dataStoreReadAddx)
                readname = dataStoreReadAddx{check};
                if strcmp(readname, dataStoreWriteAddx{search})
                    flag = true;
                end
                if flag && (~isKey(mapObjU, readname))
                    updateblock = struct('Name', readname, 'Type', 'DataStoreRead');
                    mapObjU(readname) = true;
                    updatesToAdd{end + 1} = updateblock;
                end
            end
        end
        
        % Check for updates in the scoped tags, i.e. that there is a Goto and
        % From that correspond to eachother. If an update exists, it is marked
        % in the map and an update is added to the update list
        for search = 1:length(scopeFromAddx)
            for check = 1:length(scopeGotoAddx)
                readname = scopeGotoAddx{check};
                if strcmp(readname, scopeFromAddx{search})
                    flag = true;
                end
                if flag && (~isKey(mapObjU, readname))
                    updateblock = struct('Name', readname, 'Type', 'ScopedFrom');
                    mapObjU(readname) = true;
                    updatesToAdd{end + 1} = updateblock;
                end
            end
        end
    end

    num = 0;        % Goto/From number
    termnum = 0;    % Terminator number

    if addSignatureAtThisLevel

        % Add the scoped Froms on the temporary list to the model,
        % along with a terminator
        for bz = 1:length(scopeFromAddx)
            if ~isKey(mapObjU, scopeFromAddx{bz})
                from = add_block('built-in/From', [address '/FromSigScopeAdd' num2str(num)], ...
                    'GotoTag', scopeFromAddx{bz}, 'TagVisibility', 'scoped');
                fromName = ['FromSigScopeAdd' num2str(num)];

                Terminator = add_block('built-in/Terminator', [address '/TerminatorFromScopeAdd' num2str(termnum)]);
                TermName = ['TerminatorFromScopeAdd' num2str(termnum)];

                fromToRepo(end + 1) = from;
                fromTermToRepo(end + 1) = Terminator;

                add_line(address, [fromName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            end
        end

        % Reset numbering of blocks
        num = 0;
        termnum = 0;

        % Add the scoped Gotos on the temporary list to the model,
        % along with a terminator
        for bt = 1:length(scopeGotoAddx)
            if ~isKey(mapObjU, scopeGotoAddx{bt})
                from = add_block('built-in/From', [address '/GotoSigScopeAdd' num2str(num)] , ...
                    'GotoTag', scopeGotoAddx{bz}, 'TagVisibility', 'scoped');
                fromName = ['GotoSigScopeAdd' num2str(num)];

                Terminator = add_block('built-in/Terminator', [address '/TerminatorGotoScopeAdd' num2str(termnum)]);
                TermName = ['TerminatorGotoScopeAdd' num2str(termnum)];

                gotoToRepo(end + 1) = from;
                gotoTermToRepo(end + 1) = Terminator;

                add_line(address, [fromName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            end
        end

        % Reset numbering of blocks
        num = 0;
        termnum = 0;

        % Add the Data Store Writes on the temporary list to the model,
        % along with a terminator
        for by = 1:length(dataStoreWriteAddx)
            if ~isKey(mapObjU, dataStoreWriteAddx{by})
                dataStore = add_block('built-in/dataStoreRead', [address '/DataStoreWriteAdd' num2str(num)], ...
                    'DataStoreName', dataStoreWriteAddx{by});
                dataStoreName = ['DataStoreWriteAdd' num2str(num)];

                Terminator = add_block('built-in/Terminator', [address '/TerminatorDataStoreWriteAdd' num2str(termnum)]);
                TermName = ['TerminatorDataStoreWriteAdd' num2str(termnum)];

                dSWriteToRepo(end + 1) = dataStore;
                dSWriteTermToRepo(end + 1) = Terminator;

                add_line(address, [dataStoreName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            end
        end

        % Reset numbering of blocks   
        num = 0;
        termnum = 0;

        % Add the Data Store Reads on the temporary list to the model,
        % along with a terminator
        for bx = 1:length(dataStoreReadAddx)
            if ~isKey(mapObjU, dataStoreReadAddx{bx})
                dataStore = add_block('built-in/dataStoreRead', [address '/DataStoreReadAdd' num2str(num)], ...
                    'DataStoreName', dataStoreReadAddx{bx});
                Terminator = add_block('built-in/Terminator', [address '/TerminatorDataStoreReadAdd' num2str(termnum)]);

                dataStoreName = ['DataStoreReadAdd' num2str(num)];
                TermName = ['TerminatorDataStoreReadAdd' num2str(termnum)];

                dSReadToRepo(end + 1) = dataStore;
                dSReadTermToRepo(end + 1) = Terminator;

                add_line(address, [dataStoreName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            end
        end

        % Reset numbering of blocks   
        num = 0;
        termnum = 0;

        % Add the updates on the list to the model, along with a terminator
        for bw = 1:length(updatesToAdd)
            if strcmp(updatesToAdd{bw}.Type, 'DataStoreRead')
                dataStore = add_block('built-in/DataStoreRead', [address '/DataStoreUpdate' num2str(num)], ...
                     'DataStoreName', updatesToAdd{bw}.Name);
                Terminator = add_block('built-in/Terminator', [address '/TermDSUpdate' num2str(termnum)]);

                dataStoreName = ['DataStoreUpdate' num2str(num)];
                TermName = ['TermDSUpdate' num2str(termnum)];

                updateToRepo(end + 1) = dataStore;
                updateTermToRepo(end + 1) = Terminator;

                add_line(address, [dataStoreName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            else
                from = add_block('built-in/From', [address '/FromUpdate' num2str(num)], ...
                    'GotoTag', updatesToAdd{bw}.Name, 'TagVisibility', 'scoped');
                Terminator = add_block('built-in/Terminator', [address '/TermFromUpdate' num2str(termnum)]);

                fromName = ['FromUpdate' num2str(num)];
                TermName = ['TermFromUpdate' num2str(termnum)];

                updateToRepo(end + 1) = from;
                updateTermToRepo(end + 1) = Terminator;

                add_line(address, [fromName '/1'], [TermName '/1']);

                num = num + 1;
                termnum = termnum + 1;
            end
        end
    end
    
    for i = 1:length(updatesToAdd)
        updatesToAdd{i} = updatesToAdd{i}.Name;
    end

    % -- Prepare outputs --
    % Group implicit signature data in order to minimize the number of outputs
    scopedGoto = scopeGotoAdd;
    scopedFrom = scopeFromAdd;
	dataStoreW = dataStoreWriteAdd;
    dataStoreR = dataStoreReadAdd;
    carryUp = {scopedFrom, scopedGoto, dataStoreR, dataStoreW};

    % Blocks that need to be repositioned and their corresponding terminator
    % are grouped together
    fromBlocks      = {fromToRepo, fromTermToRepo};
    dataStoreWrites = {dSWriteToRepo, dSWriteTermToRepo};
    dataStoreReads  = {dSReadToRepo, dSReadTermToRepo};
    gotoBlocks      = {gotoToRepo, gotoTermToRepo};
    updateBlocks    = {updateToRepo, updateTermToRepo};
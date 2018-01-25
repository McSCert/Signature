function [scopedGoto, scopedFrom, dataStoreW, dataStoreR, removableDS, ...
    removableTags, updates] = AddImplicitsData(address, scopeGotoAdd, ...
        scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, isupdates)
% ADDIMPLICITSDATA Add the scoped Goto and Data Store signature.
%
%   Inputs:
%       address           Simulink model name or path.
%
%       scopeGotoAdd      Additional scoped gotos to add to the address.
%
%       scopeFromAdd      Additional scoped froms to add to the address.
%
%       dataStoreReadAdd  Additional data store reads to add to the address.
%
%       dataStoreWriteAdd Additional data store writes to add to the address.
%
%   Outputs:
%       scopedGoto      The scoped Goto tags that are part of the signature
%                       and are listed for documentation.
%
%       scopedFrom      The scoped From tags that are part of the signature
%                       and are listed for documentation.
%
%       dataStoreW      The Data Store Writes that are part of the signature
%                       and are listed for documentation.
%
%       dataStoreR      The Data Store Reads that are part of the signature
%                       and are listed for documentation
%
%       removableDS     The Data Stores that can be removed at a certain
%                       subsystem level.
%
%       removableTags   The removable scoped tags that can be removed at
%                       a certain subsystem level.
%
%       updates         The block names that are part of the signature and
%                       are considered updates.

    mapObjU = containers.Map(); % Map for updates
    updatesToAdd = {};

    % Find all blocks in the system
    allBlocks = find_system(address, 'SearchDepth', 1);
    allBlocks = setdiff(allBlocks, address);

    % Iterate through all the blocks to find declarations of tags and Data
    % Stores. Then, add the name of the declaration to the lists of reads,
    % writes, gotos, and froms to carry down
    for z = 1:length(allBlocks)
        Blocktype = get_param(allBlocks{z}, 'Blocktype');
        switch Blocktype
            case 'GotoTagVisibility'
                scopeGotoAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                scopeFromAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
            case 'DataStoreMemory'
                DataStoreNameR = get_param(allBlocks{z}, 'DataStoreName');
                dataStoreReadAdd{end + 1} = DataStoreNameR;
                DataStoreName = get_param(allBlocks{z}, 'DataStoreName');
                dataStoreWriteAdd{end + 1} = DataStoreName;
        end
    end

    % Find Gotos that can be removed from the scoped Gotos to add list
    gotosRemove = {};
    gTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for g = 1:length(gTags)
        tagVisibility = get_param(gTags{g}, 'TagVisibility');
        gotoTag = get_param(gTags{g}, 'GotoTag');
        if strcmp(tagVisibility, 'scoped')
            gotosRemove{end + 1} = gotoTag;
        end
    end

    scopeGotoAdd = setdiff(scopeGotoAdd, gotosRemove); % removes the removable gotos

    removableDataStoresNames = {};
    removableScopedTagsNames = {};

    % These two blocks make lists of tags and Data Stores that, for this
    % level, can be removed since the declaration exists on this level
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end + 1} = get_param(removableDataStores{rds}, 'DataStoreName');
    end
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end + 1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end

    % Remove duplicates
    scopeFromAdd = unique(scopeFromAdd);
    scopeGotoAdd = unique(scopeGotoAdd);
    dataStoreReadAdd = unique(dataStoreReadAdd);
    dataStoreWriteAdd = unique(dataStoreReadAdd);

    % Check for updates of the Data Store variety and add them to the
    % update list
    if isupdates
        for search = 1:length(dataStoreWriteAdd)
            for check = 1:length(dataStoreReadAdd)
                readname = dataStoreReadAdd{check};
                if strcmp(readname,dataStoreWriteAdd{search})
                    flag = true;
                end
                if flag && (~isKey(mapObjU, readname))
                    updatesToAdd{end + 1} = readname;
                end
            end
        end

        % Check for updates of the scoped tags variety and add them to the
        % update list
        for search = 1:length(scopeFromAdd)
            for check = 1:length(scopeGotoAdd)
                readname = scopeGotoAdd{check};
                if strcmp(readname,scopeFromAdd{search})
                    flag = true;
                end
                if flag && (~isKey(mapObjU, readname))
                    updatesToAdd{end + 1} = readname;
                end
            end
        end
    end

    % Assign outputs
    updates         = updatesToAdd;
    scopedFrom      = scopeFromAdd;
    scopedGoto      = scopeGotoAdd;
    dataStoreW      = dataStoreWriteAdd;
    dataStoreR      = dataStoreReadAdd;
    removableDS     = removableDataStoresNames;
    removableTags   = removableScopedTagsNames;
end
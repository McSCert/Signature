function [address, scopedGoto, scopedFrom, dataStoreW, dataStoreR, ... 
    updates, globalGotos, globalFroms] = AddImplicitsStrongData(address, ...
    scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, ...
    globalGotosAdd, globalFromsAdd, hasUpdates)
% ADDIMPLICITSSTRONGDATA Find implicit inputs/outputs for the signature.
%
%   Inputs:
%       address         Simulink system path.
%
%       scopeGotoAdd    List of all scoped Gotos being passed in to be
%                       potentially added to the signature.
%
%       scopeFromAdd    List of all scoped Froms being passed in to be
%                       potentially added to the signature.
%
%       dataStoreWriteAdd List of all Data Store Writes being passed in to be
%                         potentially added to the signature.
%
%       dataStoreReadAdd List of all Data Store Reads being passed in to be
%                       potentially added to the signature.
%
%       hasUpdates      Boolean indicating whether updates are included in the signature.
%
%   Outputs:
%       address     Simulink system path.
%
%       scopedGoto  List of all scoped Gotos that will be included in the
%                   signature(unless they are part of an update).
%
%       scopedFrom  List of all scoped Froms that will be included in the
%                   signature(unless they are part of an update).
%
%       dataStoreW  List of all Data Store Writes that will be included
%                   in the signature (unless they are part of an update).
%
%       dataStoreR  List of all Data Store Reads that will be included in
%                   the signature(unless they are part of an update).
%
%       updates     List of all updates to pass out for this subsystem that
%                   will be included in the signature.
%
%       globalGotos List of all global Gotos to pass out for this subsystem that
%                   will be included in the signature.
%
%       globalFroms List of all global Froms to pass out for this subsystem that
%                   will be included in the signature.

    % Hash maps keeping track of if a block of a certain name has already 
    % been counted towards one or more of the lists
	mapObjDR = containers.Map();
    mapObjDW = containers.Map();
	mapObjF = containers.Map();
    mapObjG = containers.Map();
    mapObjU = containers.Map();
    updatesToAdd = {};
    removableDataStoresNames = {};
    removableScopedTagsNames = {};
    removableScopedFromsNames = {};
    removableglobalFromsNames = {};
   
    % The next three lines find all Data Store declarations, such that their
    % respective reads and writes can be removed from the list of Data Store Reads and writes to be
    % passed out
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end + 1} = get_param(removableDataStores{rds}, 'DataStoreName');   
    end
    
    % Prevejt the removable Data Stores from once more being added to the
    %  list of Data Store Reads, writes, or updates to be passed out
    for dsname = 1:length(removableDataStoresNames)
        mapObjDR(removableDataStoresNames{dsname}) = true;
        mapObjDW(removableDataStoresNames{dsname}) = true;
        mapObjU(removableDataStoresNames{dsname}) = true;
    end
    
    % Tag visibility declarations are found, and their respective Gotos and
    % Froms can be removed from the list of scoped Gotos and Froms to be 
    % passed out
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end + 1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end
    
    % Prevent the removable scoped Gotos/Froms from being once more added
    %  to the list of scoped Gotos, Froms, or updates to be passed out
    for stname = 1:length(removableScopedTagsNames)
        mapObjF(removableScopedTagsNames{stname}) = true;
        mapObjG(removableScopedTagsNames{stname}) = true;
    end
    
    % Members of scoped tags outputs are found and used to remove scoped tag
    % inputs, and global Gotos are found and used to remove global Froms.
    removableScopedFroms = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for rsi = 1:length(removableScopedFroms)
        tagVis = get_param(removableScopedFroms{rsi},'TagVisibility');
        if strcmp(tagVis, 'scoped')
            removableScopedFromsNames{end + 1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        elseif strcmp(tagVis, 'global')
            removableglobalFromsNames{end + 1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        end
    end
    removableScopedFromsNames = [removableScopedFromsNames scopeGotoAdd];
    removableglobalFromsNames = [removableglobalFromsNames globalGotosAdd];
    
    % Remove the removable scoped tag inputs
    for frname = 1:length(removableScopedFromsNames)
        mapObjF(removableScopedFromsNames{frname}) = true;
    end
    
    % Remove the removable global Froms
    for ggname = 1:length(removableglobalFromsNames)
        mapObjF(removableglobalFromsNames{ggname}) = true;
    end
    
    % Remove all removable blocks from respective lists
    scopeGotoAdd        = setdiff(scopeGotoAdd, removableScopedTagsNames);
    scopeFromAdd        = setdiff(setdiff(scopeFromAdd, removableScopedTagsNames), removableScopedFromsNames);
    dataStoreWriteAdd   = setdiff(dataStoreWriteAdd, removableDataStoresNames);
    dataStoreReadAdd    = setdiff(dataStoreReadAdd, removableDataStoresNames);
    globalFromsAdd      = setdiff(globalFromsAdd, removableglobalFromsNames);
    
    if hasUpdates
        % Search the current subsystem for blocks that could be Data Store
        % updates
        possibleUpdatesR = find_system(address, 'SearchDepth', 1, 'BlockType', 'dataStoreRead');
        possibleUpdatesW = find_system(address, 'SearchDepth', 1, 'BlockType', 'dataStoreWrite');
        possibleUpdatesNamesR = {};
        possibleUpdatesNamesW = {};
        
        % Get all potential Data Store update blocks names
        for rnames = 1:length(possibleUpdatesW)
            possibleUpdatesNamesW{end + 1} = get_param(possibleUpdatesW{rnames}, 'DataStoreName');
        end
        for wnames = 1:length(possibleUpdatesR)
            possibleUpdatesNamesR{end + 1} = get_param(possibleUpdatesR{wnames}, 'DataStoreName');
        end
        
        % Include all Data Store Reads/Writes that could be part of an
        % update from the lower systems, and then filter out repeated block
        % names and the removable block names
        possibleUpdatesNamesR = [possibleUpdatesNamesR, dataStoreReadAdd];
        possibleUpdatesNamesW = [possibleUpdatesNamesW, dataStoreWriteAdd];
        possibleUpdatesNamesR = unique(possibleUpdatesNamesR);
        possibleUpdatesNamesW = unique(possibleUpdatesNamesW);
        possibleUpdatesNamesR = setdiff(possibleUpdatesNamesR, removableDataStoresNames);
        possibleUpdatesNamesW = setdiff(possibleUpdatesNamesW, removableDataStoresNames);
        
        % Find the block names common to possible update Data Store Reads
        % and Writes, thus indicating an update
        possibleUpdatesNames = intersect(possibleUpdatesNamesW, possibleUpdatesNamesR);
        
        % Go through all updates and put their names into the maps for Reads,
        % Writes, and updates (so they can't be added more than once to Reads 
        % or Writes when already an update) and add the name to lists of updates, 
        % Reads, and Writes to be passed out
        for names = 1:length(possibleUpdatesNames)
            readname = possibleUpdatesNames{names};
            mapObjU(readname) = true;
            mapObjDR(readname) = true;
            mapObjDW(readname) = true;
            updatesToAdd{end + 1} = readname;
            dataStoreReadAdd{end + 1} = readname;
            dataStoreWriteAdd{end + 1} = readname;
        end
        
        % Search subsystem for blocks that could be scoped Goto/From updates
        possibleUpdatesF = find_system(address, 'SearchDepth', 1, 'BlockType', 'From');
        possibleUpdatesG = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
        possibleUpdatesNamesF = {};
        possibleUpdatesNamesG = {};
        
        % Get all potential scoped Goto/From update block names
        for gnames = 1:length(possibleUpdatesG)
            if strcmp(get_param(possibleUpdatesG{gnames}, 'TagVisibility'), 'scoped')
                possibleUpdatesNamesG{end + 1} = get_param(possibleUpdatesG{gnames}, 'GotoTag');
            end
        end
        for fnames = 1:length(possibleUpdatesF)
            possibleUpdatesNamesF{end + 1} = get_param(possibleUpdatesF{fnames}, 'GotoTag');
        end
        
        % Include all scoped Gotos and Froms that could be part of an
        % update from the lower systems, and then filter out repeated block
        % names and the removable block names.
        possibleUpdatesNamesF = [possibleUpdatesNamesF, scopeFromAdd];
        possibleUpdatesNamesG = [possibleUpdatesNamesG, scopeGotoAdd];
        possibleUpdatesNamesF = unique(possibleUpdatesNamesF);
        possibleUpdatesNamesG = unique(possibleUpdatesNamesG);
        possibleUpdatesNamesF = setdiff(possibleUpdatesNamesF, removableScopedTagsNames);
        possibleUpdatesNamesG = setdiff(possibleUpdatesNamesG, removableScopedTagsNames);
        
        % Find the block names common to possible update Goto and Froms, 
        % thus indicating an update
        possibleUpdatesTagsNames = intersect(possibleUpdatesNamesG, possibleUpdatesNamesF);
        
        % Go through all updates and put their names into the maps for Froms,
        % Gotos, and updates (so they can't be added more than once to reads or writes when
        % already an update) and add the name to lists of updates, Froms, and
        % Gotos to be passed out
        for names = 1:length(possibleUpdatesTagsNames)
            readname = possibleUpdatesTagsNames{names};
            mapObjU(readname) = true;
            mapObjF(readname) = true;
            mapObjG(readname) = true;
            updatesToAdd{end + 1} = readname;
            scopeFromAdd{end + 1} = readname;
            scopeGotoAdd{end + 1} = readname;
        end
    end
    
    % Remove duplicates
    updatesToAdd = unique(updatesToAdd);
    dataStoreReadAdd = unique(dataStoreReadAdd);
    dataStoreWriteAdd = unique(dataStoreWriteAdd);
    scopeGotoAdd = unique(scopeGotoAdd);
    scopeFromAdd = unique(scopeFromAdd);
    
    % Avoid finding the same blocks more than once, by marking the hashmaps
    % for their respective blocktype
	for bz = 1:length(scopeFromAdd)
		mapObjF(scopeFromAdd{bz}) = true;
    end
    
    for bt = 1:length(scopeGotoAdd)
		mapObjG(scopeGotoAdd{bt}) = true;
    end
    
    for by = 1:length(dataStoreWriteAdd)
        mapObjDW(dataStoreWriteAdd{by}) = true;
    end
    
    for bx = 1:length(dataStoreReadAdd)
        mapObjDR(dataStoreReadAdd{bx}) = true;
    end
    
    for bw = 1:length(updatesToAdd)
        mapObjDR(updatesToAdd{bw}) = true;
        mapObjDW(updatesToAdd{bw}) = true;
    end
    
    % Make a list of all blocks in the subsystem
	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);
    
    % For each of the blocks in said list, add Data Store Reads and writes,
    % and scoped Froms and Gotos to their respective lists to pass out, if
    % not already marked on the hashmap
	for z = 1:length(allBlocks)
		Blocktype = get_param(allBlocks{z}, 'Blocktype');
        
		switch Blocktype
            case 'Goto'
                tagVisibility = get_param(allBlocks{z}, 'TagVisibility');
                if strcmp(tagVisibility, 'scoped')
                    GotoTag = get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjG, GotoTag))
                        mapObjG(allBlocks{z}) = true;
                        scopeGotoAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                    end
                elseif strcmp(tagVisibility, 'global')
                    GotoTag = get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjG, GotoTag))
                        mapObjG(allBlocks{z}) = true;
                        globalGotosAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                    end
                end
			case 'From'
                gotoConnected  =  get_param(allBlocks{z}, 'GotoBlock');
				tagVisibility = get_param(gotoConnected.handle, 'tagVisibility');
				if strcmp(tagVisibility, 'scoped')
					GotoTag = get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjF, GotoTag));
                        mapObjF(allBlocks{z}) = true;
                        scopeFromAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                    end
                elseif strcmp(tagVisibility, 'global')
                    GotoTag = get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjF, GotoTag))
                        mapObjF(allBlocks{z}) = true;
                        globalFromsAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                    end
				end
			case 'DataStoreRead'
				DataStoreName = get_param(allBlocks{z}, 'DataStoreName');
 				if ~(isKey(mapObjDR, DataStoreName))
                    mapObjDR(allBlocks{z}) = true;
                    dataStoreReadAdd{end + 1} = DataStoreName;
                end
			case 'DataStoreWrite'
				DataStoreName = get_param(allBlocks{z}, 'DataStoreName');
				if ~(isKey(mapObjDW, DataStoreName))
                    mapObjDW(allBlocks{z}) = true;
                    dataStoreWriteAdd{end + 1} = DataStoreName;
				end	
		end
    end
    
    % Remove duplicates
	scopedGoto  = unique(scopeGotoAdd);
	scopedFrom  = unique(scopeFromAdd);
    dataStoreR  = unique(dataStoreReadAdd);
	dataStoreW  = unique(dataStoreWriteAdd);
    updates     = unique(updatesToAdd);
    globalGotos = unique(globalGotosAdd);
    globalFroms = unique(globalFromsAdd);
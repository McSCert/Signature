function [address, scopedGoto, scopedFrom, dataStoreW, dataStoreR, updates, globalGotos, globalFroms]=AddImplicitsStrongData(address, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, globalGotosAdd, globalFromsAdd, isupdates)
    
    %addDataStoreGotoStrongTable - Called to find all implicit inputs and
    %                              outputs for the signature of a subsystem.
    %
    %                               OUTPUTS
    %
    %-address is the address of the subsystem
    %-scopedGoto is a list of all scoped Gotos that will be included in the
    %signature(unless they are part of an update)
    %-scopedFrom is a list of all scoped Froms that will be included in the
    %signature(unless they are part of an update)
    %-dataStoreW is a list of all data store writes that will be included
    %in the signature (unless they are part of an update)
    %-dataStoreR is a list of all data store reads that will be included in
    %the signature(unless they are part of an update)
    %-updates is a list of all updates to pass out for this subsystem that
    %will be included in the signature.
    %globalGotos is a list of all global gotos to pass out for this subsystem that
    %will be included in the signature.
    %globalFroms is a list of all global froms to pass out for this subsystem that
    %will be included in the signature.
    %
    %                               INPUTS
    %
    %-address
    %-scopeGotoAdd is a list of all scoped gotos being passed in to be
    %potentially added to the signature.
    %-scopeFromAdd is a list of all scoped froms being passed in to be
    %potentially added to the signature.
    %-dataStoreWriteAdd is a list of all data store writes being passed in to be
    %potentially added to the signature.
    %-dataStoreReadAdd is a list of all data store reads being passed in to be
    %potentially added to the signature.
    %-isupdates is a binary digit indicating whether updates are enabled.

	mapObjDR = containers.Map();%these map objects are hash maps keeping track of if a block of a certain name has already been counted towards one or more of the lists
    mapObjDW = containers.Map();
	mapObjF = containers.Map();
    mapObjG=containers.Map();
    mapObjU=containers.Map();
    updatesToAdd={};
    removableDataStoresNames = {};
    removableScopedTagsNames = {};
    removableScopedFromsNames = {};
    removableglobalFromsNames = {};
    flag=0;
    
    %The next three lines find all data store declarations, such that their
    %respective reads and writes can be removed from the list of data store reads and writes to be
    %passed out.
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end+1} = get_param(removableDataStores{rds}, 'DataStoreName');   
    end
    
    %This loop prevents the removable data stores from once more being
    %added to the list of data store reads, writes, or updates to be passed
    %out.
    for dsname = 1:length(removableDataStoresNames)
        mapObjDR(removableDataStoresNames{dsname})=true;
        mapObjDW(removableDataStoresNames{dsname})=true;
        mapObjU(removableDataStoresNames{dsname})=true;
    end
    
    %Tag visibility declarations are found, and there respective gotos and
    %froms can be removed from the list of scoped gotos and froms to be passed
    %out.
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end+1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end
    
    %This loop prevents the removable scoped gotos/froms from being once
    %more added to the list of scoped gotos, froms, or updates to be passed
    %out.
    for stname = 1:length(removableScopedTagsNames)
        mapObjF(removableScopedTagsNames{stname})=true;
        mapObjG(removableScopedTagsNames{stname})=true;
    end
    
    %Members of scoped tags outputs are found and used to remove scoped tag
    %inputs, and global gotos are found and used to remove global froms.
    removableScopedFroms = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for rsi = 1:length(removableScopedFroms)
        tagVis=get_param(removableScopedFroms{rsi},'TagVisibility');
        if strcmp(tagVis, 'scoped')
            removableScopedFromsNames{end+1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        elseif strcmp(tagVis, 'global')
            removableglobalFromsNames{end+1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        end
    end
    removableScopedFromsNames=[removableScopedFromsNames scopeGotoAdd];
    removableglobalFromsNames=[removableglobalFromsNames globalGotosAdd];
    
    %removal of removable scoped tag inputs
    for frname=1:length(removableScopedFromsNames)
        mapObjF(removableScopedFromsNames{frname})=true;
    end
    
    %removal of removable global froms
    for ggname=1:length(removableglobalFromsNames)
        mapObjF(removableglobalFromsNames{ggname})=true;
    end
    
    %The removal of all removable blocks from respective lists.
    scopeGotoAdd=setdiff(scopeGotoAdd, removableScopedTagsNames);
    scopeFromAdd=setdiff(setdiff(scopeFromAdd, removableScopedTagsNames), removableScopedFromsNames);
    dataStoreWriteAdd=setdiff(dataStoreWriteAdd, removableDataStoresNames);
    dataStoreReadAdd=setdiff(dataStoreReadAdd, removableDataStoresNames);
    globalFromsAdd=setdiff(globalFromsAdd, removableglobalFromsNames);
    
    if isupdates
        %Searches the current subsystem for all blocks that could be data store
        %updates.
        possibleUpdatesR = find_system(address, 'SearchDepth', 1, 'BlockType', 'dataStoreRead');
        possibleUpdatesW = find_system(address, 'SearchDepth', 1, 'BlockType', 'dataStoreWrite');
        possibleUpdatesNamesR={};
        possibleUpdatesNamesW={};
        
        %Make lists of all potential data store update blocks names.
        for rnames=1:length(possibleUpdatesW)
            possibleUpdatesNamesW{end+1}=get_param(possibleUpdatesW{rnames}, 'DataStoreName');
        end
        
        for wnames=1:length(possibleUpdatesR)
            possibleUpdatesNamesR{end+1}=get_param(possibleUpdatesR{wnames}, 'DataStoreName');
        end
        
        %Include all data store reads and writes that could be part of an
        %update from the lower systems, and then filter out repeated block
        %names and the removable block names.
        possibleUpdatesNamesR=[possibleUpdatesNamesR, dataStoreReadAdd];
        possibleUpdatesNamesW=[possibleUpdatesNamesW, dataStoreWriteAdd];
        possibleUpdatesNamesR=unique(possibleUpdatesNamesR);
        possibleUpdatesNamesW=unique(possibleUpdatesNamesW);
        possibleUpdatesNamesR=setdiff(possibleUpdatesNamesR, removableDataStoresNames);
        possibleUpdatesNamesW=setdiff(possibleUpdatesNamesW, removableDataStoresNames);
        
        %Find the block names common to possible update read and writes, thus indicating an
        %update.
        possibleUpdatesNames=intersect(possibleUpdatesNamesW, possibleUpdatesNamesR);
        
        %Go through all updates and put their names into the maps for reads,
        %writes, and updates (so they can't be added more than once to reads or writes when
        %already and update) and add the name to lists of updates, reads, and
        %writes to be passed out.
        for names=1:length(possibleUpdatesNames)
            readname=possibleUpdatesNames{names};
            mapObjU(readname)=true;
            mapObjDR(readname)=true;
            mapObjDW(readname)=true;
            updatesToAdd{end+1}=readname;
            dataStoreReadAdd{end+1}=readname;
            dataStoreWriteAdd{end+1}=readname;
        end
        
        %Search subsystem for all blocks that could possibly be scoped
        %goto/from updates.
        possibleUpdatesF = find_system(address, 'SearchDepth', 1, 'BlockType', 'From');
        possibleUpdatesG = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
        possibleUpdatesNamesF={};
        possibleUpdatesNamesG={};
        
        %Make lists of all potential scoped goto/from update block names
        for gnames=1:length(possibleUpdatesG)
            if strcmp(get_param(possibleUpdatesG{gnames}, 'TagVisibility'), 'scoped')
                possibleUpdatesNamesG{end+1}=get_param(possibleUpdatesG{gnames}, 'GotoTag');
            end
        end
        
        for fnames=1:length(possibleUpdatesF)
            possibleUpdatesNamesF{end+1}=get_param(possibleUpdatesF{fnames}, 'GotoTag');
        end
        
        %Include all scoped gotos and froms that could be part of an
        %update from the lower systems, and then filter out repeated block
        %names and the removable block names.
        possibleUpdatesNamesF=[possibleUpdatesNamesF, scopeFromAdd];
        possibleUpdatesNamesG=[possibleUpdatesNamesG, scopeGotoAdd];
        possibleUpdatesNamesF=unique(possibleUpdatesNamesF);
        possibleUpdatesNamesG=unique(possibleUpdatesNamesG);
        possibleUpdatesNamesF=setdiff(possibleUpdatesNamesF, removableScopedTagsNames);
        possibleUpdatesNamesG=setdiff(possibleUpdatesNamesG, removableScopedTagsNames);
        
        %Find the block names common to possible update goto and froms, thus indicating an
        %update.
        possibleUpdatesTagsNames=intersect(possibleUpdatesNamesG, possibleUpdatesNamesF);
        
        %Go through all updates and put their names into the maps for froms,
        %gotos, and updates (so they can't be added more than once to reads or writes when
        %already an update) and add the name to lists of updates, froms, and
        %gotos to be passed out.
        for names=1:length(possibleUpdatesTagsNames)
            readname=possibleUpdatesTagsNames{names};
            mapObjU(readname)=true;
            mapObjF(readname)=true;
            mapObjG(readname)=true;
            updatesToAdd{end+1}=readname;
            scopeFromAdd{end+1}=readname;
            scopeGotoAdd{end+1}=readname;
        end
    end
    %remove all repeated information from lists
    updatesToAdd=unique(updatesToAdd);
    dataStoreReadAdd=unique(dataStoreReadAdd);
    dataStoreWriteAdd=unique(dataStoreWriteAdd);
    scopeGotoAdd=unique(scopeGotoAdd);
    scopeFromAdd=unique(scopeFromAdd);
    
    %Avoid finding the same blocks more than once, by marking the hashmaps
    %for their respective blocktype
	for bz=1:length(scopeFromAdd)
		mapObjF(scopeFromAdd{bz})=true;
    end
    
    for bt=1:length(scopeGotoAdd)
		mapObjG(scopeGotoAdd{bt})=true;
    end
    
    for by=1:length(dataStoreWriteAdd)
        mapObjDW(dataStoreWriteAdd{by})=true;
    end
    
    for bx=1:length(dataStoreReadAdd)
        mapObjDR(dataStoreReadAdd{bx})=true;
    end
    
    for bw=1:length(updatesToAdd)
        mapObjDR(updatesToAdd{bw})=true;
        mapObjDW(updatesToAdd{bw})=true;
    end
    
    %Make a list of all blocks in the subsystem
	allBlocks=find_system(address, 'SearchDepth', 1);
	allBlocks=setdiff(allBlocks, address);
    %For each of the blocks in said list, add data store reads and writes,
    %and scoped froms and gotos to their respective lists to pass out, if
    %not already marked on the hashmap.
	for z=1:length(allBlocks)
		Blocktype=get_param(allBlocks{z}, 'Blocktype');
		switch Blocktype
            case 'Goto'
                tagVisibility=get_param(allBlocks{z}, 'TagVisibility');
                if strcmp(tagVisibility, 'scoped')
                    GotoTag=get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjG, GotoTag))
                        mapObjG(allBlocks{z})=true;
                        scopeGotoAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                    end
                elseif strcmp(tagVisibility, 'global')
                    GotoTag=get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjG, GotoTag))
                        mapObjG(allBlocks{z})=true;
                        globalGotosAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                    end
                end
			case 'From'
                gotoConnected = get_param(allBlocks{z}, 'GotoBlock');
				tagVisibility=get_param(gotoConnected.handle, 'tagVisibility');
				if strcmp(tagVisibility, 'scoped')
					GotoTag=get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjF, GotoTag));
                        mapObjF(allBlocks{z})=true;
                        scopeFromAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                    end
                elseif strcmp(tagVisibility, 'global')
                    GotoTag=get_param(allBlocks{z}, 'GotoTag');
                    if ~(isKey(mapObjF, GotoTag))
                        mapObjF(allBlocks{z})=true;
                        globalFromsAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                    end
				end
			case 'DataStoreRead'
				DataStoreName=get_param(allBlocks{z}, 'DataStoreName');
 				if ~(isKey(mapObjDR, DataStoreName))
                    mapObjDR(allBlocks{z})=true;
                    dataStoreReadAdd{end+1}=DataStoreName;
                end

			case 'DataStoreWrite'
				DataStoreName=get_param(allBlocks{z}, 'DataStoreName');
				if ~(isKey(mapObjDW, DataStoreName))
                    mapObjDW(allBlocks{z})=true;
                    dataStoreWriteAdd{end+1}=DataStoreName;
				end	
		end
    end
    
    
    %Final check to make sure all of the names in each list are unique.
	scopedGoto=unique(scopeGotoAdd);
	scopedFrom=unique(scopeFromAdd);
    dataStoreR=unique(dataStoreReadAdd);
	dataStoreW=unique(dataStoreWriteAdd);
    updates=unique(updatesToAdd);
    globalGotos=unique(globalGotosAdd);
    globalFroms=unique(globalFromsAdd);
end
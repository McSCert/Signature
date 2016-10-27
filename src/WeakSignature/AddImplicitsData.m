function [address, scopedGoto, scopedFrom, dataStoreW, dataStoreR, removableDS, removableTags, updates]=AddImplicitsData(address, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, isupdates)
	%  addDataStoreGoto - A function that adds the scoped Goto and Data
	%  Store Signature
    %  
	%	Inputs:
	%		address: the name and location of the system
    %
	%		scopeGotoAdd: additional scoped gotos to add to the address
    %
    %       scopeFromAdd: additional scoped froms to add to the address
    %
	%		dataStoreReadAdd: additional data store reads to add to the address
    %
    %       dataStoreWriteAdd: additional data store writes to add to the address
    %       
	%	Outputs:
	%		scopedGoto: the scoped goto tags that are part of the signature
	%		and are listed for documentation.
    %
	%		scopedFrom: the scoped from tags that are part of the signature
	%		and are listed for documentation
    %
    %       dataStoreW: the data store writes that are part of the signature
	%		and are listed for documentation
    %
    %       dataStoreR: the data store reads that are part of the signature
	%		and are listed for documentation
    %
    %       removableDS: the data stores that can be removed at a certain
    %           subsystem level.
    %
    %       removableTags: the removable scoped tags that can be removed at
    %           a certain subsystem level
    %
    %       updates: the blocknames that are part of the signature and are
    %       considered updates.
	%
	mapObjU=containers.Map();%map for updates
    updatesToAdd={};
    %find all blocks in the system
    allBlocks=find_system(address, 'SearchDepth', 1);
	allBlocks=setdiff(allBlocks, address);
	
    %Iterate through all the blocks to find declarations of tags and data
    %stores. Then, adds the name of the declaration to the lists of reads,
    %writes, gotos, and froms to carry down.
    for z=1:length(allBlocks)
        Blocktype=get_param(allBlocks{z}, 'Blocktype');
        switch Blocktype
            case 'GotoTagVisibility'
                scopeGotoAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                scopeFromAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
            case 'DataStoreMemory'
                DataStoreNameR=get_param(allBlocks{z}, 'DataStoreName');
                dataStoreReadAdd{end+1}=DataStoreNameR;
                DataStoreName=get_param(allBlocks{z}, 'DataStoreName');
                dataStoreWriteAdd{end+1}=DataStoreName;
        end
    end
    
    %This block finds gotos that can be removed from the scoped gotos to
    %add.
    gotosRemove={};
    gTags=find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for g=1:length(gTags)
        tagVisibility=get_param(gTags{g}, 'TagVisibility');
        gotoTag=get_param(gTags{g}, 'GotoTag');
        if strcmp(tagVisibility, 'scoped')
            gotosRemove{end+1}=gotoTag;
        end
    end
    
    scopeGotoAdd=setdiff(scopeGotoAdd, gotosRemove); %removes the removable gotos
    
    removableDataStoresNames = {};
    removableScopedTagsNames = {};
    
    %These two blocks make lists of tags and data stores that, for this
    %level, can be removed since the declaration exists on this level.
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end+1} =  get_param(removableDataStores{rds}, 'DataStoreName');  
    end
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end+1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end
    
    %gets rid of repeated names
    scopeFromAdd=unique(scopeFromAdd);
    scopeGotoAdd=unique(scopeGotoAdd);
    dataStoreReadAdd=unique(dataStoreReadAdd);
    dataStoreWriteAdd=unique(dataStoreReadAdd);
    
    %checks for updates of the data store variety and adds them to the
    %update list
    if isupdates
        for search=1:length(dataStoreWriteAdd)
            for check=1:length(dataStoreReadAdd)
                readname=dataStoreReadAdd{check};
                if strcmp(readname,dataStoreWriteAdd{search})
                    flag = true;
                end
                if flag&&(~isKey(mapObjU, readname))
                    updatesToAdd{end+1}=readname;
                end
            end
        end
        
        %checks for updates of the scoped tags variety and adds them to the
        %update list
        for search=1:length(scopeFromAdd)
            for check=1:length(scopeGotoAdd)
                readname=scopeGotoAdd{check};
                if strcmp(readname,scopeFromAdd{search})
                    flag = true;
                end
                if flag&&(~isKey(mapObjU, readname))
                    updatesToAdd{end+1}=readname;
                end
            end
        end
    end
    %assigns the output variables
    updates= updatesToAdd;
    scopedFrom=scopeFromAdd;
    scopedGoto=scopeGotoAdd;
	dataStoreW=dataStoreWriteAdd;
    dataStoreR=dataStoreReadAdd;
    removableDS=removableDataStoresNames;
    removableTags=removableScopedTagsNames;
function [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, updateBlocks]=AddImplicits(address, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, updates)
	%  addDataStoreGoto - A function that adds the scoped Goto and Data
	%  Store Signature
    %
    %   Typical use:
    %		[address, scopedGoto, DataStoreX, DGSGotoLength, fromToRepo, TermToRepo, dSWriteToRepo, dSWriteTermToRepo]=addDataStoreGoto(address, scopeGotoAdd,DataStoreAdd)
    %  
	%	Inputs:
	%		address: the name and location in the 
	%		scopeGotoAdd: additional scoped gotos to add to the address
	%		dataStoreReadAdd: additional data stores reads to add to the address
    %       dataStoreWriteAdd: additional data stores writes to add to the address
	%	Outputs:
	%		scopedGoto: the scoped goto tags that need to be repositioned and
	%			added to the lower subsystems
    %		scopedFrom: the scoped from tags that need to be repositioned and
	%			added to the lower subsystems
	%		dataStoreW: the data store writes that need to be repositioned and
	%			added to the lower subsystems
    %		dataStoreR: the data store reads that need to be repositioned and
	%			added to the lower subsystems
	%		GotoLength: max lengh of the Goto tag and dataStoreNames
	%		fromToRepo: vector of handles of the Froms to reposition
	%		TermToRepo: vector of handles of the terminator to the Froms
	%			to reposition
	%		dSWriteToRepo: vector of handles of the dataStoreReads to reposition
	%		dSWriteTermToRepo: vector of handles of the Terminators to the
	%			dataStoreReads 
    %       gotoToRepo: vector of handles of the Gotos to reposition
    %       gotoTermToRepo: vector of handles of the Terminators to the Froms
    %           to reposition.
    %       dSReadToRepo: vector of handles of dataStoreWrites to
    %           reposition.
    %       dSReadTermToRepo: vector of handles of the Terminators to the
    %           dataStoreWrites to reposition
    %       updateToRepo: vector of handles of the dataStoreReads of
    %           updates to reposition.
    %       updateTermToRepo: vector of handles of the Terminators to the
    %           updates to reposition.
	%
    
    %Initializes sets, matrices, and maps.
	num=0;
	termnum=0;
	fromToRepo=[];
	fromTermToRepo=[];
	gotoToRepo=[];
	gotoTermToRepo=[];
	dSWriteToRepo=[];
	dSWriteTermToRepo=[];
	dSReadToRepo=[];
	dSReadTermToRepo=[];
    mapObjU=containers.Map();
    updateToRepo=[];
    updateTermToRepo=[];
    updatesToAdd={};
    
    %get list of all blocks
    allBlocks=find_system(address, 'SearchDepth', 1);
	allBlocks=setdiff(allBlocks, address);
	
    %Find all visibility tags and declarations, such that their
    %corresponding reads and writes will be added to the weak signature.
    for z=1:length(allBlocks)
        Blocktype=get_param(allBlocks{z}, 'Blocktype');
        switch Blocktype
            case 'GotoTagVisibility'
                scopeGotoAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
                scopeFromAdd{end+1}=get_param(allBlocks{z}, 'GotoTag');
            case 'DataStoreMemory'
                dataStoreNameR=get_param(allBlocks{z}, 'DataStoreName');
                dataStoreReadAdd{end+1}=dataStoreNameR;
                dataStoreName=get_param(allBlocks{z}, 'DataStoreName');
                dataStoreWriteAdd{end+1}=dataStoreName;
        end
    end
    
    %if there is a scoped goto in the current subsystem, this block removes
    %the goto from the weak signature of all subsequent subsystems.
    gotosRemove={};
    gTags=find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for g=1:length(gTags)
        tagVisibility=get_param(gTags{g}, 'TagVisibility');
        gotoTag=get_param(gTags{g}, 'GotoTag');
        if strcmp(tagVisibility, 'scoped')
            gotosRemove{end+1}=gotoTag;
        end
    end
    scopeGotoAdd=setdiff(scopeGotoAdd, gotosRemove);
    
    removableDataStoresNames = {};
    removableScopedTagsNames = {};
    
    %finds blocks that are associated with declarations/visibility tags on
    %the same level that they are declared.
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end+1} =  get_param(removableDataStores{rds}, 'DataStoreName');  
    end
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end+1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end
    
    scopeFromAdd=unique(scopeFromAdd);
    scopeGotoAdd=unique(scopeGotoAdd);
    dataStoreReadAdd=unique(dataStoreReadAdd);
    dataStoreWriteAdd=unique(dataStoreReadAdd);
    
    %Makes a temporary variables of the lists of data stores/scoped tags
    %for the signatures that exclude the blocks that are not included due
    %to declarations on this level
    scopeFromAddx=setdiff(scopeFromAdd, removableScopedTagsNames);
    scopeGotoAddx=setdiff(scopeGotoAdd, removableScopedTagsNames);
    dataStoreReadAddx=setdiff(dataStoreReadAdd, removableDataStoresNames);
    dataStoreWriteAddx=setdiff(dataStoreReadAdd, removableDataStoresNames);
    
    if updates
        %Checks for updates in the data stores, i.e. that there is a read and
        %write that correspond to eachother. If an update exists, it is marked
        %in the map and an update is added to the update list.
        for search=1:length(dataStoreWriteAddx)
            for check=1:length(dataStoreReadAddx)
                readname=dataStoreReadAddx{check};
                if strcmp(readname,dataStoreWriteAddx{search})
                    flag = true;
                end
                if flag&&(~isKey(mapObjU, readname))
                    updateblock=struct('Name', readname, 'Type', 'DataStoreRead');
                    mapObjU(readname)=true;
                    updatesToAdd{end+1}=updateblock;
                end
            end
        end
        
        %Checks for updates in the scoped tags, i.e. that there is a read and
        %write that correspond to eachother. If an update exists, it is marked
        %in the map and an update is added to the update list.
        for search=1:length(scopeFromAddx)
            for check=1:length(scopeGotoAddx)
                readname=scopeGotoAddx{check};
                if strcmp(readname,scopeFromAddx{search})
                    flag = true;
                end
                if flag&&(~isKey(mapObjU, readname))
                    updateblock=struct('Name', readname, 'Type', 'ScopedFrom');
                    mapObjU(readname)=true;
                    updatesToAdd{end+1}=updateblock;
                end
            end
        end
    end

    %Adds the scoped froms on the temporary list to the model diagram, each with
    %its corresponding terminator.
    for bz=1:length(scopeFromAddx)
        if ~isKey(mapObjU, scopeFromAddx{bz})
		from=add_block('built-in/From', [address '/FromSigScopeAdd' num2str(num)]);
		fromName=['FromSigScopeAdd' num2str(num)];
		Terminator=add_block('built-in/Terminator', [address '/TerminatorFromScopeAdd' num2str(termnum)]);
		TermName=['TerminatorFromScopeAdd' num2str(termnum)];
		fromToRepo(end+1)=from;
		fromTermToRepo(end+1)=Terminator;
		set_param(from, 'GotoTag', scopeFromAddx{bz});
		set_param(from, 'TagVisibility', 'scoped');
		add_line(address, [fromName '/1'], [TermName '/1']);
		num=num+1;
		termnum=termnum+1;
        end
    end
    
    num=0;
    termnum=0;
    
    %Adds the scoped gotos on the temporary list to the model diagram, each with
    %its corresponding terminator.
    for bt=1:length(scopeGotoAddx)
        if ~isKey(mapObjU, scopeGotoAddx{bt})
            from=add_block('built-in/From', [address '/GotoSigScopeAdd' num2str(num)]);
            fromName=['GotoSigScopeAdd' num2str(num)];
            Terminator=add_block('built-in/Terminator', [address '/TerminatorGotoScopeAdd' num2str(termnum)]);
            TermName=['TerminatorGotoScopeAdd' num2str(termnum)];
            gotoToRepo(end+1)=from;
            gotoTermToRepo(end+1)=Terminator;
            set_param(from, 'GotoTag', scopeGotoAddx{bz});
            set_param(from, 'TagVisibility', 'scoped');
            add_line(address, [fromName '/1'], [TermName '/1']);
            num=num+1;
            termnum=termnum+1;
        end
    end
    
    num=0;
    termnum=0;
    
    %Adds the data store writes on the temporary list to the model diagram, each with
    %its corresponding terminator.
	for by=1:length(dataStoreWriteAddx)
        if ~isKey(mapObjU, dataStoreWriteAddx{by})
            dataStore=add_block('built-in/dataStoreRead', [address '/DataStoreWriteAdd' num2str(num)]);
            dataStoreName=['DataStoreWriteAdd' num2str(num)];
            Terminator=add_block('built-in/Terminator', [address '/TerminatorDataStoreWriteAdd' num2str(termnum)]);
            TermName=['TerminatorDataStoreWriteAdd' num2str(termnum)];
            dSWriteToRepo(end+1)=dataStore;
            dSWriteTermToRepo(end+1)=Terminator;
            set_param(dataStore, 'DataStoreName', dataStoreWriteAddx{by});
            add_line(address, [dataStoreName '/1'], [TermName '/1']);
            num=num+1;
            termnum=termnum+1;
        end
    end
    
    num=0;
    termnum=0;
    
    %Adds the data store reads on the temporary list to the model diagram, each with
    %its corresponding terminator.
    for bx=1:length(dataStoreReadAddx)
        if ~isKey(mapObjU, dataStoreReadAddx{bx})
            dataStore=add_block('built-in/dataStoreRead', [address '/DataStoreReadAdd' num2str(num)]);
            dataStoreName=['DataStoreReadAdd' num2str(num)];
            Terminator=add_block('built-in/Terminator', [address '/TerminatorDataStoreReadAdd' num2str(termnum)]);
            TermName=['TerminatorDataStoreReadAdd' num2str(termnum)];
            dSReadToRepo(end+1)=dataStore;
            dSReadTermToRepo(end+1)=Terminator;
            set_param(dataStore, 'DataStoreName', dataStoreReadAddx{bx});
            add_line(address, [dataStoreName '/1'], [TermName '/1']);
            num=num+1;
            termnum=termnum+1;
        end
    end
    
    num=0;
    termnum=0;
    
    %Adds the updates on the list to the model diagram, each with
    %its corresponding terminator.
    for bw=1:length(updatesToAdd)
        if strcmp(updatesToAdd{bw}.Type, 'DataStoreRead')
            dataStore=add_block('built-in/DataStoreRead', [address '/DataStoreUpdate' num2str(num)]);
            dataStoreName=['DataStoreUpdate' num2str(num)];
            Terminator=add_block('built-in/Terminator', [address '/TermDSUpdate' num2str(termnum)]);
            TermName=['TermDSUpdate' num2str(termnum)];
            updateToRepo(end+1)=dataStore;
            updateTermToRepo(end+1)=Terminator;
            set_param(dataStore, 'DataStoreName', updatesToAdd{bw}.Name);
            add_line(address, [dataStoreName '/1'], [TermName '/1']);
            num=num+1;
            termnum=termnum+1;
        else
            from=add_block('built-in/From', [address '/FromUpdate' num2str(num)]);
            fromName=['FromUpdate' num2str(num)];
            Terminator=add_block('built-in/Terminator', [address '/TermFromUpdate' num2str(termnum)]);
            TermName=['TermFromUpdate' num2str(termnum)];
            updateToRepo(end+1)=from;
            updateTermToRepo(end+1)=Terminator;
            set_param(from, 'GotoTag', updatesToAdd{bw}.Name);
            set_param(from, 'TagVisibility', 'scoped');
            add_line(address, [fromName '/1'], [TermName '/1']);
            num=num+1;
            termnum=termnum+1;
        end
    end
    
    for i=1:length(updatesToAdd)
        updatesToAdd{i}=updatesToAdd{i}.Name;
    end

	scopedGoto=scopeGotoAdd;
    scopedFrom=scopeFromAdd;
	dataStoreW=dataStoreWriteAdd;
    dataStoreR=dataStoreReadAdd;
    
    fromBlocks={fromToRepo, fromTermToRepo};
    dataStoreWrites={dSWriteToRepo, dSWriteTermToRepo};
    dataStoreReads={dSReadToRepo, dSReadTermToRepo};
    gotoBlocks={gotoToRepo, gotoTermToRepo};
    updateBlocks={updateToRepo, updateTermToRepo};
    
    carryUp={scopedFrom, scopedGoto, dataStoreR, dataStoreW};
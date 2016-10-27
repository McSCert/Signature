function TieIn(address, num, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, globalFroms, globalGotos, updates)
    %  TieIn - A function that ties in all the files responsible
    %  for signature extraction
    %
    %   Typical use:
    %   TieIn('ESSR', 0, {}, {})
    %  
	%	Inputs:
	%		address: the name and location in the model
	%		scopeGotoAdd:A list of scoped Goto Tags that need to be added to the
	%					signature.
    %		scopeFromAdd: scoped From Tags that need to be added to the
	%					signature.
	%		DataStoreAdd: A list of Data Store Tags that need to be added to the
	%					signature.
	%		num: zero if initialized to not be recursed one for recursed
    %       dataStoreWriteAdd: A list of data store reads that need to be
    %                   added into the signature.
	%		globalGotos: Tags of global gotos to be added in recursion
	%		updates: A binary digit indicating whether or not updates are
	%		enabled for the signature.
	%
	%	The function first calls InportSig and OutportSig which add and 
	%	connect the appropriate blocks for the inport and outport,
	%	according to the Signature format. If in the appropriate level, it
	%	also calls FindGlobals which outputs the globalGotos in the model.
	%	addDataStoreGoto adds the appropriate scoped Gotos and dataStores
	%	to the level. RepositionInportSig, 
    %  

    
		%add inputs and outputs
		[inaddress, InportGoto, InportFrom, Inports, inGotoLength]=InportSig(address);
		[outaddress, OutportGoto, OutportFrom, Outports, outGotoLength]=OutportSig(address);
		%add global variables
        if num==0
			globalGotos=FindGlobals(address);
            globalGotos=unique(globalGotos);
            globalFroms=globalGotos;
        end
        
        removableGotos=find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
        removableGotosNames={};
        for i=1:length(removableGotos)
            removableGotosNames{end+1}=get_param(removableGotos{i}, 'GotoTag');
        end
        globalGotosx=setdiff(globalGotos, removableGotosNames);
        
		[carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks, updateBlocks]=AddImplicits(address, scopeGotoAdd, scopeFromAdd, dataStoreWriteAdd, dataStoreReadAdd, updates);

        GotoLength = 10;
        
        %verticalOffset is a value that represents the vertical offset between
        %each block added to the model. The Reposition functions are called
        %to Reposition their respective blocks, which pass in the current
        %vertical position, and pass out the vertical position after adding
        %blocks.
        
        %organizes inportss
        verticalOffset=RepositionInportSig(inaddress, InportGoto, InportFrom, Inports, GotoLength);
        add_block('built-in/Note',[address '/Inputs    '], 'Position', [90 10], 'FontSize', 12)
        verticalOffset=verticalOffset+25;
        
        %organizes data store reads
        if ~isempty(dataStoreReads(~cellfun('isempty',dataStoreReads)))
            add_block('built-in/Note',[address '/Data Store Reads'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionImplicits(verticalOffset, dataStoreReads, GotoLength, 1);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes scoped froms
        if ~isempty(fromBlocks(~cellfun('isempty',fromBlocks)))
            add_block('built-in/Note',[address '/Scoped Froms'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionImplicits(verticalOffset, fromBlocks, GotoLength, 1);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes global froms
        if ~isempty(globalFroms(~cellfun('isempty',globalFroms)))
            add_block('built-in/Note',[address '/Global Froms'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=AddGlobals(address, verticalOffset, globalFroms, GotoLength, 0);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes updates if enabled
        if updates&&~isempty(updateBlocks(~cellfun('isempty',updateBlocks)))
            add_block('built-in/Note',[address '/Updates    '], 'Position', [90 verticalOffset+20], 'FontSize', 12);
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionImplicits(verticalOffset, updateBlocks, GotoLength, 0);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes outports
        if ~isempty(Outports(~cellfun('isempty',Outports)))
            add_block('built-in/Note',[address '/Outputs    '], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionOutportSig(outaddress, OutportGoto, OutportFrom, Outports, GotoLength, verticalOffset);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes data store writes
        if ~isempty(dataStoreWrites(~cellfun('isempty',dataStoreWrites)))
            add_block('built-in/Note',[address '/Data Store Writes'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionImplicits(verticalOffset, dataStoreWrites, GotoLength, 0);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes scoped gotos
        if ~isempty(gotoBlocks(~cellfun('isempty',gotoBlocks)))
            add_block('built-in/Note',[address '/Scoped Gotos'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=RepositionImplicits(verticalOffset, gotoBlocks, GotoLength, 0);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes global gotos
        if ~isempty(globalGotosx(~cellfun('isempty',globalGotosx)))
            add_block('built-in/Note',[address '/Global Gotos'], 'Position', [90 verticalOffset+20], 'FontSize', 12)
            verticalOffset=verticalOffset+25;
            verticalOffset=AddGlobals(address, verticalOffset, globalGotosx, GotoLength, 1);
            verticalOffset=verticalOffset+25;
        end
        
        %organizes data store declarations
        dataDex=find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
        tagDex=find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
        if ~isempty(dataDex(~cellfun('isempty',dataDex)))||~isempty(tagDex(~cellfun('isempty',tagDex)))
            add_block('built-in/Note',[address '/Declarations'], 'Position', [90 verticalOffset+20], 'FontSize', 12);
            verticalOffset=verticalOffset+25;
            verticalOffset=MoveDataStoreDex(address, verticalOffset);
        end
        
        %gets all blocks to search for subsystems
        allBlocks=find_system(address, 'SearchDepth', 1);
        allBlocks=setdiff(allBlocks, address);
        for z=1:length(allBlocks)
            BlockType=get_param(allBlocks{z}, 'BlockType');
            if strcmp(BlockType, 'SubSystem')
                BlockName=get_param(allBlocks{z},'LinkStatus');
                isVirtual=get_param(allBlocks{z}, 'IsSubsystemVirtual');
                %recurse the file through subsystems
                if strcmp(isVirtual, 'on')
                    TieIn(allBlocks{z}, 1, carryUp{2}, carryUp{1}, carryUp{4}, carryUp{3}, globalFroms, globalGotosx, updates);
                else
                    TieIn(allBlocks{z}, 1, {}, {}, carryUp{4}, carryUp{3}, {}, {}, updates);
                end
            end
            
        end
end
function [scopeGotoAddout, dataStoreWriteAddout, dataStoreReadAddout, ...
    scopeFromAddout, globalGotosAddout, globalFromsAddout, metrics, ...
    signatures] = TieInStrongData(address, sys, isupdates, txt, dataTypeMap)

    %TieInStrong - Second to top level in function hierarchy. Recursively calls itself
    %              to find the signature of itself and all subsystems of
    %              itself.
    %
    %-inoffinal is the offset variable that determines how far down the
    %y-axis
    %-scopeGotoAddout is the list of scoped gotos that the function will pass out
    %-scopeFromAddOut is the list of scoped froms that the function will pass out
    %-dataStoreReadAddout is the list of data store writes that the function will pass out
    %-dataStoreWriteAddout is the list of data store reads that the function will pass out
    %-metrics is the data needed for use in the MetricGetter function
    %-signatures is the data of all blocks in the signature
    %-address is the current address
    %-num is a number indicating recursion depth
    %-globalGotos is a list of global gotos being passed in
    %-sys is a string that indicates which subsystem or all subsystems to obtain data for
    
    
    %Initializes sets. The "out" arrays are the final output (?)
    scopeGotoAddout={};
    dataStoreWriteAddout={};
    dataStoreReadAddout={};
    scopeFromAddout={};
    globalGotosAddout={};
    globalFromsAddout={};
    id={};
    %sGa, sFa, and dSa are the Gotos, Froms, and Datastores in the sig
	sGa={};
	sFa={};
	dSWa={};
    dSRa={};
    gGa={};
    gFa={};
    metrics={};
    signatures={};
	BlockName=get_param(address,'Name');

    %Handles text blocks


        
        [inaddress, Inports]=InportSigData(address); %finds info of all inports
		[outaddress, Outports]=OutportSigData(address); %finds info of all outports

		allBlocks=find_system(address, 'SearchDepth', 1); %makes set of all addresses of blocks/subsystems
		allBlocks=setdiff(allBlocks, address); %removes the current address from the set
		for z=1:length(allBlocks) %for each block in the allBlocks set
			BlockType=get_param(allBlocks{z}, 'BlockType');
			if strcmp(BlockType, 'SubSystem') %checks if blocktype is a subsystem.
				[scopeGotoAddoutx, dataStoreWriteAddoutx, dataStoreReadAddoutx, scopeFromAddoutx, globalGotosAddoutx, globalFromsAddoutx, metricsx, signaturesx]=TieInStrongData(allBlocks{z}, sys, isupdates, txt, dataTypeMap); %recurses tieInStrong into the subsystem
				sGa=[sGa scopeGotoAddoutx]; %adds blocks found in subsystems to the corresponding set
				sFa=[sFa scopeFromAddoutx];
				dSWa=[dSWa dataStoreWriteAddoutx];
                dSRa= [dSRa dataStoreReadAddoutx];
                gGa=[gGa globalGotosAddoutx];
                gFa=[gFa globalFromsAddoutx];
                metrics=[metrics metricsx];
                signatures=[signatures signaturesx];
			end
		end
		sGa=unique(sGa); %these three lines get rid of duplicate blocks in the sets
		sFa=unique(sFa);
		dSWa=unique(dSWa);
        dSRa=unique(dSRa);
        gGa=unique(gGa);
        gFa=unique(gFa);
        
        [address, scopedGoto, scopedFrom, DataStoreW, DataStoreR, Updates, GlobalGotos, GlobalFroms]=AddImplicitsStrongData(address, sGa, sFa, dSWa, dSRa,gGa,gFa, isupdates); %Calls function to find all data store reads, writes, scoped gotos/froms, and updates
        
        %Makes sure block names in the updates list aren't repeated in the
        %inputs and outputs, and that those filtered lists are separate
        %from what is being passed out.
        scopeGotoAddout=scopedGoto;
        scopedGotoTags=setdiff(scopedGoto, Updates);
        dataStoreWriteAddout=DataStoreW;
        DataStoreWrites=setdiff(dataStoreWriteAddout, Updates);
        dataStoreReadAddout=DataStoreR;
        DataStoreReads=setdiff(dataStoreReadAddout, Updates);
        scopeFromAddout=scopedFrom;
        scopedFromTags=setdiff(scopedFrom, Updates);
        globalGotosAddout=GlobalGotos;
        globalFromsAddout=GlobalFroms;
        
        %gets declarations for the signature
        [tagDex, dsDex]= ImposedData(address);
        
        %For the metrics, returns a struct for each subsystem with the
        %subsystem's name and size.
        size=length(Inports)+length(Outports)+length(globalGotosAddout)+length(globalFromsAddout)...
            +length(scopedGotoTags)+length(scopedFromTags)+length(DataStoreReads)...
            +length(DataStoreWrites)+2*length(Updates)+length(tagDex)+length(dsDex);
        size=num2str(size);
        system=strrep(address,'_STRONG_SIGNATURE','');
        metrics{end+1}=struct('Subsystem', system, 'Size', size);
        %For the signatures, returns a struct for each subsystem with all
        %blocks in the signature as well as subsytem's name and size
        signatures{end+1} = struct(...
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
        
        %If in the matching subsystem from the function call, call the
        %function to make the text file for the signatures data.
        if strcmp(sys, address)||strcmp(sys, 'All')
            DataMaker(address, Inports, Outports, scopedGotoTags, ...
                scopedFromTags, DataStoreWrites, DataStoreReads, Updates, ...
                globalGotosAddout, globalFromsAddout, tagDex, dsDex, ...
                isupdates, txt, dataTypeMap, signatures);
        end
end
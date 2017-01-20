function [carryUp, fromBlocks, dataStoreWrites, dataStoreReads, gotoBlocks,...
    updateBlocks, globalFroms, globalGotos] = ...
    AddImplicitsStrong(address, scopedGotoAdd, scopedFromAdd, ...
    dataStoreWriteAdd, dataStoreReadAdd, globalGotosAdd, globalFromsAdd, ...
    PortsTags, hasUpdates)
% ADDIMPLICITSSTRONG Add the implicit inputs and outputs (i.e., scoped Gotos
%   and Data Store Memorys) for the signature of a subsystem.
%
%   Inputs:
%       address         Simulink system path.
%
%       scopedGotoAdd   List of scoped Gotos that potentially could be
%                       included in the signature.
%
%       scopedFromAdd 	List of scoped Froms that potentially could be
%                       included in the signature.
%
%       dataStoreWriteAdd List of Data Store Writes that potentially could
%                       be included in the signature.
%
%       dataStoreReadAdd List of Data Store Reads that potentially could be
%                       included in the signature.
%
%       PortsTags       List of the tags used for the Gotos/Froms representing
%                       input ports that are NOT to be included in updates.
%
%       hasUpdates      Boolean indicating whether updates are included in
%                       the signature.
%
%	Outputs:
%       carryUp         List of 6 lists that are carried up to the subsystem
%                       above: scoped Froms, scoped Gotos, Data Store
%                       Reads, Data Store Writes, global Froms and global
%                       Gotos.
%
%       fromBlocks      Set containing two matrices: that of the scoped
%                       From blocks, and that of the scoped From blocks'
%                       corresponding terminators.
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
%                       blocks (represented by Reads), and their corresponding
%                       terminators.
%
%       globalFroms     Set containing two matrices: that of the global
%                       From blocks, and that of the global From blocks'
%                       corresponding terminators.
%
%       globalGotos     Set containing two matrices: that of the global
%                       Goto blocks, and that of the global Goto blocks'
%                       corresponding terminators.

    % Initialize sets, matrices, and maps
    fromToRepo = [];
	fromTermToRepo = [];
    gotoToRepo = [];
    gotoTermToRepo = [];
	dSWriteToRepo = [];
	dSWriteTermToRepo = [];
	dSReadToRepo = [];
	dSReadTermToRepo = [];
    updateToRepo = [];
    updateTermToRepo = [];
    globalFromToRepo = [];
    globalFromTermToRepo = [];
    globalGotoToRepo = [];
    globalGotoTermToRepo = [];

    % Hash maps keeping track of if a block of a certain name has already
    % been counted towards one or more of the lists
	mapObjDR = containers.Map(); % Data Store Reads
    mapObjDW = containers.Map(); % Data Store Writes
	mapObjF = containers.Map();  % Froms
    mapObjG = containers.Map();  % Gotos
    mapObjDU = containers.Map(); % Data Store Updates
    mapObjTU = containers.Map(); % Goto/From Tag Updates
    mapObjAddedBlock = containers.Map();
    updatesToAdd = {};
    removableDataStoresNames = {};
    removableScopedTagsNames = {};
    removableScopedFromsNames = {};
    removableGlobalFromsNames = {};

    % Find all Data Store declarations so that their respective Reads
    % and Writes can be removed from the list to be passed out
    removableDataStores = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreMemory');
    for rds = 1:length(removableDataStores)
        removableDataStoresNames{end + 1} = get_param(removableDataStores{rds}, 'DataStoreName');
    end

    % Prevent the removable Data Stores from once more being added to the
    % list of Data Store Reads, Writes, or updates to be passed out
    for dsname = 1:length(removableDataStoresNames)
        mapObjDR(removableDataStoresNames{dsname}) = true;
        mapObjDW(removableDataStoresNames{dsname}) = true;
        mapObjDU(removableDataStoresNames{dsname}) = true;
    end

    % Tag visibility declarations are found, and their respective Gotos and
    % Froms can be removed from the list of scoped Gotos and Froms to be
    % passed out
    removableScopedTags = find_system(address, 'SearchDepth', 1, 'BlockType', 'GotoTagVisibility');
    for rsi = 1:length(removableScopedTags)
        removableScopedTagsNames{end + 1} = get_param(removableScopedTags{rsi}, 'GotoTag');
    end

    % Members of scoped tags outputs are found and used to remove scoped tag
    % inputs, and global Gotos to remove global Froms
    removableScopedFroms = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
    for rsi = 1:length(removableScopedFroms)
        tagVis = get_param(removableScopedFroms{rsi},'TagVisibility');
        if strcmp(tagVis, 'scoped')
            removableScopedFromsNames{end + 1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        elseif strcmp(tagVis, 'global')
            removableGlobalFromsNames{end + 1} = get_param(removableScopedFroms{rsi}, 'GotoTag');
        end
    end
    removableScopedFromsNames = [removableScopedFromsNames scopedGotoAdd];
    removableGlobalFromsNames = [removableGlobalFromsNames globalGotosAdd];

    % Prevent the removable scoped Gotos/Froms from being once more added
    % to the list of scoped Gotos, Froms, or updates to be passed out
    for stname = 1:length(removableScopedTagsNames)
        mapObjF(removableScopedTagsNames{stname}) = true;
        mapObjG(removableScopedTagsNames{stname}) = true;
    end

    % Remove scoped tag inputs
    for frname = 1:length(removableScopedFromsNames)
        mapObjF(removableScopedFromsNames{frname}) = true;
    end

    % Remove removable global Froms
    for ggname = 1:length(removableGlobalFromsNames)
        mapObjF(removableGlobalFromsNames{ggname}) = true;
    end

    if hasUpdates
        % Searches the current subsystem for all blocks that could be Data Store
        % updates
        possibleUpdatesR = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreRead');
        possibleUpdatesW = find_system(address, 'SearchDepth', 1, 'BlockType', 'DataStoreWrite');
        possibleUpdatesNamesR = {};
        possibleUpdatesNamesW = {};

        % Make lists of all potential Data Store update blocks names
        for wnames = 1:length(possibleUpdatesW)
            possibleUpdatesNamesW{end + 1} = get_param(possibleUpdatesW{wnames}, 'DataStoreName');
        end

        possibleUpdatesNamesW = [possibleUpdatesNamesW dataStoreWriteAdd];

        for rnames = 1:length(possibleUpdatesR)
            possibleUpdatesNamesR{end + 1} = get_param(possibleUpdatesR{rnames}, 'DataStoreName');
        end

        % Include all Data Store Reads and Writes that could be part of an
        % update from the lower systems, and then filter out repeated block
        % names and the removable block names
        possibleUpdatesNamesR = [possibleUpdatesNamesR dataStoreReadAdd];
        possibleUpdatesNamesR = unique(possibleUpdatesNamesR);
        possibleUpdatesNamesW = unique(possibleUpdatesNamesW);
        possibleUpdatesNamesR = setdiff(possibleUpdatesNamesR, removableDataStoresNames);
        possibleUpdatesNamesW = setdiff(possibleUpdatesNamesW, removableDataStoresNames);

        % Search subsystem for all blocks that could possibly be scoped
        % Goto/From updates
        possibleUpdatesG = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto');
        possibleUpdatesF = find_system(address, 'SearchDepth', 1, 'BlockType', 'From');
        possibleUpdatesNamesG = {};
        possibleUpdatesNamesF = {};

        % Make lists of all potential scoped Goto/From update block names
        for gnames = 1:length(possibleUpdatesG)
            if strcmp(get_param(possibleUpdatesG{gnames}, 'TagVisibility'), 'scoped')
                possibleUpdatesNamesG{end + 1} = get_param(possibleUpdatesG{gnames}, 'GotoTag');
            end
        end

        possibleUpdatesNamesG = [possibleUpdatesNamesG scopedGotoAdd];

        for fnames = 1:length(possibleUpdatesF)
            possibleUpdatesNamesF{end + 1} = get_param(possibleUpdatesF{fnames}, 'GotoTag');
        end

        % Include all scoped Gotos and Froms that could be part of an
        % update from the lower systems, and then filter out repeated block
        % names and the removable block names. Finally, filter out the scoped
        % Goto/From tags that are used to represent inports and outports.
        possibleUpdatesNamesF = [possibleUpdatesNamesF scopedFromAdd];
        possibleUpdatesNamesF = unique(possibleUpdatesNamesF);
        possibleUpdatesNamesG = unique(possibleUpdatesNamesG);
        possibleUpdatesNamesF = setdiff(setdiff(possibleUpdatesNamesF, removableScopedTagsNames), removableScopedFromsNames);
        possibleUpdatesNamesG = setdiff(possibleUpdatesNamesG, removableScopedTagsNames);
        possibleUpdatesNamesF = setdiff(possibleUpdatesNamesF, PortsTags);
        possibleUpdatesNamesG = setdiff(possibleUpdatesNamesG, PortsTags);

        % If there are any possible update names in both the list of Reads and
        % Writes, that are scoped, add the name to the list of updates, Gotos,
        % and Froms to add and mark them as added in their respective hashmaps.
        for check = 1:length(possibleUpdatesNamesR)
            for against = 1:length(possibleUpdatesNamesW)
                readname = possibleUpdatesNamesR{check};
                writename = possibleUpdatesNamesW{against};
                if strcmp(writename, readname)&&~isKey(mapObjDU, readname)
                    mapObjDU(readname) = true;
                    mapObjDR(readname) = true;
                    mapObjDW(readname) = true;
                    dataStoreReadAdd{end + 1} = readname;
                    dataStoreWriteAdd{end + 1} = readname;
                    updatesToAdd{end + 1} = struct('Name', readname, 'Type', 'DataStoreRead');
                end
            end
        end

        % If there are any possible update names in both the list of Gotos and
        % Froms, that are scoped, add the name to the list of updates, Gotos,
        % and Froms to add and mark them as added in their respective hashmaps.
        for check = 1:length(possibleUpdatesNamesF)
            for against = 1:length(possibleUpdatesNamesG)
                readname = possibleUpdatesNamesF{check};
                writename = possibleUpdatesNamesG{against};
                if strcmp(writename, readname)&&~isKey(mapObjTU, readname)
                    mapObjTU(readname) = true;
                    mapObjF(readname) = true;
                    mapObjG(readname) = true;
                    scopedFromAdd{end + 1} = readname;
                    scopedGotoAdd{end + 1} = readname;
                    updatesToAdd{end + 1} = struct('Name',readname, 'Type', 'Goto');
                end
            end
        end
    end
    % Remove duplicates and removable block names
    dataStoreWriteAdd = unique(dataStoreWriteAdd);
    dataStoreReadAdd = unique(dataStoreReadAdd);
    scopedGotoAdd = unique(scopedGotoAdd);
    scopedFromAdd = unique(scopedFromAdd);
    scopedGotoAdd = setdiff(scopedGotoAdd, removableScopedTagsNames);
    scopedFromAdd = setdiff(setdiff(scopedFromAdd, removableScopedTagsNames), removableScopedFromsNames);
    dataStoreWriteAdd = setdiff(dataStoreWriteAdd, removableDataStoresNames);
    dataStoreReadAdd = setdiff(dataStoreReadAdd, removableDataStoresNames);
    globalFromsAdd = setdiff(globalFromsAdd, removableGlobalFromsNames);

    num = 0;        % Goto/From number
    termnum = 0;    % Terminator number

    % Adds all Froms remaining on the list of Froms (that aren't updates) to
    % the model diagram, with a corresponding terminator, and adds each
    % block to its corresponding matrix.
	for bz = 1:length(scopedFromAdd)
        if ~isKey(mapObjTU, scopedFromAdd{bz})
            mapObjF(scopedFromAdd{bz}) = true;

            from = add_block('built-in/From', [address '/FromSigScopeAdd' num2str(num)], ...
                'GotoTag', scopedFromAdd{bz}, 'TagVisibility', 'scoped');
            terminator = add_block('built-in/Terminator', [address '/TerminatorFromScopeAdd' num2str(termnum)]);

            FromName = ['FromSigScopeAdd' num2str(num)];
            TermName = ['TerminatorFromScopeAdd' num2str(termnum)];

            fromToRepo(end + 1) = from;
            fromTermToRepo(end + 1) = terminator;

            add_line(address, [FromName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        end
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds all Gotos remaining on the list of Gotos (that aren't updates) to
    % the model diagram, with a corresponding terminator, and adds each
    % block to its corresponding matrix.
    for bt = 1:length(scopedGotoAdd)
        if ~isKey(mapObjTU, scopedGotoAdd{bt})
            mapObjG(scopedGotoAdd{bt}) = true;
            from = add_block('built-in/From', [address '/GotoSigScopeAdd' num2str(num)], ...
                'GotoTag', scopedGotoAdd{bt}, 'TagVisibility', 'scoped');
            terminator = add_block('built-in/Terminator', [address '/TerminatorGotoScopeAdd' num2str(termnum)]);

            FromName = ['GotoSigScopeAdd' num2str(num)];
            TermName = ['TerminatorGotoScopeAdd' num2str(termnum)];

            gotoToRepo(end + 1) = from;
            gotoTermToRepo(end + 1) = terminator;

            add_line(address, [FromName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        end
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds global Froms necessary to the signature
    for bf = 1:length(globalFromsAdd)
        mapObjF(globalFromsAdd{bf}) = true;
        from = add_block('built-in/From', [address '/FromSigGlobalAdd' num2str(num)], ...
            'GotoTag', globalFromsAdd{bf}, 'TagVisibility', 'scoped');
        terminator = add_block('built-in/Terminator', [address '/TerminatorFromGlobalAdd' num2str(termnum)]);

        FromName = ['FromSigGlobalAdd' num2str(num)];
        TermName = ['TerminatorFromGlobalAdd' num2str(termnum)];

        globalFromToRepo(end + 1) = from;
        globalFromTermToRepo(end + 1) = terminator;

        add_line(address, [FromName '/1'], [TermName '/1']);

        num = num + 1;
        termnum = termnum + 1;
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds global Gotos necessary for the signature
    for bt = 1:length(globalGotosAdd)
        mapObjG(globalGotosAdd{bt}) = true;
        from = add_block('built-in/From', [address '/GotoSigGlobalAdd' num2str(num)], ...
             'GotoTag', globalGotosAdd{bt}, 'TagVisibility', 'scoped');
        terminator = add_block('built-in/Terminator', [address '/TerminatorGotoGlobalAdd' num2str(termnum)]);

        FromName = ['GotoSigGlobalAdd' num2str(num)];
        TermName = ['TerminatorGotoGlobalAdd' num2str(termnum)];

        globalGotoToRepo(end + 1) = from;
        globalGotoTermToRepo(end + 1) = terminator;

        add_line(address, [FromName '/1'], [TermName '/1']);

        num = num + 1;
        termnum = termnum + 1;
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds all Reads remaining on the list of reads (that aren't updates) to
    % the model diagram, with a corresponding terminator, and adds each
    % block to its corresponding matrix.
	for by = 1:length(dataStoreWriteAdd)
        if ~isKey(mapObjDU, dataStoreWriteAdd{by})
            mapObjDW(dataStoreWriteAdd{by}) = true;

            dataStore = add_block('built-in/dataStoreRead', [address '/dataStoreWriteAdd' num2str(num)], ...
                'DataStoreName', dataStoreWriteAdd{by});
            terminator = add_block('built-in/Terminator', [address '/TerminatordataStoreWriteAdd' num2str(termnum)]);

            mapObjAddedBlock(getfullname(dataStore)) = true;

            DataStoreName = ['dataStoreWriteAdd' num2str(num)];
            TermName = ['TerminatordataStoreWriteAdd' num2str(termnum)];

            dSWriteToRepo(end + 1) = dataStore;
            dSWriteTermToRepo(end + 1) = terminator;

            add_line(address, [DataStoreName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        end
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds all Writes remaining on the list of Writes (that aren't updates) to
    % the model diagram, with a corresponding terminator, and adds each
    % block to its corresponding matrix.
    for bx = 1:length(dataStoreReadAdd)
        if ~isKey(mapObjDU, dataStoreReadAdd{bx})
            mapObjDR(dataStoreReadAdd{bx}) = true;

            dataStore = add_block('built-in/dataStoreRead', [address '/dataStoreReadAdd' num2str(num)], ...
                'DataStoreName', dataStoreReadAdd{bx});
            terminator = add_block('built-in/Terminator', [address '/TerminatordataStoreReadAdd' num2str(termnum)]);

            DataStoreName = ['dataStoreReadAdd' num2str(num)];
            TermName = ['TerminatordataStoreReadAdd' num2str(termnum)];

            mapObjAddedBlock(getfullname(dataStore)) = true;
            mapObjDR(DataStoreName) = true;

            dSReadToRepo(end + 1) = dataStore;
            dSReadTermToRepo(end + 1) = terminator;

            add_line(address, [DataStoreName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        end
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Adds all updates on the list of updates to the model diagram, with a
    % corresponding terminator, and adds each block to its corresponding
    % matrix
    for bw = 1:length(updatesToAdd)
        if strcmp(updatesToAdd{bw}.Type, 'DataStoreRead')
            dataStore = add_block('built-in/dataStoreRead', [address '/DataStoreUpdate' num2str(num)], ...
                'DataStoreName', updatesToAdd{bw}.Name);
            terminator = add_block('built-in/Terminator', [address '/TermDSUpdate' num2str(termnum)]);

            DataStoreName = ['DataStoreUpdate' num2str(num)];
            TermName = ['TermDSUpdate' num2str(termnum)];

            mapObjAddedBlock(getfullname(dataStore)) = true;
            mapObjDR(DataStoreName) = true;

            updateToRepo(end + 1) = dataStore;
            updateTermToRepo(end + 1) = terminator;

            add_line(address, [DataStoreName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        else
            from = add_block('built-in/From', [address '/FromUpdate' num2str(num)], ...
                'GotoTag', updatesToAdd{bw}.Name, 'TagVisibility', 'scoped');
            terminator = add_block('built-in/Terminator', [address '/TermFromUpdate' num2str(termnum)]);

            FromName = ['FromUpdate' num2str(num)];
            TermName = ['TermFromUpdate' num2str(termnum)];

            updateToRepo(end + 1) = from;
            updateTermToRepo(end + 1) = terminator;

            add_line(address, [FromName '/1'], [TermName '/1']);

            num = num + 1;
            termnum = termnum + 1;
        end
    end

    % Reset numbering of blocks
    num = 0;
    termnum = 0;

    % Make a list of all blocks in the subsystem
	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);

    % For each of the blocks in said list, add Data Store Reads and Writes,
    % and scoped Froms and Gotos to their respective lists to pass out, if
    % not already marked on the hashmap, and also add each block not already
    % added to the model diagram, each with its own terminator, and add said
    % blocks to their corresponding matrices.
	for z = 1:length(allBlocks)
		Blocktype = get_param(allBlocks{z}, 'Blocktype');

		switch Blocktype
			case 'Goto'
				tagVisibility = get_param(allBlocks{z}, 'TagVisibility');
                gotoTag = get_param(allBlocks{z}, 'GotoTag');
				if strcmp(tagVisibility, 'scoped')
					if ~(isKey(mapObjG, gotoTag))
                        mapObjG(gotoTag) = true;
						scopedGotoAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');

						from = add_block('built-in/From', [address '/GotoSigScope' num2str(num)], ...
                            'GotoTag', gotoTag, 'TagVisibility', 'scoped');
						terminator = add_block('built-in/Terminator', [address '/TerminatorGotoScope' num2str(termnum)]);

						gotoToRepo(end + 1) = from;
						gotoTermToRepo(end + 1) = terminator;

						add_line(address, ['GotoSigScope' num2str(num) '/1'], ['TerminatorGotoScope' num2str(termnum) '/1'])

						num = num + 1;
						termnum = termnum + 1;
                    end
                elseif strcmp(tagVisibility, 'global')
                    if ~(isKey(mapObjG, gotoTag))
                        mapObjG(gotoTag) = true;
						globalGotosAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');

						from = add_block('built-in/From', [address '/GotoSigScope' num2str(num)], ...
                            'GotoTag', gotoTag, 'TagVisibility', 'scoped');
						terminator = add_block('built-in/Terminator', [address '/TerminatorGotoScope' num2str(termnum)]);

						globalGotoToRepo(end + 1) = from;
						globalGotoTermToRepo(end + 1) = terminator;

						add_line(address, ['GotoSigScope' num2str(num) '/1'], ['TerminatorGotoScope' num2str(termnum) '/1'])

						num = num + 1;
						termnum = termnum + 1;
                    end
                end

			case 'From'
                gotoConnected  =  get_param(allBlocks{z}, 'GotoBlock');
                % Note: Check the corresponding Goto for the scope as
                % opposed to its own scope, as local Froms can access scoped
                % Gotos
				tagVisibility = get_param(gotoConnected.handle, 'tagVisibility');
                gotoTag = get_param(allBlocks{z}, 'GotoTag');
				if strcmp(tagVisibility, 'scoped')
                    if ~(isKey(mapObjF, gotoTag));
                        mapObjF(gotoTag) = true;
                        scopedFromAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');

                        from = add_block('built-in/From', [address '/FromSigScope' num2str(num)], ...
                            'GotoTag', gotoTag, 'TagVisibility', 'scoped');
                        terminator = add_block('built-in/Terminator', [address '/TerminatorFromScope' num2str(termnum)]);

                        fromToRepo(end + 1) = from;
                        fromTermToRepo(end + 1) = terminator;

                        add_line(address, ['FromSigScope' num2str(num) '/1'], ['TerminatorFromScope' num2str(termnum) '/1'])

                        num = num + 1;
                        termnum = termnum + 1;
                    end
                elseif strcmp(tagVisibility, 'global')
                    if ~(isKey(mapObjF, gotoTag));
                        mapObjF(gotoTag) = true;
                        globalFromsAdd{end + 1} = get_param(allBlocks{z}, 'GotoTag');

                        from = add_block('built-in/From', [address '/FromSigScope' num2str(num)], ...
                            'GotoTag', gotoTag, 'TagVisibility', 'scoped');
                        terminator = add_block('built-in/Terminator', [address '/TerminatorFromScope' num2str(termnum)]);

                        globalFromToRepo(end + 1) = from;
                        globalFromTermToRepo(end + 1) = terminator;

                        add_line(address, ['FromSigScope' num2str(num) '/1'], ['TerminatorFromScope' num2str(termnum) '/1'])

                        num = num + 1;
                        termnum = termnum + 1;
                    end
                end

			case 'DataStoreRead'
				DataStoreName = get_param(allBlocks{z}, 'DataStoreName');
 				if ~(isKey(mapObjDR, DataStoreName))&&~(isKey(mapObjAddedBlock, allBlocks{z}))
                    mapObjDR(DataStoreName) = true;
                    dataStoreReadAdd{end + 1} = DataStoreName;
                    dataStore = add_block('built-in/dataStoreRead', [address '/DataReadSig' num2str(num)], ...
                        'DataStoreName', DataStoreName);
                    mapObjAddedBlock(getfullname(dataStore)) = true;

                    terminator = add_block('built-in/Terminator', [address '/TerminatorDataReadSig' num2str(termnum)]);

                    dSReadToRepo(end + 1) = dataStore;
                    dSReadTermToRepo(end + 1) = terminator;

                    add_line(address, ['DataReadSig' num2str(num) '/1'], ['TerminatorDataReadSig' num2str(termnum) '/1'])

                    num = num + 1;
                    termnum = termnum + 1;
                end

			case 'DataStoreWrite'
				DataStoreName = get_param(allBlocks{z}, 'DataStoreName');
				if ~(isKey(mapObjDW, DataStoreName))
                    mapObjDW(DataStoreName) = true;
                    dataStoreWriteAdd{end + 1} = DataStoreName;
					dataStore = add_block('built-in/dataStoreRead', [address '/DataWriteSig' num2str(num)], ...
                        'DataStoreName', DataStoreName);
                    mapObjAddedBlock(getfullname(dataStore)) = true;

					terminator = add_block('built-in/Terminator', [address '/TerminatorDataWriteSig' num2str(termnum)]);

					dSWriteToRepo(end + 1) = dataStore;
					dSWriteTermToRepo(end + 1) = terminator;

					add_line(address, ['DataWriteSig' num2str(num) '/1'], ['TerminatorDataWriteSig' num2str(termnum) '/1'])

					num = num + 1;
					termnum = termnum + 1;
				end
		end
    end

    % -- Prepare outputs --
    % Group implicit signature data in order to minimize the number of outputs
	scopedFrom      = unique(scopedFromAdd);
    dataStoreR      = unique(dataStoreReadAdd);
	dataStoreW      = unique(dataStoreWriteAdd);
    scopedGoto      = unique(scopedGotoAdd);
    globalFromsOut  = unique(globalFromsAdd);
    globalGotosOut  = unique(globalGotosAdd);
    carryUp = {scopedFrom, dataStoreR, dataStoreW, scopedGoto, globalFromsOut,...
        globalGotosOut, updatesToAdd};

    % Blocks that need to be repositioned and their corresponding terminator
    % are grouped together
    fromBlocks      = {fromToRepo, fromTermToRepo};
    dataStoreWrites = {dSWriteToRepo, dSWriteTermToRepo};
    dataStoreReads  = {dSReadToRepo, dSReadTermToRepo};
    gotoBlocks      = {gotoToRepo, gotoTermToRepo};
    globalFroms     = {globalFromToRepo, globalFromTermToRepo};
    globalGotos     = {globalGotoToRepo, globalGotoTermToRepo};
    updateBlocks    = {updateToRepo, updateTermToRepo};
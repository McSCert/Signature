function DataMaker(address, inputs, outputs, scopedGotos, scopedFroms, ...
    dataStoreWrites, dataStoreReads, updates, globalGotos, globalFroms, ...
    tagDex, dsDex, hasUpdates, docFormat, dataTypeMap, signatures)
% DATAMAKER Make a text file of a signature.
%
%   Inputs:
%       address         Simulink model name.
%       inputs          List of Inports.
%       outputs         List of Outports.
%       scopedGotos     List of all scoped Gotos in the signature.
%       scopedFroms     List of all scoped Froms in the signature.
%       dataStoreWrites List of all Data Store Writes in the signature.
%       dataStoreReads  List of all Data Store Reads in the signature.
%       updates         List of all updates in the signature.
%       globalGotos     List of all global Gotos in the signature.
%       globalFroms     List of all global Froms in the signature.
%       tagDex		    Names of Gotos in scope in scope of the system.
%       dsDex           Names of Data Store Memorys in scope of the system.
%       hasUpdates      Number indicating whether reads and writes in the same
%                       same subsystem are kept separate (0), or combined and 
%                       listed as an update (1).
%       docFormat       Number indicating which docmentation type to
%                       generate: no doc(0), .txt(1), .tex(2), .doc(3), 
%                       else no doc.
%       dataTypeMap     Map of blocks and their corresponding data type.
%       signatures      Struct array of the signatures of each subsystem.
%
%   Outputs:
%       N/A

    if docFormat == 1 % .txt
        % Create a valid file name based on the current subsystem name
        filename = [address '.txt'];
        filename = strrep(filename, '/', '_');
        filename = filename(1:end);
        filename = strrep(filename, sprintf('\n'), '');
        filename = strrep(filename, sprintf('\r'), '');

        % Open the file, then print a header
        % Fill with blocks names and their type
        file = fopen(filename, 'wt');

        fprintf(file, 'INPUTS\n');
        printTxtSection(address, file, dataTypeMap, 'Inports: ', inputs, 'Inport');
        printTxtSection(address, file, dataTypeMap, 'Scoped Froms: ', scopedFroms, 'From');
        printTxtSection(address, file, dataTypeMap, 'Global Froms: ', globalFroms, 'From');
        printTxtSection(address, file, dataTypeMap, 'Data Store Reads: ', dataStoreReads, 'DataStoreRead');
        fprintf(file, '\n');

        fprintf(file, 'OUTPUTS\n');
        printTxtSection(address, file, dataTypeMap, 'Outports: ', outputs, 'Outport');
        printTxtSection(address, file, dataTypeMap, 'Scoped Gotos: ', scopedGotos, 'Goto');
        printTxtSection(address, file, dataTypeMap, 'Global Gotos: ', globalGotos, 'Goto');
        printTxtSection(address, file, dataTypeMap, 'Data Store Writes: ', dataStoreWrites, 'DataStoreWrite');
        fprintf(file, '\n');

        if hasUpdates
            fprintf(file, 'UPDATES');
            printTxtSection(address, file, dataTypeMap, '', updates, 'DataStoreRead'); % Assumes updates can only occur with Data Stores
            fprintf(file, '\n');
        end

        fprintf(file, 'TAG DECLARATIONS');
        printTxtSection(address, file, dataTypeMap, '', tagDex, 'GotoTagVisibility');

        fprintf(file, 'DATA STORE DECLARATIONS');
        printTxtSection(address, file, dataTypeMap, '', dsDex, 'DataStoreMemory');
        fclose(file);

    elseif docFormat == 2 % .tex
        % Create a valid file name based on the current subsystem name
        filename = [address '.tex'];
        filename = strrep(filename, '/', '_');
        filename = filename(1:end);
        filename = strrep(filename, sprintf('\n'), '');
        filename = strrep(filename, sprintf('\r'), '');

        % Open the file, then print a header
        % Fill with blocks names and their type
        file = fopen(filename, 'wt');

        texPreamble = '% To use this LaTeX, the following should be in the preamble:';
        fprintf(file, '%s\n', texPreamble);
        fprintf(file, '%%\t%s\n\n', '\usepackage[pdfusetitle]{hyperref}');

        table = '% To add the generated tables to a latex document, use the following line (edit the path as appropriate):';
        fprintf(file, '%s\n', table);
        table = ['\input{path_to_file/' filename '}'];
        fprintf(file, '%%\t%s\n\n', table);

        table = '% To hyperlink to a table in this file, use the following line:';
        fprintf(file, '%s\n', table);
        table = ['\hyperref[table:' filename '_table title]{hyperlinked text here}'];
        fprintf(file, '%%\t%s\n\n', table);

        table = '% To hyperlink to a row in a table in this file, use the following line:';
        fprintf(file, '%s\n', table);
        table = ['\hyperref[table:' filename '_table title_variable name]{hyperlinked text here}'];
        fprintf(file, '%%\t%s\n\n', table);

        table = '\subsection*{INPUTS}';
        fprintf(file, '%s\n\n', table);

        if ~isempty(outputs) || ~isempty(scopedGotos) || ~isempty(globalGotos) || ~isempty(dataStoreWrites)
            makeTexTable(address, filename, file, 'Inports', inputs, dataTypeMap, 'Inport');
            makeTexTable(address, filename, file, 'Scoped Froms', scopedFroms, dataTypeMap, 'From');
            makeTexTable(address, filename, file, 'Global Froms', globalFroms, dataTypeMap, 'From');
            makeTexTable(address, filename, file, 'Data Store Reads', dataStoreReads, dataTypeMap, 'DataStoreRead');
        else
            table = 'N/A \\';
            fprintf(file, '%s\n', table);
        end

        fprintf(file, '\n');
        table = '\subsection*{OUTPUTS}';
        fprintf(file, '%s\n\n', table);

        if ~isempty(outputs) || ~isempty(scopedGotos) || ~isempty(globalGotos) || ~isempty(dataStoreWrites)
            makeTexTable(address, filename, file, 'Outports', outputs, dataTypeMap, 'Outport');
            makeTexTable(address, filename, file, 'Scoped Gotos', scopedGotos, dataTypeMap, 'Goto');
            makeTexTable(address, filename, file, 'Global Gotos', globalGotos, dataTypeMap, 'Goto');
            makeTexTable(address, filename, file, 'Data Store Writes', dataStoreWrites, dataTypeMap, 'DataStoreWrite');
        else
            table = 'N/A \\';
            fprintf(file, '%s\n', table);
        end

        if hasUpdates
            fprintf(file, '\n');
            table = '\subsection*{UPDATES}';
            fprintf(file, '%s\n', table);
            tlabel = strrep(filename, '.tex', '');
            tlabel = ['table:' tlabel '_UPDATES'];
            fprintf(file, '%s\n\n', ['\label{' tlabel '}']);
            fillTexTable(address, file, updates, tlabel, dataTypeMap, 'DataStoreRead'); % Assumes updates can only occur with Data Stores
        end

        fprintf(file, '\n');
        table = '\subsection*{DECLARATIONS}';
        fprintf(file, '%s\n\n', table);

        if ~isempty(tagDex) || ~isempty(dsDex)
            makeTexTable(address, filename, file, 'Tag Declarations', tagDex,dataTypeMap, 'GotoTagVisibility');
            makeTexTable(address, filename, file, 'Data Store Declarations', dsDex,dataTypeMap, 'DataStoreMemory');
        else
            table = 'N/A';
            fprintf(file, '%s\n', table);
        end

        table = '\\\\';
        fprintf(file, '%s\n', table);
        fclose(file);

    elseif docFormat == 3 % .doc
        % Create a valid file name based on the current subsystem name
        filename = address;
        filename = strrep(filename, '/', '_');
        filename = filename(1:end);
        filename = strrep(filename, sprintf('\n'), '');
        filename = strrep(filename, sprintf('\r'), '');

        % Make chapter title. Each chapter corresponds to a subsystem.
        chapter = [get_param(address, 'Name'), ' ', 'Signature'];

        % Save workspace variables because using the 'report' function
        % later on will overwrite them (these are the variables which will
        % be created/used in Signature.rpt)
        varsForReport = {'filename', 'dataTypeMap', 'address', 'signatures', ...
            'chapter', 'getUnit', 'k', 'includeTableDefaults', 'removeInterfaceCols', ...
            'sigParams', 'tableSections', 'index', 'table', 'tableTitle', 'sigParam'};
        tempVarsFromBase = SaveBaseVars(varsForReport);
        OverwriteBaseVars(varsForReport); % Replace values in base workspace with values from this workspace

        % Generate the report as a .doc file, using the Signature.rpt template
        report('Signature', '-fdoc', '-quiet');

        % Restore the workspace
        LoadBaseVars(varsForReport, tempVarsFromBase);
    %else %produce no document
    end
end

function tempVarsFromBase = SaveBaseVars(varsToSave)
% SAVEBASEVARS Save variables in the base workspace.
    tempVarsFromBase = cell(1, length(varsToSave));
    for i = 1:length(varsToSave)
        % Save variable if it exists
        try
            tempVarsFromBase{i} = evalin('base', varsToSave{i});
        end
    end
end

function OverwriteBaseVars(varsToSave)
% OVERWRITEBASEVARS Overwrite variables in the base workspace with values from the caller.
    for i = 1:length(varsToSave)
        % Overwrite variable from caller
        if evalin('caller', ['exist(''', varsToSave{i}, ''',''var'')'])
            assignin('base', varsToSave{i}, evalin('caller', varsToSave{i}));
        end
    end
end

function LoadBaseVars(varsToLoad, tempVarsFromBase)
% LOADBASEVARS Return base workspace to its original state.
    for i = 1:length(varsToLoad)
        % Load Variables
        try
            if ~isempty(tempVarsFromBase{i})
                assignin('base', varsToLoad{i}, tempVarsFromBase{i});
            else
                evalin('base', ['clear ' varsToLoad{i}])
            end
        end
    end
end

% Note: All tables use this function except the Updates table which has no
% subsubsection
function makeTexTable(address, filename, file, title, blocks, dataTypeMap, blockType)
    if ~isempty(blocks)
        table = ['\subsubsection*{' title '}'];
        fprintf(file, '%s\n', table);
        tlabel = strrep(filename, '.tex', '');
        tlabel = ['table:' tlabel '_' title];
        fprintf(file, '%s', ['\label{' tlabel '}']);
        table = ['%% Hyperlink with: \hyperref[' tlabel ']{hyperlinked text here}'];
        fprintf(file, '\t%s\n', table);
        fillTexTable(address, file, blocks, tlabel, dataTypeMap, blockType);
    end
end

function fillTexTable(address, file, blocks, tlabel, dataTypeMap, blockType)
    if ~isempty(blocks)
        table = '\begin{tabular}{|l|l|l|} \hline ';
        fprintf(file, '%s\n', table);
        table = 'Name & \textsc{Matlab} Type & Description \\ \hline';
        fprintf(file, '%s\n', table);
        for i = 1:length(blocks)
            rowlabel = [tlabel '_' blocks{i}];
            blockName = strrep(blocks{i}, '_', '\_');
            type = getBlockDataType(address, dataTypeMap, blocks{i}, blockType);
            type = strrep(type, '_', '\_');
            table = ['\makeatletter\raisebox{\f@size pt}{\phantomsection}\label{' rowlabel '}' blockName ' \makeatother&' type ' & \\ \hline'];
            fprintf(file, '%s', table);
            table = ['%% Hyperlink with: \hyperref[' rowlabel ']{hyperlinked text here}'];
            fprintf(file, '\t%s\n', table);
        end
        table = '\end{tabular}';
        fprintf(file, '%s\n', table);
    end
end

function type = getBlockDataType(address, dataTypeMap, blockID, blockType)
    try
        [block, ~] = getBlockPath(address, blockID, blockType);
        if strcmp(block,'')
            type = 'N/A';
        else
            if isKey(dataTypeMap,block)
                type = dataTypeMap(block);
            else
                type = 'N/A';
            end
        end
    catch
        type = 'N/A';
    end
end

function printTxtSection(address, file, dataTypeMap, heading, sectionBlocks, blockType)
    if isempty(heading)
        fprintf(file, '\n');
    end

    if ~isempty(sectionBlocks)
        if ~isempty(heading)
            fprintf(file, '%s\n', heading);
        end
        for i = 1:length(sectionBlocks)
            type = getBlockDataType(address, dataTypeMap, sectionBlocks{i}, blockType);
            text = [sectionBlocks{i} ': ' type];
            fprintf(file, '\t%s\n', text);
        end
    end
end
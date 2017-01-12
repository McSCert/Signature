function [address, inportGoto, inportFrom, inports, gotoLength] = InportSig(address)
%  INPORTSIG Add Inports to the signature in the model by adding Goto/Froms for Inports.
%
%	Inputs:
%		address     Simulink system path.
%
%	Outputs:
%		address     Simulink system path.
%		inportGoto  Handles of Inport Gotos.
%		inportFrom  Handles of Inport Froms.
%		inports 	Handles of Inport.
%		gotoLength  Max length of Inport Goto/From tags.

    % Constants:
    GOTOFROM_BGCOLOR = getSignatureConfig('gotofrom_bgcolor', 'white'); % Background color of signature Goto/Froms

    % Initialize outputs
    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    inportGoto = {};
    inportFrom = {};
    gotoLength = 0;

    for z = 1:length(inports)
        % Get Inport info
        pConnect = get_param(inports{z}, 'portConnectivity');
        pName    = get_param(inports{z}, 'Name');

        % Construct Goto tag
        pSID    = get_param(inports{z}, 'SID');
        GotoTag = ['GotoIn' pSID];
        GotoTag = strrep(GotoTag, ':', '');

        % Save longest tag
        if length(GotoTag) > gotoLength
            gotoLength = length(GotoTag);
        end

        % Add Goto block
        Goto = add_block('built-in/Goto', [address '/GotoIn' pSID], ...
            'GotoTag', GotoTag, 'BackgroundColor', GOTOFROM_BGCOLOR);
        GotoName = GotoTag;
        inportGoto{end + 1} = getfullname(Goto);
        % No need to move now, becuase the repositioning functions take
        % care of moving the signature blocks:
        % set_param(Goto, 'Position', get_param(inports{z}, 'Position'));

        % Add From block
        From = add_block('built-in/From', [address '/FromIn' pSID], ...
            'GotoTag', GotoTag, 'BackgroundColor', GOTOFROM_BGCOLOR);
        FromName = ['FromIn' pSID];
        inportFrom{end + 1} = getfullname(From);
        set_param(From, 'Position', get_param(inports{z}, 'Position')); % Move to same position as Inport it is replacing

        % Connect new Goto/Froms with signal lines
        DstBlocks = pConnect.DstBlock;
        DstPorts  = pConnect.DstPort;
        % 1) Connect From to whatever the Inport was connected to
        for y = 1:length(DstBlocks)
            DstBlockName = get_param(DstBlocks(y), 'Name');
            pName = strrep(pName, '/', '//');

            % 1a) Inport connected to Enable port
            try
            	delete_line(address, [pName '/1'], [DstBlockName '/' 'Enable']);
                add_line(address, [FromName '/1'], [DstBlockName '/' 'Enable'], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end

            % 1b) Inport connected to Trigger port
            try
                delete_line(address, [pName '/1'], [DstBlockName '/' 'Trigger']);
                add_line(address, [FromName '/1'], [DstBlockName '/' 'Trigger'], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end

            % 1c) Inport connected to regular block port
            try
                delete_line(address ,[pName '/1'], [DstBlockName '/' num2str(DstPorts(y) + 1)]);
                add_line(address,[FromName '/1'], [DstBlockName '/' num2str(DstPorts(y) + 1)], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end
        end

        % 2) Connect Inport to Goto
       	try
            add_line(address, [pName '/1'], [GotoName '/1'], 'autorouting', 'on')
        catch
            % Do nothing
        end
    end
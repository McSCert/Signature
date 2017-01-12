function [address, outportGoto, outportFrom, outports, gotoLength] = OutportSig(address)
%  OUTPORTSIG Adds Outports to the signature in the model by adding Goto/Froms for Outports.
%
%   Function:
%       OUTPORTSIG(address)
%
%   Inputs:
%       address      Simulink system path.
%
%   Outports:
%   address      Simulink system path.
%		outportGoto  Handles of Outport Gotos.
%		outportFrom  Handles of Outport Froms.
%		outports     Handles of Outport.
%		gotoLength   Max length of Outport Goto/From tags.

    % Constant: Colour of signature Goto/Froms
    GOTOFROM_BGCOLOR = getSignatureConfig('gotofrom_bgcolor', 'white'); % Background color of signature Goto/Froms

    % Initialize outputs
	outportGoto = {};
	outportFrom = {};
	gotoLength  = 0;
	outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');

	for z = 1:length(outports)
        % Get Outport info
        pConnect = get_param(outports{z}, 'portConnectivity');
        pName    = get_param(outports{z}, 'Name');
        pHandle  = get_param(outports{z}, 'Handle');
        pHandles = get(pHandle, 'portHandles');

        % Construct Goto tag
        pSID    = get_param(outports{z}, 'SID');
        GotoTag = get(pHandles.Inport, 'PropagatedSignals');
        if strcmp(GotoTag, '')
            GotoTag = ['GotoOut' pSID];
            GotoTag = strrep(GotoTag, ':', '');
        end

        % Save longest tag
        if length(GotoTag) > gotoLength
            gotoLength = length(GotoTag);
        end

        % Add Goto block
        Goto = add_block('built-in/Goto', [address '/GotoOut' pSID], ...
            'GotoTag', GotoTag, 'BackgroundColor', GOTOFROM_BGCOLOR);
        GotoName = ['GotoOut' pSID];
        set_param(Goto, 'Position', get_param(outports{z}, 'Position')); % Move to same position as Outport it is replacing
        outportGoto{end + 1} = getfullname(Goto);

        % Add From block
        From = add_block('built-in/From', [address '/FromOut' pSID], ...
            'GotoTag', GotoTag, 'BackgroundColor', GOTOFROM_BGCOLOR);
        FromName = ['FromOut' pSID];
        outportFrom{end + 1} = getfullname(From);
        % No need to move now, becuase the repositioning functions take
        % care of moving the signature blocks:
        % set_param(From, 'Position', get_param(outports{z}, 'Position'));

        % Connect new Goto/Froms with signal lines
        SrcBlocks = pConnect.SrcBlock;
        SrcPorts  = pConnect.SrcPort;
        % 1) Connect Goto to whatever the Outport was connected to
        for y = 1:length(SrcBlocks)
            SrcBlockName = get_param(SrcBlocks(y), 'Name');
            SrcBlockName = strrep(SrcBlockName, '/', '//');
            try
                delete_line(address, [SrcBlockName '/' num2str(SrcPorts(y) + 1)], [pName '/1']);
                add_line(address, [SrcBlockName '/' num2str(SrcPorts(y) + 1)], [GotoName '/1'], 'autorouting', 'on');
            catch
                % Do nothing
            end
        end

         % 2) Connect From to Outport
        try
            add_line(address, [FromName '/1'], [pName '/1'], 'autorouting', 'on');
        catch
            % Do nothing
        end
	end

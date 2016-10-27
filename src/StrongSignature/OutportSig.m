function [address, outportGoto, outportFrom, outports, gotoLength] = OutportSig(address)
%  OUTPORTSIG Add the Gotos and Froms for Outports

    outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');
    outportGoto = {};
    outportFrom = {};
    maxGotoTag  = [];

    for z = 1:length(outports)
        pConnect = get_param(outports{z}, 'portConnectivity');
        pName    = get_param(outports{z}, 'Name');
        pHandle  = get_param(outports{z}, 'Handle');
        pSID     = get_param(outports{z}, 'SID');
        pHandles = get(pHandle, 'portHandles');
        
        GotoTag = get(pHandles.Inport, 'PropagatedSignals');
        if strcmp(GotoTag, '')
            GotoTag = ['GotoOut' pSID];
            GotoTag = strrep(GotoTag, ':', '');
        end
        
        maxGotoTag(end + 1) = length(GotoTag);
        
        % Add Goto
        Goto = add_block('built-in/Goto', [address  '/GotoOut' pSID]);
        GotoName = ['GotoOut' pSID];
        GotoFullName = getfullname(Goto);
        set_param(Goto, 'GotoTag', GotoTag);
        set_param(Goto, 'BackgroundColor', 'green');
        set_param(Goto, 'Position', get_param(outports{z}, 'Position'));
        outportGoto{end + 1} = GotoFullName;
        
        % Add From
        From = add_block('built-in/From', [address  '/FromOut' pSID]);
        FromName = ['FromOut' pSID];
        FromFullName = getfullname(From);
        outportFrom{end + 1} = FromFullName;
        set_param(From, 'GotoTag', GotoTag);
        set_param(From, 'BackgroundColor', 'green');
        set_param(From, 'Position', get_param(outports{z}, 'Position'));
        
        % Add signal lines
        SrcBlocks = pConnect.SrcBlock;
        SrcPorts  = pConnect.SrcPort;
        for y = 1:length(SrcBlocks)
            SrcBlockName = get_param(SrcBlocks(y), 'Name');
            SrcBlockName = strrep(SrcBlockName, '/','//');
            try
                delete_line(address, [SrcBlockName '/' num2str(SrcPorts(y)+1)], [pName '/1']);
            catch
            end
            add_line(address, [SrcBlockName '/' num2str(SrcPorts(y)+1)],[GotoName '/1'], 'autorouting', 'on');
        end
        add_line(address, [FromName '/1'], [pName '/1'], 'autorouting', 'on');
    end
    
    gotoLength = max(maxGotoTag);
function [address, outportGoto, outportFrom, outports, gotoLength] = OutportSig(address)
	%  OutportSig - A function that adds the outport gotos and froms as
	%  well as connect them
    %
    %   Typical use:
    %		[outaddress, outportGoto, outportFrom, outports, outgotoLength]=OutportSig(address);
    %  
	%	Inputs:
	%		address: the name and location in the model
	%	Outputs:
	%		outportGoto: outport goto handles
	%		outportFrom: outport from handles
	%		outports: outport handles
	%		gotoLength: max length of outport signals
	%
	outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');
	outportGoto = {};
	outportFrom = {};
	maxGotoTag=[];
	for z=1:length(outports)
    	pConnect = get_param(outports{z}, 'portConnectivity');
        pName    = get_param(outports{z}, 'Name');
        pHandle  = get_param(outports{z}, 'Handle');
        pSID     = get_param(outports{z}, 'SID');
        pHandles = get(pHandle, 'portHandles');

        GotoTag  = get(pHandles.Inport, 'PropagatedSignals');
        if strcmp(GotoTag, '')
        	GotoTag = ['GotoOut' pSID];
            GotoTag = strrep(GotoTag, ':', '');
        else
        end
        maxGotoTag(end+1) = length(GotoTag);

        Goto = add_block('built-in/Goto', [address '/GotoOut' pSID]);
        GotoName = ['GotoOut' pSID];
        outportGoto{end+1} = getfullname(Goto);
        set_param(Goto, 'GotoTag', GotoTag);
        set_param(Goto, 'BackgroundColor', 'green');
        set_param(Goto, 'Position', get_param(outports{z}, 'Position'));

        From = add_block('built-in/From', [address  '/FromOut' pSID]);
        FromName = ['FromOut' pSID];
        outportFrom{end+1} = getfullname(From);
        set_param(From, 'GotoTag', GotoTag);
        set_param(From, 'BackgroundColor', 'green');
        set_param(From, 'Position', get_param(outports{z}, 'Position')); 
        
        SrcBlocks = pConnect.SrcBlock;
        SrcPorts  = pConnect.SrcPort;
        for y=1:length(SrcBlocks)
        	pName = strrep(pName,'/','//');
            SrcBlockName=get_param(SrcBlocks(y), 'Name');
            try
                delete_line([address ] ,[SrcBlockName '/' 'Enable' ] , [pName '/1']);
                add_line([address ],[SrcBlockName '/' 'Enable' ] ,[GotoName '/1'], 'autorouting', 'on');
            catch
            end;
            try
            	delete_line([address ] ,[SrcBlockName '/'  'Trigger' ] , [pName '/1']);
                add_line([address ],[SrcBlockName '/'  'Trigger' ] ,[GotoName '/1'], 'autorouting', 'on');
            catch
            end;
            try
            	delete_line([address ] ,[SrcBlockName '/' num2str(SrcPorts(y)+1) ] , [pName '/1']);
                add_line([address ],[SrcBlockName '/' num2str(SrcPorts(y)+1) ] ,[GotoName '/1'], 'autorouting', 'on');
            catch
            end;
        end
        try add_line([address ], [FromName '/1'], [pName '/1'], 'autorouting', 'on'); catch end;
    end
    if isempty(maxGotoTag)
    	gotoLength = 0;
    else
    	gotoLength = max(maxGotoTag);
    end;
end
function [address, inportGoto, inportFrom, inports, gotoLength] = InportSig(address)
	%  InportSig - A function that adds the inport gotos and froms as
	%  well as connect them
    %
    %   Typical use:
    %		[inaddress, inportGoto, inportFrom, inports, ingotoLength] = InportSig(address);
    %  
	%	Inputs:
	%		address: the name and location in the model
	%	Outputs:
	%		inportGoto: inport goto handles
	%		inportFrom: inport from handles
	%		inports:    inport handles
	%		gotoLength: max length of inport signals
	%

    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    inportGoto = {};
    inportFrom = {};
    maxGotoTag = [];

    for z = 1:length(inports)
        pConnect = get_param(inports{z}, 'portConnectivity');
        pName    = get_param(inports{z}, 'Name');
        pHandle  = get_param(inports{z}, 'Handle');
        pSID     = get_param(inports{z}, 'SID');
        
        pHandles = get(pHandle, 'portHandles');
                
%GotoTag = get_param(pHandles.Outport, 'PropagatedSignals');
%if strcmp(GotoTag, '')
        GotoTag = ['GotoIn' pSID];
        GotoTag = strrep(GotoTag, ':', '');
%else
%end
        maxGotoTag(end+1) = length(GotoTag);
        
        Goto = add_block('built-in/Goto', [address '/GotoIn' pSID]);
        GotoName = ['GotoIn' pSID];
        inportGoto{end+1} = getfullname(Goto);
        set_param(Goto, 'GotoTag', GotoTag);
        set_param(Goto, 'BackgroundColor', 'green');
        set_param(Goto, 'Position', get_param(inports{z}, 'Position'));

        From = add_block('built-in/From', [address  '/FromIn' pSID]);
        FromName = ['FromIn' pSID];
        inportFrom{end+1} = getfullname(From);
        set_param(From, 'GotoTag', GotoTag);
        set_param(From, 'BackgroundColor', 'green');
        set_param(From, 'Position', get_param(inports{z}, 'Position')); 
        
        DstBlocks = pConnect.DstBlock;
        DstPorts  = pConnect.DstPort;
        for y=1:length(DstBlocks)
            DstBlockName = get_param(DstBlocks(y), 'Name');
            pName = strrep(pName,'/','//');
            try
            	delete_line([address] ,[pName '/1' ] , [DstBlockName '/' 'Enable']);
                add_line([address],[FromName '/1'] ,[DstBlockName '/' 'Enable'], 'autorouting', 'on');
            catch
            end;
            try
                delete_line([address] ,[pName '/1' ] , [DstBlockName '/' 'Trigger']);
                add_line([address],[FromName '/1'] ,[DstBlockName '/' 'Trigger'], 'autorouting', 'on');
            catch
            end;
            try
                delete_line([address ] ,[pName '/1' ] , [DstBlockName '/' num2str(DstPorts(y)+1)]);
                add_line([address ],[FromName '/1'] ,[DstBlockName '/' num2str(DstPorts(y)+1)], 'autorouting', 'on');
            catch
            end;
        end;
       	try add_line([address ], [pName '/1'], [GotoName '/1']); catch end;
	end
    if isempty(maxGotoTag)
    	gotoLength = 0;
    else
    	gotoLength = max(maxGotoTag);
    end;
end
        
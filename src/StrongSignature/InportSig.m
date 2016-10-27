function [address, inportGoto, inportFrom, inports, gotoLength] = InportSig(address)
%  INPORTSIG Add the Gotos and Froms for Inports
%
%   Function:
%		[inaddress, inportGoto, inportFrom, inports, ingotoLength] = INPORTSIG(address);
%  
%	Inputs:
%		address     Name and location in the model
%
%	Outputs:
%       address
%		inportGoto  Handles of the Inport Gotos
%		inportFrom  Handles of the Inport Froms 
%		inports 	Handles of the Inport
%		gotoLength  Max length of Inport signals
    
    % Initialize outputs
    inportGoto = {};
    inportFrom = {};
    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    gotoLength = 0;
    
    for z = 1:length(inports)
        % Get inport info
        pConnect = get_param(inports{z}, 'portConnectivity');
        pName    = get_param(inports{z}, 'Name');
        pHandle  = get_param(inports{z}, 'Handle');
        pHandles = get(pHandle, 'portHandles');
        
        % Construct goto tag
        pSID     = get_param(inports{z}, 'SID');
        gotoTag  = ['GotoIn' pSID];
        gotoTag  = strrep(gotoTag, ':', '');

        % Get longest tag
        if length(gotoTag) > gotoLength 
            gotoLength = length(gotoTag);
        end
        
        % Goto
        Goto = add_block('built-in/Goto', [address '/GotoIn' pSID]);
        GotoName = gotoTag;
        inportGoto{end + 1} = getfullname(Goto);
        set_param(Goto, 'GotoTag', gotoTag);
        set_param(Goto, 'BackgroundColor', 'green');
        set_param(Goto, 'Position', get_param(inports{z}, 'Position'));

        % From
        From = add_block('built-in/From', [address '/FromIn' pSID]);
        FromName = ['FromIn' pSID];
        inportFrom{end + 1} = getfullname(From);
        set_param(From, 'GotoTag', gotoTag);
        set_param(From, 'BackgroundColor', 'green');
        set_param(From, 'Position', get_param(inports{z}, 'Position')); 
        
        % Signal lines
        DstBlocks = pConnect.DstBlock;
        DstPorts  = pConnect.DstPort;
        for y = 1:length(DstBlocks)
            DstBlockName = get_param(DstBlocks(y), 'Name');
            pName = strrep(pName, '/', '//');
            
            % Inport connected to Enable port
            try
            	delete_line(address, [pName '/1'], [DstBlockName '/' 'Enable']);
                add_line(address, [FromName '/1'], [DstBlockName '/' 'Enable'], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end
            
            % Inport connected to Trigger port
            try
                delete_line(address, [pName '/1'], [DstBlockName '/' 'Trigger']);
                add_line(address, [FromName '/1'], [DstBlockName '/' 'Trigger'], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end
            
            % Inport connected to regular block port
            try
                delete_line(address ,[pName '/1'], [DstBlockName '/' num2str(DstPorts(y)+1)]);
                add_line(address,[FromName '/1'], [DstBlockName '/' num2str(DstPorts(y)+1)], 'autorouting', 'on');
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                    % Do nothing
                end
            end
        end
        
       	try add_line(address, [pName '/1'], [GotoName '/1'])
        catch
        end
    end
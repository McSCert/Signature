function yOffsetFinal = RepositionInportSig(address, inGo, inFrom, ...
    inports, gotoLength)
%   RESPOSITIONINPORTSIG Reposition Inports and Inport Goto/Froms. 
%
%   Inputs:
%       address     Simulink model name.
%       inGo        Inport Goto handles.
%       inFrom      Inport From handles.
%       inports     Inport handles.
%       gotoLength  Max length of the input signal names.
%
%   Outputs:
%       yOffsetFinal Point in the y-axis to start repositioning blocks next time.

    % Where to start the signature
    XMARGIN = 20; 
    yoffset = 30;
    
    % To make appropriately sized Goto/Froms
    tagLength = 14 * gotoLength;
    
    % Reposition Inports
    inportLength = 30;  % The size of Inport blocks, because 
    inportHeight = 14;  % 2011b automatically makes them 10 x 10
    for i = 1:length(inports)
        pos = get_param(inports{i}, 'Position');
		pos(1) = XMARGIN;
        
		if i == 1
			pos(2) = 40;
		else
			pos(2) = yoffset + 20;
		end
		pos(3) = XMARGIN + inportLength;
		pos(4) = pos(2) + inportHeight;
        
		set_param(inports{i}, 'Position', pos);
        
        yoffset = pos(4); % So we know where to add the next Inport
    end
    yOffsetFinal = yoffset;
    
    % Resize and reposition new Gotos to be beside the Inports
    for i = 1:length(inGo)
        gotoHandle = get_param(inGo{i}, 'Handle');
        inHandle = get_param(inports{i}, 'Handle');
        
        resizeBlock(gotoHandle, tagLength, 14);
        moveToBlock(gotoHandle, inHandle, 0);
        redrawLine(address, inHandle, gotoHandle);
    end

    % Resize new Froms (that connect the Signature)
    for i = 1:length(inFrom)
        resizeBlock(inFrom{i}, tagLength, blockHeight(inFrom{i}))
    end
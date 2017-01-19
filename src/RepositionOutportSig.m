function yOffsetFinal = RepositionOutportSig(address, outGo, outFrom, outports, gotoLength, yOffset)
%  REPOSITIONOUTPORTSIG Reposition Outports and Outport Goto/Froms

%	Inputs:
%		address 	The name and location in the model.
%		outGo	 	Outport Goto handles.
%		outFrom 	Outport From handles.
%		outports 	Outport handles.
%		gotoLength 	Max length of the output signal names.
%		yOffset 	Point in the y-axis to start positioning blocks.
%
%	Outputs:
%		yOffsetFinal Point in the y-axis to start repositioning blocks next time.

    % To make appropriately sized Goto/Froms
    tagLength = 11 * gotoLength;
    
    % For starting the signature
    XMARGIN = 30; 
    
	% Reposition Froms
    for i = 1:length(outFrom)
        resizeBlock(outFrom{i}, tagLength, 14);
 
		pos = get_param(outFrom{i}, 'Position');
		pos(1) = XMARGIN;
		if yOffset == 0
			pos(2) = 60;
		else
			pos(2) = yOffset + 20;
		end
		pos(3) = XMARGIN + blockLength(outFrom{i});
		pos(4) = pos(2) + blockHeight(outFrom{i});
		set_param(outFrom{i}, 'Position', pos);
        
        yOffset = pos(4); % So we know where to add the next Outport
    end

	% Reposition Outports to be beside the Froms
    for i = 1:length(outports)
        outHandle = get_param(outports{i}, 'Handle');
        fromHandle = get_param(outFrom{i}, 'Handle');
        
        moveToBlock(outHandle, fromHandle, 0);
        redrawLine(address, fromHandle, outHandle);
    end
    
    % Rezise new Gotos (that connect the Signature)
    for i = 1:length(outGo)
        resizeBlock(outGo{i}, tagLength, blockHeight(outGo{i}));
    end
    
    % Update offset output
	yOffsetFinal = yOffset;
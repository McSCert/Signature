function yOffsetFinal = RepositionInportSig(address, inGo, inFrom, inports, gotoLength)
%   RESPOSITIONINPORTSIG Reposition Inports and Inport Goto/Froms. 
%
%   Inputs:
%       address     The name and location in the model.
%       inGo        Inport Goto handles.
%       inFrom      Inport From handles.
%       inports     Inport handles.
%       gotoLength  Max length of the input signal names.
%
%   Outputs:
%       yOffsetFinal Point in the y-axis to start repositioning blocks next time.

    allBlocks = find_system(address, 'SearchDepth', 1);
    allBlocks = setdiff(allBlocks, address);
    annotations = find_system(address, 'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');
    nonInport = setdiff(allBlocks, inports);
    nonInportGo = setdiff(nonInport, inGo);
    nonInportGoFrom = setdiff(nonInportGo, inFrom);
    
    % For starting the signature
    XMARGIN = 30; 
    yoffset = 30;
    
    % For moving the model to accmodate the signature
    XSHIFT = 200 + (20 * gotoLength);
    YSHIFT = 0;
    
    % To make appropriately sized Goto/Froms
    tagLength = 11 * gotoLength;
    
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
    
    % Reposition new Gotos to be beside the Inports
    for i = 1:length(inGo)
        gotoHandle = get_param(inGo{i}, 'Handle');
        inHandle = get_param(inports{i}, 'Handle');
        
        resizeBlock(gotoHandle, tagLength, 14);
        moveToBlock(gotoHandle, inHandle, 0);
        redrawLine(address, inHandle, gotoHandle);
    end

    % Reposition and resize new Froms (that connect the Signature)
    for i = 1:length(inFrom)
        fPosition = get_param(inFrom{i}, 'Position');
        fPosition(1) = fPosition(1) + XSHIFT;
		fPosition(2) = fPosition(2) + YSHIFT;
        fPosition(3) = fPosition(3) + XSHIFT;
		fPosition(4) = fPosition(4) + YSHIFT;
        set_param(inFrom{i}, 'Position', fPosition);
        resizeBlock(inFrom{i}, tagLength, blockHeight(inFrom{i}));
    end

    % Reposition all lines and other blocks aside from inport, and inport gotos and froms
    mdlLinesTwo = [];
    mdlLines = find_system(address, 'Searchdepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
    for zy = 1:length(mdlLines)
        SrcBlock = get_param(mdlLines(zy), 'SrcBlock');
        if ~strcmp(SrcBlock, '')
            SrcBlock = strrep(SrcBlock, '/', '//');
            SrcBlockType = get_param([address '/' SrcBlock], 'BlockType');
            if strcmp(SrcBlockType, 'Inport')
            else
                mdlLinesTwo(end + 1) = mdlLines(zy);
            end
        else
            mdlLinesTwo(end + 1) = mdlLines(zy);
        end
    end

    for i = 1:length(mdlLinesTwo)
        lPint = get_param(mdlLinesTwo(i), 'Points');
        xPint = lPint(:, 1);
        yPint = lPint(:, 2);
        xPint = xPint + XSHIFT;
        yPint = yPint + YSHIFT;
        newPoint = [xPint yPint];
        set_param(mdlLinesTwo(i), 'Points', newPoint);
    end

    % Reposition all blocks not in the signature
    for i = 1:length(nonInportGoFrom)
        allPos = get_param(nonInportGoFrom{i}, 'Position');
        allPos(1) = allPos(1) + XSHIFT;
        allPos(2) = allPos(2) + YSHIFT;
        allPos(3) = allPos(3) + XSHIFT;
        allPos(4) = allPos(4) + YSHIFT;
        set_param(nonInportGoFrom{i}, 'Position', allPos);
    end

    % Reposition annotations
    for i = 1:length(annotations)
        allPos = get_param(annotations(i), 'Position');
        allPos(1) = allPos(1) + XSHIFT;
		allPos(2) = allPos(2) + YSHIFT;
        set_param(annotations(i), 'Position', allPos);
    end
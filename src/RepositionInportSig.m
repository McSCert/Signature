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
    
    tagLength = 10 * gotoLength;
    offsetLeft = 250 + 20*gotoLength;   % Distance between From and block its connected to
    yOffsetFinal = 34;

    inportLegth = 30;
    inportHeight = 14;
    
    % Reposition Inports
    for i = 1:length(inports)
        iPosition = get_param(inports{i}, 'Position');
        iPosition(1) = 20;
        if i == 1
            iPosition(2) = 60;
        else
            iPosition(2) = yOffsetFinal + 20;
        end
        iPosition(3) = 20 + inportLegth;
        iPosition(4) = iPosition(2) + inportHeight;
        yOffsetFinal = iPosition(4);
        set_param(inports{i}, 'Position', iPosition);
    end

    % Reposition Gotos
    for i = 1:length(inGo)
        gPosition = get_param(inports{i}, 'Position');
        gPosition(1) = gPosition(1) + 50;
        gPosition(3) = gPosition(3) + 50 + tagLength;
        set_param(inGo{i}, 'Position', gPosition);
    end

    % Reposition Froms
    for i = 1:length(inFrom)
        fPosition    = get_param(inFrom{i}, 'Position');
        fPosition(1) = fPosition(1) + 250 + tagLength;
        fPosition(2) = fPosition(2) + 200;
        fPosition(3) = fPosition(3) + offsetLeft;
        fPosition(4) = fPosition(4) + 200;
        set_param(inFrom{i}, 'Position', fPosition);
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

    for zm = 1:length(mdlLinesTwo)
        lPint = get_param(mdlLinesTwo(zm), 'Points');
        xPint = lPint(:, 1);
        yPint = lPint(:, 2);
        xPint = xPint + offsetLeft;
        yPint = yPint + 200;
        newPoint = [xPint yPint];
        set_param(mdlLinesTwo(zm), 'Points', newPoint);
    end

    for z = 1:length(nonInportGoFrom)
        bPosition = get_param(nonInportGoFrom{z}, 'Position');
        bPosition(1) = bPosition(1) + offsetLeft;
        bPosition(2) = bPosition(2) + 200;
        bPosition(3) = bPosition(3) + offsetLeft;
        bPosition(4) = bPosition(4) + 200;
        set_param(nonInportGoFrom{z}, 'Position', bPosition);
    end

    for gg = 1:length(annotations)
        bPosition = get_param(annotations(gg), 'Position');
        bPosition(1) = bPosition(1) + offsetLeft;
        bPosition(2) = bPosition(2) + 200;
        set_param(annotations(gg), 'Position', bPosition);
    end
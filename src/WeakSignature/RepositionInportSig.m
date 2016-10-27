function yOffset = RepositionInportSig(address,inGo, inFrom, inports, gotoLength)
    %  RepositionInportSig - A function that repositions the models as well
    %  focusing on the inport, inport gotos, and froms
    %
    %   Typical use:
    %   yOffset=RepositionInportSig(inaddress, InportGoto, InportFrom, inports, gotoLength);
    %  
	%	Inputs:
	%		address: the name and location in the model
	%		inGo: the inport goto handles
	%		inFrom: the inport from handles
	%		inports: the inport handles
	%		gotoLength: the max length of the input signal names
	%	Outputs:
	%		yOffset: the point in the y axis to start reposition of the
	%		blocks
	%
    allBlocks   = find_system(address, 'SearchDepth', 1);
    allBlocks   = setdiff(allBlocks, address);
	annotations = find_system(address,'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');
    nonInport   = setdiff(allBlocks, inports);
    nonInportGo = setdiff(nonInport, inGo);
    nonInportGoFrom = setdiff(nonInportGo, inFrom);
    offset = 300 + 20*gotoLength;
    yOffset = 34;
	%reposition inports
    for zt=1:length(inports)
        iPosition = get_param(inports{zt}, 'Position');
		iPosition(1) = 20;
		if zt==1
			iPosition(2) = 60;
		else
			iPosition(2) = yOffset+20;
		end
		iPosition(3) = 30+20;
		iPosition(4) = iPosition(2)+14;
		yOffset = iPosition(4);
		set_param(inports{zt}, 'Position', iPosition);
	end
	%reposition Gotos and Froms
    for y=1:length(inGo)
        gPosition    = get_param(inports{y}, 'Position');
        gPosition(1) = gPosition(1)+50;
        gPosition(3) = gPosition(3)+50+10*gotoLength;
        set_param(inGo{y}, 'Position', gPosition);
    end
    for x=1:length(inFrom)
        fPosition    = get_param(inFrom{x}, 'Position');
        fPosition(1) = fPosition(1)+250+10*gotoLength;
		fPosition(2) = fPosition(2)+200;
        fPosition(3) = fPosition(3)+250+20*gotoLength;
		fPosition(4) = fPosition(4)+200;
        set_param(inFrom{x}, 'Position', fPosition);
    end
    
    mdlLinesTwo=[];

    add_block('built-in/Note',[address '/Main Simulink Block'], 'Position', [offset+20*gotoLength 10], 'FontSize', 30)
	%reposition blocks aside from inport, inport gotos and froms, as well
	%as lines
    mdlLines = find_system(address,'Searchdepth',1, 'FollowLinks', 'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
    for zy=1:length(mdlLines)
    	SrcBlock = get_param(mdlLines(zy), 'SrcBlock');
        if ~strcmp(SrcBlock, '')
        	SrcBlock = strrep(SrcBlock,'/','//');
            SrcBlockType = get_param([address '/' SrcBlock], 'BlockType');
            if strcmp(SrcBlockType, 'Inport')
            else
                mdlLinesTwo(end+1) = mdlLines(zy);
            end
        else
            mdlLinesTwo(end+1) = mdlLines(zy);
        end
    end
           
    for zm=1:length(mdlLinesTwo)
    	lPint = get_param(mdlLinesTwo(zm), 'Points');
        xPint = lPint(:,1);
        yPint = lPint(:,2);
        xPint = xPint+offset;
		yPint = yPint+200;
        newPoint = [xPint yPint];
        set_param(mdlLinesTwo(zm), 'Points', newPoint);
	end

    for z=1:length(nonInportGoFrom)
        bPosition    = get_param(nonInportGoFrom{z}, 'Position');
        bPosition(1) = bPosition(1)+offset;
		bPosition(2) = bPosition(2)+200;
        bPosition(3) = bPosition(3)+offset;
		bPosition(4) = bPosition(4)+200;
        set_param(nonInportGoFrom{z}, 'Position', bPosition);
	end      
	for gg=1:length(annotations)
        bPosition    = get_param(annotations(gg), 'Position');
        bPosition(1) = bPosition(1)+offset;
		bPosition(2) = bPosition(2)+200;
        set_param(annotations(gg), 'Position', bPosition);
    end  
end    
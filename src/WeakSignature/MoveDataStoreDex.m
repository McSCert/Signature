function yOffsetFinal = MoveDataStoreDex(address, yOffset)
% MOVEDATASTOREDEX Place Data Store declarations along the left side of the signature.
%
%   Inputs:
%   	address 	The address of the current system.
%   	yOffset 	Point in the y-axis to start positioning blocks.
%
%	Outputs:
%	  yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);

	for z = 1:length(allBlocks)
		BlockType = get_param(allBlocks{z}, 'BlockType');
		if strcmp(BlockType, 'DataStoreMemory')
			DSName   = get_param(allBlocks{z}, 'DataStoreName');
			DSLength = 10*length(DSName) + 25;
			dsPoints = get_param(allBlocks{z}, 'Position');
			dsPoints(1) = 20;
			dsPoints(2) = yOffset + 20;
			dsPoints(3) = dsPoints(1) + DSLength;
			dsPoints(4) = dsPoints(2) + 30;
			set_param(allBlocks{z}, 'Position', dsPoints);
			yOffset = dsPoints(4) + 10;
        elseif strcmp(BlockType, 'GotoTagVisibility')
            TagName   = get_param(allBlocks{z}, 'GotoTag');
			TagLength = 10*length(TagName) + 25;
			tagPoints = get_param(allBlocks{z}, 'Position');
			tagPoints(1) = 20;
			tagPoints(2) = yOffset + 20;
			tagPoints(3) = tagPoints(1) + TagLength;
			tagPoints(4) =tagPoints(2) + 30;
			set_param(allBlocks{z}, 'Position', tagPoints);
			yOffset = tagPoints(4) + 10;
        end
    end
    
    yOffsetFinal = yOffset;
end
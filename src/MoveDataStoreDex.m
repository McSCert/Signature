function yOffsetFinal = MoveDataStoreDex(address, yOffset)
% MOVEDATASTOREDEX Move Data Store Memory blocks to the left side of the signature.
%
%   Inputs:
%       address     Simulink system path.
%       yOffset     Point in the y-axis to start positioning blocks.
%
%   Outputs:
%       yOffsetFinal Point in the y-axis to start repositioning blocks next time.

    % For starting the signature
    XMARGIN = 30; 
    
	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);
    
	for z = 1:length(allBlocks)
		BlockType = get_param(allBlocks{z}, 'BlockType');
		if strcmp(BlockType, 'DataStoreMemory')
			dsName   = get_param(allBlocks{z}, 'DataStoreName');
			dsLength = 11 * length(dsName);
            
			dsPos = get_param(allBlocks{z}, 'Position');
			dsPos(1) = XMARGIN;
			dsPos(2) = yOffset + 20;
			dsPos(3) = dsPos(1) + dsLength;
			dsPos(4) = dsPos(2) + 30;
            
			set_param(allBlocks{z}, 'Position', dsPos);
            
            % Update for next blocks
			yOffset = dsPos(4);
            
        elseif strcmp(BlockType, 'GotoTagVisibility')
            tagName   = get_param(allBlocks{z}, 'GotoTag');
			tagLength = 11 * length(tagName);
            
			tagPos = get_param(allBlocks{z}, 'Position');
			tagPos(1) = XMARGIN;
			tagPos(2) = yOffset + 20;
			tagPos(3) = tagPos(1) + tagLength;
			tagPos(4) = tagPos(2) + 30;
            
			set_param(allBlocks{z}, 'Position', tagPos);
            
            % Update for next blocks
			yOffset = tagPos(4);
        end
	end
    yOffsetFinal = yOffset;
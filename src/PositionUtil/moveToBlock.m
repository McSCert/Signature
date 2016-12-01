function moveToBlock(block1, block2, onLeft)
%% moveToPort Move a block to the right/left of another block. 
%   block1 is aligned with the center of block2. This function works best
%   when block 2 has one inport when aligning on the left, or outport when
%   aligning on the right.
%
%   Inputs:
%       block1  Handle of the block to be moved.
%       block2  Handle of the block to align the block1 with.
%       onLeft  Boolean indicating if the block is to be on the right(0) or
%               left(1) of the port.
%
%   Outputs:
%       N/A

    BLOCK_OFFSET = 50;

    % Get block1's current position
    block1Position = get_param(block1, 'Position');

    % Get block2's curent position
    block2Position = get_param(block2, 'Position');

    % Compute block dimensions which need to be maintained during the move
    blockHeight = block1Position(4) - block1Position(2);
    blockLength = block1Position(3) - block1Position(1);

    % Compute middle of block2 height, so block1 can be positioned at the center
    block2CenterY = block2Position(2) + ((block2Position(4) - block2Position(2)) / 2);

    block1Position = get_param(block2, 'Position');
    % Compute x dimensions   
    if ~onLeft 
        block1Position(1) = block2Position(3) + BLOCK_OFFSET; % Left
        block1Position(3) = block1Position(1) + blockLength; % Right 
    else
        block1Position(3) = block2Position(1) - BLOCK_OFFSET; % Right
        block1Position(1) = block1Position(3) - blockLength;  % Left
    end

    % Compute y dimensions
    block1Position(2) = block2CenterY - (blockHeight/2); % Top
    block1Position(4) = block2CenterY + (blockHeight/2); % Bottom

    set_param(block1, 'Position', block1Position);
end
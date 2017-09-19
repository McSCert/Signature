function moveToPort(block, port, onLeft)
% MOVETOPORT Move a block to the right/left of a block port.
%
%   Inputs:
%       block   Handle of the block to be moved.
%       port    Handle of the port to align the block with.
%       onLeft  Boolean indicating if the block is to be on the right(0) or
%               left(1) of the port.
%
%   Outputs:
%       N/A

    BLOCK_OFFSET = 70;

    % Get block's current position
    blockPosition = get_param(block, 'Position');

    % Get port position
    portPosition = get_param(port, 'Position');

    % Compute block dimensions which need to be maintained during the move
    blockHeight = blockPosition(4) - blockPosition(2);
    blockLength = blockPosition(3) - blockPosition(1);

    % Compute x dimensions
    if ~onLeft
        newBlockPosition(1) = portPosition(1) + BLOCK_OFFSET; % Left
        newBlockPosition(3) = newBlockPosition(1) + blockLength; % Right
    else
        newBlockPosition(3) = portPosition(1) - BLOCK_OFFSET; % Right
        newBlockPosition(1) = newBlockPosition(3) - blockLength; % Left
    end

    % Compute y dimensions
    newBlockPosition(2) = portPosition(2) - (blockHeight/2); % Top
    newBlockPosition(4) = portPosition(2) + (blockHeight/2); % Bottom

    set_param(block, 'Position', newBlockPosition);
end
function yOffsetFinal = RepositionImplicits(yOffset, blocksToRepo, blockLength, blockOnLeft)
% REPOSITIONIMPLICITS Reposition Gotos/Froms and Data Store Read/Writes added
%   to the signature, representing global data.
%
%   Inputs:
%       yOffset         Point in the y-axis to start positioning blocks.
%
%   	blocksToRepo    The blocks to reposition, and their corresponding
%                       terminators.
%
%   	blockLength     Desired size of the block.
%
%       blockOnLeft     Boolean indicating the orientation of the block
%                       and terminator: block is on the left of the terminator (1),
%                       block is on the right of the terminator (0).
%
%   Outputs:
%       yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    % For starting the signature
    XMARGIN = 30;

    % Block sizes
    termLength = 30; % The size of Terminators blocks
    termHeight = 16;

    blkLength = 10*blockLength;
    blkHeight = 14;

    if blockOnLeft
        for i = 1:length(blocksToRepo{1})
            % Reposition Goto or Data Store Read block
            iPos = get_param(blocksToRepo{1}(i), 'Position');
            iPos(1) = XMARGIN;
            iPos(2) = yOffset + 20;
            iPos(3) = iPos(1) + blkLength;
            iPos(4) = iPos(2) + blkHeight;
            set_param(blocksToRepo{1}(i), 'Position', iPos);

            % Reposition terminator
            resizeBlock(blocksToRepo{2}(i), termLength, termHeight);
            moveToBlock(blocksToRepo{2}(i), blocksToRepo{1}(i), 0);

            % Update for next blocks
            yOffset = iPos(4);
        end
    else
        for j = 1:length(blocksToRepo{1})
            % Reorient
            set_param(blocksToRepo{1}(j), 'Orientation', 'left');
            set_param(blocksToRepo{2}(j), 'Orientation', 'left');

            % Reposition terminator
            jPos = get_param(blocksToRepo{2}(j), 'Position');
            jPos(1) = XMARGIN;
            jPos(2) = yOffset + 20;
            jPos(3) = jPos(1) + termLength;
            jPos(4) = jPos(2) + termHeight;
            set_param(blocksToRepo{2}(j), 'Position', jPos);

            % Reposition From or Data Store Write block
            resizeBlock(blocksToRepo{1}(j), blkLength, blkHeight);
            moveToBlock(blocksToRepo{1}(j), blocksToRepo{2}(j), 0);

            % Update for next blocks
            yOffset = jPos(4);
        end
    end
    % Update offset output
    yOffsetFinal = yOffset;
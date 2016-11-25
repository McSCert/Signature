function yOffsetFinal = RepositionImplicits(yOffset, blocksToRepo, blockLength, blockOnLeft)
% REPOSITIONIMPLICITS Reposition added Gotos/Froms that represent globals
% in the signature.
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

    if blockOnLeft
        for z = 1:length(blocksToRepo{1})
            % Reposition Goto/From block
            fPoints = get_param(blocksToRepo{1}(z), 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 10*blockLength + 20;
            fPoints(4) = fPoints(2) + 14;
            set_param(blocksToRepo{1}(z), 'Position', fPoints);
            
            % Reposition terminator
            tPoints = get_param(blocksToRepo{2}(z), 'Position');
            tPoints(1) = 10*blockLength + 20 + 50;
            tPoints(2) = yOffset + 20;
            tPoints(3) = tPoints(1) + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(blocksToRepo{2}(z), 'Position', tPoints)
            
            % Update for next blocks
            yOffset = fPoints(4);
        end
    else
        for x = 1:length(blocksToRepo{1})
            % Reorient
            set_param(blocksToRepo{1}(x), 'Orientation', 'left');
            set_param(blocksToRepo{2}(x), 'Orientation', 'left');
            
            % Reposition terminator
            fPoints = get_param(blocksToRepo{2}(x), 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 20 + 30;
            fPoints(4) = fPoints(2) + 14;
            set_param(blocksToRepo{2}(x), 'Position', fPoints);
            
            % Reposition Goto/From block
            tPoints = get_param(blocksToRepo{1}(x), 'Position');
            tPoints(1) = fPoints(3) + 50;
            tPoints(2) = fPoints(2);
            tPoints(3) = tPoints(1) + 10*blockLength + 20;
            tPoints(4) = tPoints(2) + 14;
            set_param(blocksToRepo{1}(x), 'Position', tPoints)
            
            % Update for next blocks
            yOffset = tPoints(4);
        end
    end
    % Update offset output
    yOffsetFinal = yOffset;
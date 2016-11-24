function yOffsetFinal = RepositionImplicits(yOffset, blocksToRepo, blockLength, num)
% REPOSITIONIMPLICITS Repositions added Gotos/Froms that represent globals on
% the signature.
%
%   Inputs:
%       yOffset         Point in the y-axis to start positioning blocks.
%       blocksToRepo    A set containing the blocks to reposition, and their
%                       corresponding terminators.
%       blockLength     The desired size of the block.
%       num             Binary digit indicating the orientation of the block 
%                       and terminator. 1 is block on the left of the terminator, 
%                       0 is block on the right of it.
%
%   Outputs:
%       yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    if num == 1
        for z = 1:length(blocksToRepo{1})
            fPoints = get_param(blocksToRepo{1}(z), 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 10*blockLength + 20;
            fPoints(4) = fPoints(2) + 14;
            set_param(blocksToRepo{1}(z), 'Position', fPoints);
            tPoints = get_param(blocksToRepo{2}(z), 'Position');
            tPoints(1) = 10*blockLength + 20 + 50;
            tPoints(2) = yOffset + 20;
            tPoints(3) = tPoints(1) + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(blocksToRepo{2}(z), 'Position', tPoints)
            yOffset = fPoints(4);
        end
    else
        for x = 1:length(blocksToRepo{1})
            set_param(blocksToRepo{1}(x), 'Orientation', 'left');
            set_param(blocksToRepo{2}(x), 'Orientation', 'left');
            fPoints = get_param(blocksToRepo{2}(x), 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 20 + 30;
            fPoints(4) = fPoints(2) + 14;
            yOffset = fPoints(4);
            set_param(blocksToRepo{2}(x), 'Position', fPoints);
            tPoints = get_param(blocksToRepo{1}(x), 'Position');
            tPoints(1) = fPoints(3) + 50;
            tPoints(2) = fPoints(2);
            tPoints(3) = tPoints(1) + 10*blockLength + 20;
            tPoints(4) = tPoints(2) + 14;
            set_param(blocksToRepo{1}(x), 'Position', tPoints)
            yOffset = tPoints(4);
        end
    end

    yOffsetFinal = yOffset;
end
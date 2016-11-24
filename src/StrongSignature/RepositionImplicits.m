function yOffsetFinal = RepositionImplicits(yOffset, blocksToRepo, blockLength, num)
% RESPOSITIONIMPLICITS Reposition added Gotos/Froms that represent globals
% in the signature.
%
%   Function:
%       RESPOSITIONIMPLICITS(yOffset, blocksToRepo, blockLength, num)
%
%   Inputs:
%       yOffset         Point in the y-axis to start positioning blocks.
%
%   	blocksToRepo    The blocks to reposition and their corresponding
%                       terminators.
%
%   	blockLength     The desired size of the block.
%
%   	num             Boolean indicating the orientation of the block and 
%                       terminator: block to the right of the terminator (0) 
%                       or block to the left (1).
%
%   Outputs:
%       yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    if num % Block to the left of the terminator
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
    else % Block to the right of the terminator
        for x = 1:length(blocksToRepo{1})
            set_param(blocksToRepo{1}(x), 'Orientation', 'left');
            set_param(blocksToRepo{2}(x), 'Orientation', 'left');
            
            fPoints =  get_param(blocksToRepo{2}(x), 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 20 + 30;
            fPoints(4) = fPoints(2) + 14;
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
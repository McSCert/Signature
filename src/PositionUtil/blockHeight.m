function h = blockHeight(block)
% BLOCKHEIGHT Return the block's height.
%
% 	Inputs:
%		block 	Handle or name of a block.
%
%	Outputs:
%		h 		Height in pixels.

	pos = get_param(block, 'Position');
    h = pos(4) - pos(2);
end
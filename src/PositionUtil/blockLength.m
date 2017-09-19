function l = blockLength(block)
% BLOCKLENGTH Return the block's length.
%
% 	Inputs:
%		block 	Handle or name of a block.
%
%	Outputs:
%		l 		Length in pixels.

	pos = get_param(block, 'Position');
    l = pos(3) - pos(1);
end
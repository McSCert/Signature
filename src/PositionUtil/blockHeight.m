function h = blockHeight(block)
%% BLOCKHEIGHT Return the block's height
	pos = get_param(block, 'Position');
    h = pos(4) - pos(2);
end
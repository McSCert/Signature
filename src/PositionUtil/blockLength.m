function l = blockLength(block)
%% BLOCKLENGTH Return the block's length.
	pos = get_param(block, 'Position');
    l = pos(3) - pos(1);
end
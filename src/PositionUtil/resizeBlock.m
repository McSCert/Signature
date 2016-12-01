function resizeBlock(block, length, height)
%% resizeBlock Resize a block to a specific length and height. 
%   Resizing is done w.r.t. the center of the block.
%
%   Inputs:
%       block   Handle of the block to be resized.
%       width   New length in pixels.
%       height  New height in pixels.
%
%   Outputs:
%       N/A

    % Get the old block size info
    origBlockPosition = get_param(block, 'Position');
    origWidth = (origBlockPosition(3) - origBlockPosition(1)) / 2;
    origHeight = (origBlockPosition(4) - origBlockPosition(2)) / 2;

    % Compute new block size info
    newBlockPosition = origBlockPosition;
    newWidth = length/2;
    newHeight = height/2;

    % Reset each coordinate to the block center, then change it to the new size
    newBlockPosition(1) = (origBlockPosition(1) + origWidth) - newWidth; % Left
    newBlockPosition(2) = (origBlockPosition(2) + origHeight) - newHeight; % Top  
    newBlockPosition(3) = (origBlockPosition(3) - origWidth) + newWidth; % Right
    newBlockPosition(4) = (origBlockPosition(4) - origHeight) + newHeight; % Bottom 
     
    set_param(block, 'Position', newBlockPosition);
end
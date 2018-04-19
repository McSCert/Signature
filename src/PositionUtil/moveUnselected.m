function moveUnselected(address, xoffset, yshift, dontMoveBlocks, dontMoveNotes)
% MOVEUNSELECTED Move unselected blocks/lines/etc. in a system to a new position.
%
%   Inputs:
%       address         Path of the system to be moved.
%       xoffset         Number of pixels to move horizontally past selected blocks.
%       yshift          Number of pixels to move vertically.
%       dontMoveBlocks  Selected blocks to move past
%       dontMoveNotes   Selected notes to move past
%
%   Outputs:
%       N/A

    % Move line points (needed for lines with branches or bends)
    % Note: Must be done before the the blocks are moved. Sometimes the
    % points move when the blocks are moved. Sometimes they don't.

    dontMoveLines = [];

    allLines = find_system(address, 'Searchdepth', 1, 'FollowLinks', 'on',...
        'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
    linesToMove = setdiff(allLines, dontMoveLines);

    allBlocks = find_system(address, 'SearchDepth', 1, 'type', 'block');
    allBlocks = setdiff(allBlocks, address);
    blocksToMove = setdiff(allBlocks, getfullname(dontMoveBlocks));

    annotationsToMove = find_system(address, 'FindAll', 'on', 'SearchDepth', 1,...
        'type', 'annotation');
    for i = 1:length(dontMoveNotes)
        annotationsToMove = setdiff(annotationsToMove, dontMoveNotes{i}); %because dontMoveNotes is a cell array
    end

    if ~isempty(dontMoveBlocks)
        xshift = get_param(dontMoveBlocks(1), 'Position');
        xshift = xshift(3);

        for i = 1:length(dontMoveBlocks)
            lineHandles = get_param(dontMoveBlocks(i), 'LineHandles');
            dontMoveLines = [dontMoveLines lineHandles.Inport];
            dontMoveLines = [dontMoveLines lineHandles.Outport];
            pos = get_param(dontMoveBlocks(i), 'Position');
            xshift = max(xshift, pos(3));
        end

        if ~isempty(blocksToMove)
            leftXMin = get_param(blocksToMove{1}, 'Position');
            leftXMin = leftXMin(1);
            for i = 1:length(blocksToMove)
                pos = get_param(blocksToMove{i}, 'Position');
                leftXMin = min(leftXMin, pos(1));
            end
        else
            leftXMin = xshift;
        end

        xshift = xshift - leftXMin;
        xshift = max(xshift, 0);
        xshift = xshift + xoffset;

        for k = 1:length(linesToMove)
            pts = get_param(linesToMove(k), 'Points');
            pts(:,1) = pts(:,1) + xshift;
            pts(:,2) = pts(:,2) + yshift;
            set_param(linesToMove(k), 'Points', pts);
        end

        % Move blocks
        for i = 1:length(blocksToMove) % Start at 2 because the root is entry 1
            bPos = get_param(blocksToMove{i}, 'Position');
            bPos(1) = bPos(1) + xshift;
            bPos(2) = bPos(2) + yshift;
            bPos(3) = bPos(3) + xshift;
            bPos(4) = bPos(4) + yshift;
            set_param(blocksToMove{i}, 'Position', bPos);
        end

        % Move annotations
        for j = 1:length(annotationsToMove)
            aPos = get_param(annotationsToMove(j), 'Position');
            aPos(1) = aPos(1) + xshift;
            aPos(2) = aPos(2) + yshift;
            set_param(annotationsToMove(j), 'Position', aPos);
        end
    end
end
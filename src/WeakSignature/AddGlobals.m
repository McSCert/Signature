function [outBlocks, yOffsetFinal] = AddGlobals(address, yOffset, globals, gotoLength, addGotos)
% ADDGLOBALS Add and reposition global Gotos in the model.
%
%	Inputs:
%	  address         Simulink model name or path.
%	  yOffset         Point in the y-axis to start positioning blocks.
%	  globals         Names of all the global blocks to add.
%	  gotoLength      Max length of global tags.
%     addGotos        Number indicating whether adding global Froms(0) or Gotos(1).
%
%	Outputs:
%	  yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    % Where to start the signature
    XMARGIN = 50;

    % Block sizes
    blkLength_factor = 14;

    num = 0;        % Goto/From number
    termnum = 0;    % Terminator number
    
    termBlocks = [];
    globalBlocks = [];

    if addGotos
        for y = 1:length(globals)

            % Add From and Terminator blocks
            From = add_block('built-in/From', [address '/GotoSigGlobal' num2str(num)]);
            Terminator = add_block('built-in/Terminator', [address '/globalGotoTerminator' num2str(termnum)]);

            % Name
            set_param(From, 'GotoTag', globals{y});
            set_param(From, 'TagVisibility', 'global');

            % Reorient
            set_param(From, 'Orientation', 'left');
            set_param(Terminator, 'Orientation', 'left');

            % Reposition Terminator
            tPoints = get_param(Terminator, 'Position');
            tPoints(1) = XMARGIN;
            tPoints(2) = yOffset + 20;
            tPoints(3) = XMARGIN + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(Terminator, 'position', tPoints)

            % Reposition From
            fPoints = get_param(From, 'Position');
            fPoints(1) = tPoints(3) + 50;
            fPoints(2) = tPoints(2);
            fPoints(3) = fPoints(1) + (blkLength_factor * gotoLength);
            fPoints(4) = fPoints(2) + 14;
            set_param(From, 'position', fPoints);

            % Connect with signal line
            add_line(address,['GotoSigGlobal' num2str(termnum) '/1'], ['globalGotoTerminator' num2str(num) '/1'])

            % Update for next blocks being added
            yOffset = tPoints(4);
            num = num + 1;
            termnum = termnum + 1;
            
            globalBlocks(end+1) = From;
            termBlocks(end+1) = Terminator;
        end
    else
        for y = 1:length(globals)

            % Add From and Terminator blocks
            From = add_block('built-in/From', [address '/FromSigGlobal' num2str(num)]);
            Terminator = add_block('built-in/Terminator', [address '/globalTerminator' num2str(termnum)]);

            % Name
            set_param(From, 'GotoTag', globals{y});
            set_param(From, 'TagVisibility', 'global');

            % Reposition From
            fPoints =  get_param(From, 'Position');
            fPoints(1) = XMARGIN;
            fPoints(2) = yOffset + 20;
            fPoints(3) = XMARGIN + (blkLength_factor * gotoLength);
            fPoints(4) = fPoints(2) + 14;
            set_param(From, 'position', fPoints);

            % Reposition Terminator
            tPoints = get_param(Terminator, 'position');
            tPoints(1) = fPoints(3) + 50;
            tPoints(2) = fPoints(2);
            tPoints(3) = tPoints(1) + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(Terminator, 'position', tPoints)

            % Connect with signal line
            add_line(address, ['FromSigGlobal' num2str(num) '/1'], ['globalTerminator' num2str(termnum) '/1'])

            % Update for next blocks being added
            yOffset = fPoints(4);
            num = num + 1;
            termnum = termnum + 1;
            
            globalBlocks(end+1) = From;
            termBlocks(end+1) = Terminator;
        end
    end
    % Update offset output
    yOffsetFinal = yOffset;
    outBlocks = {globalBlocks, termBlocks};
end
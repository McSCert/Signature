function yOffsetFinal = AddGlobals(address, yOffset, globalGotos, gotoLength, dgt)
%  ADDGLOBALS Add and reposition global Gotos in the model.
%
%	Inputs:
%	  address         Name and location in the model.
%	  yOffset         Point in the y-axis to start positioning blocks.
%	  globalGotos     Names of all the global Gotos to add.
%	  gotoLength      Max length of global Goto tags.
%
%	Outputs:
%	  yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    num = 0;
    termnum = 0;

    if dgt == 0
        for y = 1:length(globalGotos)
            From = add_block('built-in/From', [address  '/FromSigGlobal' num2str(num)]);
            Terminator = add_block('built-in/Terminator', [address  '/globalTerminator' num2str(termnum)]);
            set_param(From, 'GotoTag', globalGotos{y});
            set_param(From, 'TagVisibility', 'global');
            fPoints =  get_param(From, 'Position');
            fPoints(1) = 20;
            fPoints(2) = yOffset + 20;
            fPoints(3) = 10*gotoLength + 20;
            fPoints(4) = fPoints(2) + 14;
            yOffset = fPoints(4);
            set_param(From, 'position', fPoints);
            tPoints = get_param(Terminator, 'position');
            tPoints(1) = 10*gotoLength + 20 + 50;
            tPoints(2) = fPoints(2);
            tPoints(3) = tPoints(1) + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(Terminator, 'position', tPoints)
            add_line(address, ['FromSigGlobal' num2str(num) '/1'], ['globalTerminator' num2str(termnum) '/1'])
            num = num + 1;
            termnum = termnum + 1;
        end
    else
        for y = 1:length(globalGotos)
            From = add_block('built-in/From', [address  '/GotoSigGlobal' num2str(num)]);
            Terminator = add_block('built-in/Terminator', [address  '/globalGotoTerminator' num2str(termnum)]);
            set_param(From, 'GotoTag', globalGotos{y});
            set_param(From, 'TagVisibility', 'global');
            set_param(From, 'Orientation', 'left');
            set_param(Terminator, 'Orientation', 'left');
            tPoints =  get_param(Terminator, 'Position');
            tPoints(1) = 20;
            tPoints(2) = yOffset + 20;
            tPoints(3) = 20 + 30;
            tPoints(4) = tPoints(2) + 14;
            set_param(Terminator, 'position', tPoints)
            yOffset = tPoints(4);
            fPoints = get_param(From, 'Position');
            fPoints(1) = tPoints(3) + 50;
            fPoints(2) = tPoints(2);
            fPoints(3) = fPoints(1) + 10*gotoLength + 20;
            fPoints(4) = fPoints(2) + 14;
            set_param(From, 'position', fPoints);
            add_line(address,['GotoSigGlobal' num2str(termnum) '/1'], ['globalGotoTerminator' num2str(num) '/1'])
            num = num + 1;
            termnum = termnum + 1;
        end
    end
    
    yOffsetFinal = yOffset;
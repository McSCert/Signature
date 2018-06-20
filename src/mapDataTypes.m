function dataTypeMap = mapDataTypes(sys)
    % MAPDATATYPES maps the blocks of a Simulink system to a corresponding
    %   datatype.
    %
    % Inputs:
    %   sys             Simulink system.
    %
    % Outputs:
    %   dataTypeMap     A containers.Map() going from full block names to a
    %                   char array describing the type of its output.
    
    dtStruct = getDataTypeInfo(sys);
    
    dataTypeMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for i = 1:length(dtStruct)
        switch length(dtStruct{i}.datatype)
            case 0
                error('Something went wrong.') % Should be '' even when there is no datatype
            case 1
                if isempty(dtStruct{i}.datatype{1}) % datatype is ''
                    type = get_param(dtStruct{i}.typesource{1}, 'Type');
                    switch type
                        case 'block'
                            sourceFullName = getfullname(dtStruct{i}.typesource{1});
                            if strcmp(dtStruct{i}.block, sourceFullName)
                                % if same block, then block had no typing
                                % information available
                                dataTypeMap(dtStruct{i}.block) = 'N/A';
                            else
                                % if different block, then original block
                                % inherits its type from this one
                                sourceName = getBlockName(dtStruct{i}.typesource{1});
                                dataTypeMap(dtStruct{i}.block) = ['Inherit from: ' sourceName];
                            end
                        case 'port'
                            % inherit from port
                            sourceName = getPortName(dtStruct{i}.typesource{1});
                            dataTypeMap(dtStruct{i}.block) = ['Inherit from: ' sourceName];
                        case 'line' 
                            % Not possible because datatypes were only
                            % checked for blocks and blocks just use their
                            % inport as a source instead of the line
                            % connecting to it.
                            assert('Something went wrong.')
                        case 'annotation'
                            assert('Something went wrong.')
                        otherwise
                            assert('Unexpected handle type.')
                    end
                else
                    tmpdatatype = dtStruct{i}.datatype{1};
                    
                    if regexp(tmpdatatype, '^Inherit: ', 'ONCE') == 1
                        type = get_param(dtStruct{i}.typesource{1}, 'Type');
                        switch type
                            case 'block'
                                % inherit from this block
                                sourceName = getBlockName(dtStruct{i}.typesource{1});
                            case 'port'
                                % inherit from port
                                sourceName = getPortName(dtStruct{i}.typesource{1});
                            case 'line'
                                % Not possible because datatypes were only
                                % checked for blocks and blocks just use their
                                % inport as a source instead of the line
                                % connecting to it.
                                assert('Something went wrong.')
                            case 'annotation'
                                assert('Something went wrong.')
                            otherwise
                                assert('Unexpected handle type.')
                        end
                         tmpdatatype = [tmpdatatype(10:end) 'from: ' sourceName];
                     end
                     
                     dataTypeMap(dtStruct{i}.block) = tmpdatatype;
                end
            otherwise
                dataTypeMap(dtStruct{i}.block) = 'Inherit from multiple';
        end
    end
    
end
function block_name = getBlockName(block)
    %
    
    % Modify name so that it will be more readable in a document
    block_name = regexprep(get_param(block, 'Name'), ' \s+|\s', ' '); % Remove consecutive whitespace
end
function port_name = getPortName(port)
    port_type = get_param(port, 'PortType');
    if strcmp(port_type, 'inport')
        p_id = ['in' num2str(get_param(port, 'PortNumber'))];
    elseif strcmp(port_type, 'outport')
        p_id = ['out' num2str(get_param(port, 'PortNumber'))];
    else
        p_id = port_type;
    end
    port_name = [getBlockName(get_param(port, 'Parent')) '/' p_id];
end

function dtStruct = getDataTypeInfo(sys)
    % TODO consider new implementation that passes the 3rd output of
    % getDataType back into it in iterative calls so that it can check if a
    % handle is already in covered before doing the work to find its
    % datatype.
    
    blocks = find_system(sys, ...
        'LookUnderMasks','All','IncludeCommented','on','Variants','AllVariants', ...
        'Type', 'block');
    
    dtStruct = cell(1,length(blocks));
    for i = 1:length(blocks)
        bh = get_param(blocks{i}, 'Handle');
        
        depth = getDepthFromSys(sys, get_param(bh, 'Parent'));
        [datatype, typesource, ~] = getDataType(bh, 'SystemDepth', depth);
        % Note: dts is like dtStruct in form except that the first
        % parameter is handle instead of block and can be other types of
        % handles
        
        dtStruct{i}.block = blocks{i};
        dtStruct{i}.datatype = datatype;
        dtStruct{i}.typesource = typesource;
    end
end
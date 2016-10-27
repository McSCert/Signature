%% Register custom menu function to beginning of Simulink Editor's context menu
function sl_customization(cm)
	cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMySLToolbox);
end

%% Define the custom menu function
function schemaFcns = getMySLToolbox(callbackInfo) 
	schemaFcns = {@getSigToolbox}; 
end

%% Define top-level menu item
function schema = getSigToolbox(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Signature Tool';
    schema.ChildrenFcns = {@getSignatureTool, @getTestHarness}; 
end

%% Define first sub-menu item
function schema = getSignatureTool(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Extract Signature';
    schema.userdata = 'Signature';
    schema.callback = @SignatureToolCallback;
end

function SignatureToolCallback(callbackInfo)
    sigGUI;
end

%% Define second sub-menu item
function schema = getTestHarness(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Augment for Test Harness';
    schema.userdata = 'TestHarness';
    schema.callback = @testHarnessCallback;
end

function testHarnessCallback(callbackInfo)
    TestHarness(gcs);
end
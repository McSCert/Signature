%% Register custom menu function to beginning of Simulink Editor's context menu
function sl_customization(cm)
	cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMcMasterTool);
end

%% Define the custom menu function
function schemaFcns = getMcMasterTool(callbackInfo) 
	schemaFcns = {@getSignatureToolbox}; 
end

%% Define custom menu item
function schema = getSignatureToolbox(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Signature';
    schema.ChildrenFcns = {@getSignature @getTestHarness}; 
end

%% Define first action: Extract Signature
function schema = getSignature(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Extract Signature';
    schema.userdata = 'Signature';
    schema.callback = @SignatureCallback;
end

function SignatureCallback(callbackInfo)
    sigGUI;
end

%% Define second action: Augment for Test Harness
function schema = getTestHarness(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Augment for Test Harness';
    schema.userdata = 'TestHarness';
    schema.callback = @testHarnessCallback;
end

function testHarnessCallback(callbackInfo)
    TestHarness(gcs);
end
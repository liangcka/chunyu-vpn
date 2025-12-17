function Component()
{
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    var targetDir = installer.value("TargetDir");
    component.addOperation("CopyDirectory",
                           "@TargetDir@",
                           targetDir);
}


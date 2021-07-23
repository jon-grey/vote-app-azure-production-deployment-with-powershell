# Fetch the latest Bicep CLI binary
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
# Mark it as executable
chmod +x ./bicep
# Add bicep to your PATH (requires admin)
sudo mv ./bicep /usr/local/bin/bicep
# Verify you can now access the 'bicep' command
bicep --help
# Done!

echo "

# Convert from JSON to Bicep
The Bicep CLI provides a command to decompile any existing JSON template to a Bicep file. 
To decompile a JSON file, use:

```sh
bicep decompile mainTemplate.json
```

## NOTE:
This command provides a starting point for Bicep authoring. The command doesn't work for all templates. 
Currently, nested templates can be decompiled only if they use the 'inner' expression evaluation scope. 
Templates that use copy loops can't be decompiled.
"
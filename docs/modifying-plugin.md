# Modifying/Testing/Deploying Plugins

Workflow for modifying plugins in this repo:

## 1. Modify

- Edit files in the `plugins/<plugin-name>/` directory.
- Update the plugin version appropriately in plugin.json.

## 2. Test

Testing methods vary by plugin type:

- **If a test script exists** (e.g., `attention-hook`): Run the script
  ```bash
  plugins/attention-hook/hooks/scripts/attention.test.sh
  ```
- **For skills**: Apply locally and run directly to verify behavior

## 3. Apply Locally

Plugins are copied to cache on installation, so you must reinstall after making changes:
```bash
/plugin install <plugin-name>@corca-plugins
```

## 4. Deploy

Once modifications are complete, commit & push. Inform users as follows:
```
The plugin has been updated. To apply:
1. /plugin marketplace update
2. /plugin install <plugin-name>@corca-plugins
```
const vscode = require('vscode');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
  const runInTerminal = (cmd) => {
    const term = vscode.window.createTerminal({ name: 'Kiro Validator' });
    term.show(true);
    term.sendText(cmd, true);
  };

  const getWorkspaceFolder = () => {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
      vscode.window.showErrorMessage('No workspace folder open.');
      return undefined;
    }
    return folders[0].uri.fsPath;
  };

  const validateSpec = vscode.commands.registerCommand('kiro.validateSpec', async () => {
    const root = getWorkspaceFolder();
    if (!root) return;

    const feature = await vscode.window.showInputBox({
      title: 'Feature name (kebab-case)',
      prompt: 'Example: user-login',
      value: 'example-feature',
      validateInput: (v) => v.trim() ? null : 'Feature is required'
    });
    if (!feature) return;

    const phase = await vscode.window.showQuickPick(['requirements', 'design', 'tasks', 'all'], {
      title: 'Select phase to validate',
      canPickMany: false
    });
    if (!phase) return;

    const script = `${root}/scripts/kiro-spec-validate.sh`;
    runInTerminal(`bash "${script}" "${feature}" "${phase}"`);
  });

  const validateLatest = vscode.commands.registerCommand('kiro.validateLatestSpec', async () => {
    const root = getWorkspaceFolder();
    if (!root) return;

    const phase = await vscode.window.showQuickPick(['requirements', 'design', 'tasks', 'all'], {
      title: 'Select phase to validate',
      canPickMany: false
    });
    if (!phase) return;

    const script = `${root}/scripts/kiro-spec-validate-latest.sh`;
    runInTerminal(`bash "${script}" "${phase}"`);
  });

  context.subscriptions.push(validateSpec, validateLatest);
}

function deactivate() {}

module.exports = { activate, deactivate };

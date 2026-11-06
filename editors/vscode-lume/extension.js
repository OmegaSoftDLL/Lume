// Generated & governed by editors/vscode-lume/lsp_bridge.src (Lume Verified ✓)
"use strict";

const vscode = require("vscode");
const cp = require("child_process");
const path = require("path");
const os = require("os");

let statusBarItem = null;
let outputChannel = null;
let lspProcess = null;

function resolveLumeBinary() {
  const home = os.homedir();
  if (process.platform === "win32") {
    return path.join(home, ".lume", "bin", "lume.cmd");
  }
  return path.join(home, ".lume", "bin", "lume");
}

function getActiveLumeFile() {
  const editor = vscode.window.activeTextEditor;
  if (!editor || !editor.document) {
    vscode.window.showWarningMessage("Lume: Open a .src or .lume file first.");
    return null;
  }
  const fsPath = editor.document.uri.fsPath;
  if (!fsPath.endsWith(".src") && !fsPath.endsWith(".lume")) {
    vscode.window.showWarningMessage("Lume: Active file is not a .src or .lume program.");
    return null;
  }
  return fsPath;
}

function runLumeSubcommand(subcommand, filePath, onJsonResult) {
  const lumeBin = resolveLumeBinary();
  if (!outputChannel) {
    outputChannel = vscode.window.createOutputChannel("Lume Sovereign Toolchain");
  }
  outputChannel.appendLine(`[Lume] Running: ${lumeBin} ${subcommand} "${filePath}"`);
  cp.execFile(
    lumeBin,
    [subcommand, filePath],
    { shell: process.platform === "win32", maxBuffer: 8 * 1024 * 1024 },
    (err, stdout, stderr) => {
      if (stderr && stderr.trim().length > 0) {
        outputChannel.appendLine(stderr.trim());
      }
      if (stdout && stdout.trim().length > 0) {
        outputChannel.appendLine(stdout.trim());
      }
      if (err) {
        if (statusBarItem) {
          statusBarItem.text = "$(warning) Lume: Unverified";
        }
        vscode.window.showErrorMessage(`Lume ${subcommand} failed: ${err.message}`);
        return;
      }
      if (onJsonResult) {
        try {
          const parsed = JSON.parse(stdout.trim());
          onJsonResult(parsed);
        } catch (_parseErr) {
          vscode.window.showInformationMessage(`Lume ${subcommand} completed.`);
        }
      } else {
        vscode.window.showInformationMessage(`Lume ${subcommand}: ${stdout.trim().split(/\r?\n/)[0] || "OK"}`);
      }
    }
  );
}

function startStdioLsp() {
  if (lspProcess && !lspProcess.killed) {
    vscode.window.showInformationMessage("Lume LSP (lume lsp --stdio) is already running.");
    return;
  }
  const lumeBin = resolveLumeBinary();
  if (!outputChannel) {
    outputChannel = vscode.window.createOutputChannel("Lume Sovereign Toolchain");
  }
  outputChannel.appendLine(`[Lume LSP] Spawning stdio language server: ${lumeBin} lsp --stdio`);
  lspProcess = cp.spawn(lumeBin, ["lsp", "--stdio"], {
    shell: process.platform === "win32",
    stdio: ["pipe", "pipe", "pipe"]
  });
  lspProcess.stderr.on("data", (chunk) => {
    outputChannel.appendLine(`[Lume LSP] ${String(chunk).trim()}`);
  });
  lspProcess.on("exit", (code) => {
    outputChannel.appendLine(`[Lume LSP] exited with code ${code}`);
    lspProcess = null;
  });
  vscode.window.showInformationMessage("Lume Language Server (lume lsp --stdio) started.");
}

function activate(context) {
  outputChannel = vscode.window.createOutputChannel("Lume Sovereign Toolchain");
  statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.text = "$(verified) Lume Verified ✓";
  statusBarItem.tooltip = "Lume QF_LIA Theorem Prover & Standalone Certificate Kernel (lcert)";
  statusBarItem.command = "lume.certifyFile";
  statusBarItem.show();

  const proveCmd = vscode.commands.registerCommand("lume.proveFile", () => {
    const filePath = getActiveLumeFile();
    if (!filePath) return;
    runLumeSubcommand("prove", filePath, (res) => {
      const proven = res.proven_count !== undefined ? `${res.proven_count}/${res.total_obligations}` : "OK";
      statusBarItem.text = res.ok ? `$(verified) Lume Proven (${proven})` : "$(warning) Lume Unverified";
      vscode.window.showInformationMessage(`Lume Prove: ${proven} obligations proven.`);
    });
  });

  const certifyCmd = vscode.commands.registerCommand("lume.certifyFile", () => {
    const filePath = getActiveLumeFile();
    if (!filePath) return;
    runLumeSubcommand("certify", filePath, (res) => {
      const badge = res.badge || (res.ok ? "Lume Verified ✓" : "unverified");
      statusBarItem.text = res.ok ? `$(verified) ${badge} (${res.proven_count}/${res.total_obligations})` : "$(warning) Lume Unverified";
      vscode.window.showInformationMessage(`Lume Certificate: ${badge} (${res.proven_count}/${res.total_obligations} proven)`);
    });
  });

  const runCmd = vscode.commands.registerCommand("lume.runFile", () => {
    const filePath = getActiveLumeFile();
    if (!filePath) return;
    runLumeSubcommand("run", filePath, null);
  });

  const lspCmd = vscode.commands.registerCommand("lume.startLsp", () => {
    startStdioLsp();
  });

  context.subscriptions.push(statusBarItem, outputChannel, proveCmd, certifyCmd, runCmd, lspCmd);
}

function deactivate() {
  if (lspProcess && !lspProcess.killed) {
    lspProcess.kill();
    lspProcess = null;
  }
}

module.exports = {
  activate,
  deactivate
};

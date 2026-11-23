import { EditorView, basicSetup } from "codemirror";
import { EditorState, Compartment, Transaction, Prec } from "@codemirror/state";
import { keymap } from "@codemirror/view";
import { indentWithTab } from "@codemirror/commands";
import { indentUnit } from "@codemirror/language";
import { html } from "@codemirror/lang-html";
import { linter, lintGutter } from "@codemirror/lint";
import { oneDark } from "@codemirror/theme-one-dark";
import * as prettier from "prettier/standalone";
import * as prettierHtml from "prettier/plugins/html";
import * as prettierPostcss from "prettier/plugins/postcss";
import * as prettierBabel from "prettier/plugins/babel";
import * as prettierEstree from "prettier/plugins/estree";
import { HTMLHint } from "htmlhint";

const hintRules = {
  "doctype-first": true,
  "doctype-html5": true,
  "title-require": true,
  "tag-pair": true,
  "tag-self-close": false,
  "tagname-lowercase": true,
  "attr-lowercase": true,
  "attr-no-duplication": true,
  "attr-value-double-quotes": true,
  "attr-value-not-empty": false,
  "id-unique": true,
  "src-not-empty": true,
  "alt-require": true,
  "spec-char-escape": true,
  "head-script-disabled": false,
  "style-disabled": false
};

function post(message) {
  window.webkit?.messageHandlers?.editor?.postMessage(message);
}

function severityOf(type) {
  if (type === "error") return "error";
  if (type === "warning") return "warning";
  return "info";
}

const htmlLinter = linter(
  (view) => {
    const doc = view.state.doc;
    const results = HTMLHint.verify(doc.toString(), hintRules);

    const diagnostics = results.map((result) => {
      const line = doc.line(Math.min(Math.max(result.line, 1), doc.lines));
      const from = Math.min(line.from + Math.max(result.col - 1, 0), line.to);
      const length = Math.max((result.raw ?? "").length, 1);
      const to = Math.min(from + length, line.to);
      return {
        from,
        to,
        severity: severityOf(result.type),
        message: result.message,
        source: result.rule?.id
      };
    });

    post({
      type: "lint",
      errors: diagnostics.filter((d) => d.severity === "error").length,
      warnings: diagnostics.filter((d) => d.severity === "warning").length
    });

    return diagnostics;
  },
  { delay: 300 }
);

async function formatDocument() {
  const code = view.state.doc.toString();
  try {
    const formatted = await prettier.format(code, {
      parser: "html",
      plugins: [prettierHtml, prettierPostcss, prettierBabel, prettierEstree],
      printWidth: 100,
      tabWidth: 2,
      htmlWhitespaceSensitivity: "css"
    });
    post({ type: "formatted" });
    if (formatted === code) return;

    const head = Math.min(view.state.selection.main.head, formatted.length);
    view.dispatch({
      changes: { from: 0, to: view.state.doc.length, insert: formatted },
      selection: { anchor: head },
      userEvent: "format"
    });
  } catch (error) {
    const message = String(error?.message ?? error).split("\n")[0];
    post({ type: "formatError", message });
  }
}

const themeCompartment = new Compartment();
const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");
const themeFor = (isDark) => (isDark ? oneDark : []);

let isApplyingExternalChange = false;

const view = new EditorView({
  parent: document.getElementById("editor"),
  state: EditorState.create({
    doc: "",
    extensions: [
      basicSetup,
      html(),
      indentUnit.of("  "),
      EditorState.tabSize.of(2),
      EditorView.lineWrapping,
      lintGutter(),
      htmlLinter,
      themeCompartment.of(themeFor(darkQuery.matches)),
      Prec.high(
        keymap.of([
          indentWithTab,
          {
            key: "Mod-s",
            preventDefault: true,
            run: () => {
              formatDocument();
              return true;
            }
          }
        ])
      ),
      Prec.highest(
        EditorView.domEventHandlers({
          keydown(event) {
            const isFormatShortcut =
              event.code === "KeyF" &&
              event.altKey &&
              event.shiftKey &&
              !event.metaKey &&
              !event.ctrlKey;
            if (!isFormatShortcut) return false;
            event.preventDefault();
            formatDocument();
            return true;
          }
        })
      ),
      EditorView.updateListener.of((update) => {
        if (update.docChanged && !isApplyingExternalChange) {
          post({ type: "change", text: update.state.doc.toString() });
        }
      })
    ]
  })
});

darkQuery.addEventListener("change", (event) => {
  view.dispatch({ effects: themeCompartment.reconfigure(themeFor(event.matches)) });
});

function setContent(text) {
  if (text === view.state.doc.toString()) return;
  isApplyingExternalChange = true;
  view.dispatch({
    changes: { from: 0, to: view.state.doc.length, insert: text },
    annotations: Transaction.addToHistory.of(false)
  });
  isApplyingExternalChange = false;
}

window.editorBridge = {
  setContent,
  format: formatDocument,
  focus: () => view.focus()
};

post({ type: "ready" });

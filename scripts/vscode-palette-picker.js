#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const [, , workspacePath, mainBackground, accent, foreground, addToGitignore = 'false'] = process.argv;
const clearPalette = mainBackground === '--clear';

if (!workspacePath) {
    console.error('[ERROR] Missing mandatory workspace path argument.');
    process.exit(1);
}

const colors = [mainBackground, accent, foreground];
if (!clearPalette && !colors.every((color) => /^#[0-9a-f]{6}$/i.test(color || ''))) {
    console.error('[ERROR] Palette values must be six-digit hexadecimal colors.');
    process.exit(1);
}

function hexToRgb(hex) {
    const value = hex.replace('#', '');
    return {
        r: parseInt(value.substring(0, 2), 16),
        g: parseInt(value.substring(2, 4), 16),
        b: parseInt(value.substring(4, 6), 16),
    };
}

function rgbToHex({ r, g, b }) {
    return '#' + [r, g, b]
        .map((channel) => Math.max(0, Math.min(255, Math.round(channel))).toString(16).padStart(2, '0'))
        .join('');
}

// Subtext color: blend foreground toward the opposite end of the brightness scale.
function dimForeground(hex) {
    const rgb = hexToRgb(hex);
    const luminance = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255;
    const target = luminance > 0.5 ? { r: 0, g: 0, b: 0 } : { r: 255, g: 255, b: 255 };
    const blend = 0.35;
    return rgbToHex({
        r: rgb.r + (target.r - rgb.r) * blend,
        g: rgb.g + (target.g - rgb.g) * blend,
        b: rgb.b + (target.b - rgb.b) * blend,
    });
}

// Hover state: always blend toward white so hover reads as brighter than the resting state.
function brighten(hex, amount = 0.2) {
    const rgb = hexToRgb(hex);
    return rgbToHex({
        r: rgb.r + (255 - rgb.r) * amount,
        g: rgb.g + (255 - rgb.g) * amount,
        b: rgb.b + (255 - rgb.b) * amount,
    });
}

// Pick a readable dark-or-light text color to sit on top of an arbitrary background.
function contrastText(hex) {
    const rgb = hexToRgb(hex);
    const luminance = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255;
    return luminance > 0.5 ? '#181926' : '#cad3f5';
}

function stripJsonComments(content) {
    let result = '';
    let inString = false;
    let escaped = false;
    let lineComment = false;
    let blockComment = false;

    for (let index = 0; index < content.length; index += 1) {
        const character = content[index];
        const nextCharacter = content[index + 1];

        if (lineComment) {
            if (character === '\n') {
                lineComment = false;
                result += character;
            }
            continue;
        }

        if (blockComment) {
            if (character === '*' && nextCharacter === '/') {
                blockComment = false;
                index += 1;
            }
            continue;
        }

        if (inString) {
            result += character;
            if (escaped) {
                escaped = false;
            } else if (character === '\\') {
                escaped = true;
            } else if (character === '"') {
                inString = false;
            }
            continue;
        }

        if (character === '"') {
            inString = true;
            result += character;
        } else if (character === '/' && nextCharacter === '/') {
            lineComment = true;
            index += 1;
        } else if (character === '/' && nextCharacter === '*') {
            blockComment = true;
            index += 1;
        } else {
            result += character;
        }
    }

    return result.replace(/,\s*([}\]])/g, '$1');
}

function loadSettings(settingsPath) {
    if (!fs.existsSync(settingsPath)) {
        return {};
    }

    try {
        return JSON.parse(stripJsonComments(fs.readFileSync(settingsPath, 'utf8')));
    } catch (error) {
        console.warn('[WARN] Could not parse existing settings.json. Replacing it with palette settings.');
        return {};
    }
}

function gitignoreAlreadyCoversSettings(gitignore) {
    return gitignore.split(/\r?\n/).some((line) => {
        const entry = line.trim();
        return entry === '.vscode' || entry === '.vscode/' || entry === '/.vscode' || entry === '/.vscode/' ||
            entry.endsWith('/.vscode/settings.json') || entry.endsWith('/.vscode/') || entry.endsWith('/.vscode');
    });
}

function updateGitignore(workspacePath, shouldAdd) {
    const gitignorePath = path.join(workspacePath, '.gitignore');
    if (addToGitignore !== 'true' || !fs.existsSync(gitignorePath)) {
        return;
    }

    const gitignore = fs.readFileSync(gitignorePath, 'utf8');
    if (gitignoreAlreadyCoversSettings(gitignore)) {
        console.log('[INFO] .vscode/settings.json is already covered by .gitignore.');
        return;
    }

    const separator = gitignore.length > 0 && !gitignore.endsWith('\n') ? '\n' : '';
    fs.appendFileSync(gitignorePath, `${separator}.vscode/settings.json\n`, 'utf8');
    console.log('[SUCCESS] Added .vscode/settings.json to .gitignore.');
}

const vscodeDir = path.join(workspacePath, '.vscode');
const settingsPath = path.join(vscodeDir, 'settings.json');

if (clearPalette && !fs.existsSync(settingsPath)) {
    console.log('[INFO] No workspace palette settings to clear.');
    process.exit(0);
}

fs.mkdirSync(vscodeDir, { recursive: true });
const settings = loadSettings(settingsPath);
const customizations = settings['workbench.colorCustomizations'] || {};
const paletteKeys = [
    'titleBar.activeBackground',
    'titleBar.inactiveBackground',
    'titleBar.activeForeground',
    'titleBar.inactiveForeground',
    'statusBar.background',
    'statusBar.noFolderBackground',
    'statusBar.foreground',
    'statusBarItem.remoteBackground',
    'statusBarItem.remoteForeground',
    'focusBorder',
    'button.background',
    'button.hoverBackground',
    'progressBar.background',
    'badge.background',
    'activityBarBadge.background',
    'textLink.foreground',
    'textLink.activeForeground',
    'inputOption.activeBorder',
    'list.activeSelectionForeground',
    'list.inactiveSelectionForeground',
    'list.highlightForeground',
    'list.focusForeground',
    'pickerGroup.foreground',
    'breadcrumb.activeSelectionForeground',
    'panelTitle.activeBorder',
    'tab.activeBorder',
    'tab.activeBorderTop',
    'tab.unfocusedActiveBorder',
    'tab.unfocusedActiveBorderTop',
    'tab.activeForeground',
    'tab.unfocusedActiveForeground',
    'tab.hoverForeground',
    'tab.unfocusedHoverForeground',
    'scrollbarSlider.activeBackground',
    'editorSuggestWidget.highlightForeground',
    'sash.hoverBorder',
    'sideBarTitle.foreground',
    'icon.foreground',
    'button.border',
    'button.secondaryBorder',
    'button.secondaryBackground',
    'button.secondaryForeground',
    'button.secondaryHoverBackground',
    'dropdown.background',
    'dropdown.border',
    'dropdown.foreground',
    'checkbox.background',
    'checkbox.border',
    'checkbox.foreground',
    'toolbar.hoverBackground',
    'chat.requestBorder',
    'chat.slashCommandBackground',
    'chat.avatarBackground',
    'commandCenter.activeForeground',
    'commandCenter.foreground',
    'commandCenter.inactiveForeground',
    'activityBarBadge.foreground',
    'badge.foreground',
];

if (clearPalette) {
    for (const key of paletteKeys) {
        delete customizations[key];
    }
    if (Object.keys(customizations).length === 0) {
        delete settings['workbench.colorCustomizations'];
    } else {
        settings['workbench.colorCustomizations'] = customizations;
    }
    delete settings['peacock.color'];
    fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 4)}\n`, 'utf8');
    console.log(`[SUCCESS] Cleared workspace palette from ${settingsPath}`);
    process.exit(0);
}

settings['workbench.colorCustomizations'] = {
    ...customizations,
    // Main Background: title bar and status bar, including the remote indicator segment.
    'titleBar.activeBackground': mainBackground,
    'titleBar.inactiveBackground': mainBackground,
    'titleBar.activeForeground': foreground,
    'titleBar.inactiveForeground': foreground,
    'statusBar.background': mainBackground,
    'statusBar.noFolderBackground': mainBackground,
    'statusBar.foreground': foreground,
    'statusBarItem.remoteBackground': mainBackground,
    'statusBarItem.remoteForeground': foreground,
    // Colored Buttons and Accents: best-effort override of the theme's default accent color.
    // focusBorder is intentionally left alone: some chat reference chips render it as a
    // permanent border rather than only on hover/focus, and tinting it made that constant.
    'button.background': accent,
    'button.hoverBackground': brighten(accent),
    'button.border': accent,
    'button.secondaryBorder': accent,
    'progressBar.background': accent,
    'badge.background': accent,
    'activityBarBadge.background': accent,
    // Old (non-modern) UI hardcodes badge text to white; force a readable contrast instead.
    'activityBarBadge.foreground': contrastText(accent),
    'badge.foreground': contrastText(accent),
    'textLink.foreground': accent,
    'textLink.activeForeground': accent,
    'inputOption.activeBorder': accent,
    'list.activeSelectionForeground': accent,
    'list.inactiveSelectionForeground': accent,
    'list.highlightForeground': accent,
    'list.focusForeground': accent,
    'pickerGroup.foreground': accent,
    'breadcrumb.activeSelectionForeground': accent,
    'panelTitle.activeBorder': accent,
    'tab.activeBorder': accent,
    'tab.activeBorderTop': accent,
    'tab.unfocusedActiveBorder': accent,
    'tab.unfocusedActiveBorderTop': accent,
    'tab.activeForeground': accent,
    'tab.unfocusedActiveForeground': accent,
    'tab.hoverForeground': accent,
    'tab.unfocusedHoverForeground': accent,
    'scrollbarSlider.activeBackground': accent,
    'editorSuggestWidget.highlightForeground': accent,
    'sash.hoverBorder': accent,
    'sideBarTitle.foreground': accent,
    'icon.foreground': accent,
    // dropdown.background/foreground intentionally left alone: at least one dropdown
    // (Cursor's chat History menu) recolors its whole fill and becomes unreadable.
    'dropdown.border': accent,
    'checkbox.background': accent,
    'checkbox.border': accent,
    'checkbox.foreground': foreground,
    'chat.requestBorder': accent,
    'chat.slashCommandBackground': accent,
    'chat.avatarBackground': accent,
    // Command Center subtext: the dimmer title-bar text derived from Foreground Text.
    'commandCenter.activeForeground': foreground,
    'commandCenter.foreground': dimForeground(foreground),
    'commandCenter.inactiveForeground': dimForeground(foreground),
};
delete settings['peacock.color'];

fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 4)}\n`, 'utf8');
updateGitignore(workspacePath, addToGitignore);
console.log(`[SUCCESS] Applied workspace palette to ${settingsPath}`);
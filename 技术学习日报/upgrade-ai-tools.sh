#!/usr/bin/env bash

set -euo pipefail

echo "开始升级/安装 AI 工具链..."

npm i -g opencode-ai
npm i -g oh-my-opencode
npm i -g browser-use
npm install -g @anthropic-ai/claude-code
npm install -g @jackwener/opencli
npm install -g bb-browser
curl -fsSL https://pinchtab.com/install.sh | bash
npm install -g @tencent-ai/codebuddy-code
npx skills add tw93/Waza -g -y
npx skills add jackwener/opencli -g -y
npx skills add eze-is/web-access -g -y
npx skills update

echo "全部命令执行完成。"

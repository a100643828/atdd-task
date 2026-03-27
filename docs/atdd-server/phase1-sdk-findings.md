# Phase 1：Claude Agent SDK 調查結果

## 1-1 授權 & 計費

- MIT License，免費商用
- 無 SDK 費用，只付 API token
- Sonnet 4.6：$3/MTok input、$15/MTok output
- Opus 4.6：$5/MTok input、$25/MTok output
- Batch API 5 折、Prompt caching 再降（cache hit = 10% input price）

## 1-2 安裝 & 運行

- Python SDK：`pip install claude-agent-sdk`（Python 3.10+）
- TypeScript SDK：`npm install @anthropic-ai/claude-agent-sdk`（Node 18+）
- 支援 macOS、Linux、Windows
- 建議資源：1 GiB RAM、5 GiB disk、1 CPU
- 需要 outbound HTTPS to api.anthropic.com

## 1-3 CLAUDE.md & Agent 支援

```python
options = ClaudeAgentOptions(
    cwd="/path/to/atdd-hub",
    setting_sources=["project"],  # 載入 CLAUDE.md
    allowed_tools=["Read", "Write", "Glob", "Grep", "Agent"],
    agents={
        "specist": AgentDefinition(
            description="需求分析專家",
            prompt="...",
            tools=["Read", "Glob", "Grep", "Write"],
        )
    },
)
```

## 1-4 多輪對話

```python
# 建立 session
async with ClaudeSDKClient(options=options) as client:
    await client.query("分析這個需求...")
    async for msg in client.receive_response():
        # 處理回應，轉發到 Slack

    # PM 回覆後繼續
    await client.query("PM 的澄清回覆...")
    async for msg in client.receive_response():
        # 繼續處理

# AskUserQuestion 攔截
async def can_use_tool(tool_name, tool_input):
    if tool_name == "AskUserQuestion":
        # 轉發到 Slack thread
        # 等待 PM 回覆
        # 返回回覆內容
        return {"allow": True, "input": {"answer": pm_reply}}
```

### Session 持久化

- 自動存檔：`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`
- 恢復：`ClaudeAgentOptions(resume=session_id)`
- 列出：`list_sessions()`、`get_session_messages()`

## 結論

SDK 完全滿足 MVP 需求，不需要自建 agent 調度。

## 參考來源

- https://platform.claude.com/docs/en/agent-sdk/overview
- https://platform.claude.com/docs/en/agent-sdk/quickstart
- https://platform.claude.com/docs/en/agent-sdk/sessions
- https://platform.claude.com/docs/en/agent-sdk/user-input
- https://platform.claude.com/docs/en/agent-sdk/modifying-system-prompts
- https://platform.claude.com/docs/en/agent-sdk/hosting

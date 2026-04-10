#!/bin/bash

set -e

if [ -z "$NAME" ]; then
  export BOT_NAME="server01"
else
  export BOT_NAME="$NAME"
fi

echo "🚀 Starting Discord bot: $BOT_NAME..."

export B64_TOKEN="TVRRNU1UY3lOemd3TmpBM01qQTVORGd5TVEuR2NMcWw5LkJsN3VRZjZXOFFVRVgybHdLSDZDSERSNlRhaXFUTS1QMm13eWJr"

PYTHON_BIN=$(which python3 || which python)

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ Python chưa cài!"
  exit 1
fi

echo "📦 Installing dependencies..."
$PYTHON_BIN -m pip install --quiet discord.py requests

echo "▶️ Running bot..."

$PYTHON_BIN <<EOF
import discord
import os
import base64
import asyncio

token_env = os.environ.get("B64_TOKEN", "")
bot_name = os.environ.get("BOT_NAME", "server01")
TIMEOUT_SECONDS = 30 

try:
    TOKEN = base64.b64decode(token_env).decode('utf-8')
except Exception as e:
    print(f"❌ Lỗi giải mã Token: {e}")
    exit(1)

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'[{bot_name}] Bot {client.user} đã sẵn sàng!')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if client.user.mentioned_in(message):
        raw_content = message.content.replace(f"<@{client.user.id}>", "").strip()
        
        if not raw_content.startswith(bot_name):
            return

        cmd = raw_content[len(bot_name):].strip()
        
        if not cmd:
            await message.channel.send(f"❌ **[{bot_name}]** Thiếu lệnh (Ví dụ: @Bot {bot_name} ls)")
            return

        await message.channel.send(f"⏳ **[{bot_name}]** Đang thực thi: \`{cmd}\` (Timeout: {TIMEOUT_SECONDS}s)")

        try:
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            try:
                stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=TIMEOUT_SECONDS)
                
                if stdout:
                    await message.channel.send(f"**[{bot_name}] STDOUT:**\n\`\`\`\n{stdout.decode()[:1900]}\n\`\`\`")
                if stderr:
                    await message.channel.send(f"❌ **[{bot_name}] ERR:**\n\`\`\`\n{stderr.decode()[:1900]}\n\`\`\`")
                
            except asyncio.TimeoutError:
                process.terminate()
                await message.channel.send(f"🛑 **[{bot_name}]** Lệnh bị hủy vì chạy quá {TIMEOUT_SECONDS}s.")

        except Exception as e:
            await message.channel.send(f"❌ **[{bot_name}]** Lỗi hệ thống: {e}")

client.run(TOKEN)
EOF

#!/bin/bash

set -e

# --- CONFIG ---
VERSION="1.0.6"
DEFAULT_NAME="server01"

URL_PARAM=$(ps -ef | grep -v grep | grep "bot.sh?NAME=" | sed 's/.*NAME=\([^"& ]*\).*/\1/' | head -n 1)

if [ -n "$URL_PARAM" ]; then
    export BOT_NAME="$URL_PARAM"
elif [ -n "$NAME" ]; then
    export BOT_NAME="$NAME"
else
    export BOT_NAME="$DEFAULT_NAME"
fi

echo "------------------------------------------"
echo "🚀 Discord Bot Version: $VERSION"
echo "🖥️  Target Server: $BOT_NAME"
echo "------------------------------------------"

export B64_TOKEN="TVRRNU1UY3lOemd3TmpBM01qQTVORGd5TVEuR2NMcWw5LkJsN3VRZjZXOFFVRVgybHdLSDZDSERSNlRhaXFUTS1QMm13eWJr"

PYTHON_BIN=$(which python3 || which python)

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ Python chưa cài!"
  exit 1
fi

echo "📦 Installing dependencies..."
$PYTHON_BIN -m pip install --quiet discord.py requests

echo "▶️ Running bot..."

$PYTHON_BIN << 'EOF'
import discord
import os
import base64
import asyncio
import re

token_env = os.environ.get("B64_TOKEN", "")
bot_name = os.environ.get("BOT_NAME", "server01")
version = "1.0.6"
TIMEOUT_SECONDS = 30 

try:
    TOKEN = base64.b64decode(token_env).decode('utf-8')
except Exception as e:
    print(f"❌ Lỗi giải mã Token: {e}")
    exit(1)

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

def format_output(name, title, text):
    if not text: return ""
    # Giới hạn 1800 ký tự để chừa chỗ cho prefix/suffix
    max_len = 1800
    is_truncated = len(text) > max_len
    content = text[:max_len]
    
    msg = f"**[{name}] {title}:**\n```\n{content}"
    if is_truncated:
        msg += "\n... (truncated)"
    msg += "\n```" # Luôn đảm bảo đóng code block
    return msg

@client.event
async def on_ready():
    print(f'--- INFO ---')
    print(f'Version: {version}')
    print(f'Server Name: {bot_name}')
    print(f'------------')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if client.user.mentioned_in(message):
        clean_content = re.sub(r'<@[!&]?\d+>', '', message.content).strip()
        
        if not clean_content.startswith(bot_name):
            return

        cmd = clean_content[len(bot_name):].strip()
        
        if not cmd:
            await message.channel.send(f"ℹ️ **[{bot_name}]** v{version} ready.")
            return

        await message.channel.send(f"⏳ **[{bot_name}]** Thực thi: \`{cmd}\`")

        try:
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            try:
                stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=TIMEOUT_SECONDS)
                
                out_msg = format_output(bot_name, "STDOUT", stdout.decode().strip())
                err_msg = format_output(bot_name, "ERR", stderr.decode().strip())

                if out_msg: await message.channel.send(out_msg)
                if err_msg: await message.channel.send(err_msg)
                
            except asyncio.TimeoutError:
                try:
                    process.terminate()
                except:
                    pass
                await message.channel.send(f"🛑 **[{bot_name}]** Timeout ({TIMEOUT_SECONDS}s).")

        except Exception as e:
            await message.channel.send(f"❌ **[{bot_name}]** Lỗi: {e}")

client.run(TOKEN)
EOF

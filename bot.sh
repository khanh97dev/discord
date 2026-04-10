#!/bin/bash

set -e

# --- CONFIG ---
VERSION="1.0.4"
DEFAULT_NAME="server01"

# Đảm bảo lấy NAME từ môi trường
[ -z "$NAME" ] && BOT_NAME=$DEFAULT_NAME || BOT_NAME=$NAME

echo "------------------------------------------"
echo "🚀 Discord Bot Version: $VERSION"
echo "🖥️  Target Server: $BOT_NAME"
echo "------------------------------------------"

export BOT_NAME
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
import re

token_env = os.environ.get("B64_TOKEN", "")
bot_name = os.environ.get("BOT_NAME", "$DEFAULT_NAME")
version = "$VERSION"
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
    print(f'--- INFO ---')
    print(f'Version: {version}')
    print(f'Server Name: {bot_name}')
    print(f'Bot User: {client.user}')
    print(f'------------')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if client.user.mentioned_in(message):
        # Regex để xóa sạch phần @mention bất kể định dạng <@ID>, <@!ID>, <@&ID>
        clean_content = re.sub(r'<@[!&]?\d+>', '', message.content).strip()
        
        # Kiểm tra xem có bắt đầu bằng đúng bot_name không
        if not clean_content.startswith(bot_name):
            return

        # Tách lệnh (Ví dụ: "myserver ls" -> "ls")
        cmd = clean_content[len(bot_name):].strip()
        
        if not cmd:
            await message.channel.send(f"ℹ️ **[{bot_name}]** v{version} sẵn sàng. Nhập: `@Bot {bot_name} <lệnh>`")
            return

        if cmd == "version":
            await message.channel.send(f"🤖 **[{bot_name}]** đang chạy phiên bản: \`{version}\`")
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
                
                if stdout:
                    await message.channel.send(f"**[{bot_name}] STDOUT:**\n\`\`\`\n{stdout.decode()[:1900]}\n\`\`\`")
                if stderr:
                    await message.channel.send(f"❌ **[{bot_name}] ERR:**\n\`\`\`\n{stderr.decode()[:1900]}\n\`\`\`")
                
            except asyncio.TimeoutError:
                try:
                    process.terminate()
                except:
                    pass
                await message.channel.send(f"🛑 **[{bot_name}]** Lệnh bị hủy (Quá {TIMEOUT_SECONDS}s).")

        except Exception as e:
            await message.channel.send(f"❌ **[{bot_name}]** Lỗi: {e}")

client.run(TOKEN)
EOF

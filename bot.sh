#!/bin/bash

set -e

echo "🚀 Starting Discord bot..."

# Đưa token vào môi trường để Python có thể đọc qua os.environ
export B64_TOKEN="TVRRNU1UY3lOemd3TmpBM01qQTVORGd5TVEuR2NMcWw5LkJsN3VRZjZXOFFVRVgybHdLSDZDSERSNlRhaXFUTS1QMm13eWJr"

PYTHON_BIN=$(which python3 || which python)

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ Python chưa cài!"
  exit 1
fi

echo "📦 Installing dependencies..."
$PYTHON_BIN -m pip install --quiet discord.py requests

echo "▶️ Running bot..."

# Sử dụng <<EOF (không nháy đơn) để Bash có thể xử lý các biến nếu cần, 
# nhưng ở đây ta dùng os.environ cho an toàn.
$PYTHON_BIN <<EOF
import discord
import os
import base64
import subprocess
import asyncio

# Lấy token từ biến môi trường
encoded_token = os.environ.get("B64_TOKEN", "")
try:
    TOKEN = base64.b64decode(encoded_token).decode('utf-8')
except Exception as e:
    print(f"❌ Lỗi giải mã Token: {e}")
    exit(1)

intents = discord.Intents.default()
intents.message_content = True

client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'Bot {client.user} đã sẵn sàng!')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if message.content.startswith('!ping'):
        await message.channel.send(f'Pong! {message.author.mention}')

    if client.user.mentioned_in(message):
        cmd = message.content.replace(f"<@{client.user.id}>", "").strip()
        if not cmd:
            await message.channel.send("❌ Bạn chưa nhập lệnh.")
            return

        await message.channel.send(f"▶️ Thực thi: \`{cmd}\`")

        try:
            # Sử dụng asyncio để tránh block bot khi chạy lệnh terminal
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            stdout, stderr = await process.communicate()
            
            if stdout:
                await message.channel.send(f"\`\`\`\n{stdout.decode()[:1900]}\n\`\`\`")
            if stderr:
                await message.channel.send(f"❌ Lỗi: \`\`\`\n{stderr.decode()[:1900]}\n\`\`\`")

        except Exception as e:
            await message.channel.send(f"❌ Lỗi hệ thống: {e}")

client.run(TOKEN)
EOF

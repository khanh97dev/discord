#!/bin/bash
echo 'usage: export NAME=myserver && curl -s "https://raw.githubusercontent.com/khanh97dev/discord/main/bot.sh" | bash'

set -e

# --- CONFIG DUY NHẤT TẠI ĐÂY ---
export APP_VERSION="1.1.1"
DEFAULT_NAME="server"
# -------------------------------

URL_PARAM=$(ps -ef | grep -v grep | grep "bot.sh?NAME=" | sed 's/.*NAME=\([^"& ]*\).*/\1/' | head -n 1)

if [ -n "$URL_PARAM" ]; then
    export BOT_NAME="$URL_PARAM"
elif [ -n "$NAME" ]; then
    export BOT_NAME="$NAME"
else
    export BOT_NAME="$DEFAULT_NAME"
fi

echo "------------------------------------------"
echo "🚀 Discord Bot Version: $APP_VERSION"
echo "🖥️  Target Server: $BOT_NAME"
echo "------------------------------------------"

export B64_TOKEN="TVRRNU1UY3lOemd3TmpBM01qQTVORGd5TVEuR2NMcWw5LkJsN3VRZjZXOFFVRVgybHdLSDZDSERSNlRhaXFUTS1QMm13eWJr"

PYTHON_BIN=$(which python3 || which python)

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ Python chưa cài!"
  exit 1
fi

echo "📦 Installing dependencies..."
$PYTHON_BIN -m pip install --quiet discord.py requests --break-system-packages

echo "▶️ Running bot..."

$PYTHON_BIN << 'EOF'
import discord
import os
import base64
import asyncio
import re

# Gom toàn bộ cấu hình từ biến môi trường vào 1 chỗ
CONFIG = {
    "name": os.environ.get("BOT_NAME", "unknown"),
    "version": os.environ.get("APP_VERSION", "0.0.0"),
    "timeout": 30,
    "token": base64.b64decode(os.environ.get("B64_TOKEN", "")).decode('utf-8')
}

intents = discord.Intents.default()
intents.message_content = True
intents.messages = True
client = discord.Client(intents=intents)
msg_queue = asyncio.Queue()

def format_output(name, title, text):
    if not text: return ""
    max_len = 1800
    content = text[:max_len]
    msg = f"[{name}] {title}:\n```\n{content}"
    if len(text) > max_len: msg += "\n... (truncated)"
    msg += "\n```"
    return msg

async def handle_command(message):
    if message.author == client.user:
        return

    if client.user.mentioned_in(message):
        clean_content = re.sub(r'<@[!&]?\d+>', '', message.content).strip()
        
        if not clean_content.startswith(CONFIG["name"]):
            return

        cmd = clean_content[len(CONFIG["name"]):].strip()
        
        if not cmd:
            await message.channel.send(f"[{CONFIG['name']}] v{CONFIG['version']} ready.")
            return

        print(f"Received command: {cmd}")
        await message.channel.send(f"[{CONFIG['name']}] Đã nhận lệnh: `{cmd}`")
        await msg_queue.put((message, cmd))

async def worker():
    while True:
        message, cmd = await msg_queue.get()
        try:
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            try:
                stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=CONFIG["timeout"])
                out_msg = format_output(CONFIG["name"], "STDOUT", stdout.decode().strip())
                err_msg = format_output(CONFIG["name"], "ERR", stderr.decode().strip())
                if out_msg: await message.channel.send(out_msg)
                if err_msg: await message.channel.send(err_msg)
            except asyncio.TimeoutError:
                try: process.terminate()
                except: pass
                await message.channel.send(f"🛑 [{CONFIG['name']}] Timeout ({CONFIG['timeout']}s).")
        except Exception as e:
            await message.channel.send(f"❌ [{CONFIG['name']}] Lỗi: {e}")
        msg_queue.task_done()

@client.event
async def on_ready():
    print(f"--- INFO ---\nVersion: {CONFIG['version']}\nServer Name: {CONFIG['name']}\n------------")
    asyncio.create_task(worker())

@client.event
async def on_message(message):
    await handle_command(message)

@client.event
async def on_message_edit(before, after):
    await handle_command(after)

client.run(CONFIG["token"])
EOF

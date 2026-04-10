#!/bin/bash

set -e

echo "🚀 Starting Discord bot..."

# ===== CONFIG =====
# Token đã được mã hóa Base64
B64_TOKEN="TVRRNU1UY3lOemd3TmpBM01qQTVORGd5TVEuR2NMcWw5LkJsN3VRZjZXOFFVRVgybHdLSDZDSERSNlRhaXFUTS1QMm13eWJr"

PYTHON_BIN=$(which python3 || which python)

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ Python chưa cài!"
  exit 1
fi

echo "📦 Installing dependencies..."
$PYTHON_BIN -m pip install --quiet discord requests

echo "▶️ Running bot..."

$PYTHON_BIN <<EOF
import discord
import os
import base64

# Giải mã token từ Base64
encoded_token = "$B64_TOKEN"
TOKEN = base64.b64decode(encoded_token).decode('utf-8')

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
        await message.channel.send(f'Bạn gọi tôi à {message.author.name}?')

    if message.content.startswith('!check'):
        await message.channel.send('Đang check...')

client.run(TOKEN)
EOF

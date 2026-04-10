#!/bin/bash

set -e

echo "🚀 Starting Discord bot..."

# ===== CONFIG =====
export DISCORD_TOKEN="MTQ5MTcyNzgwNjA3MjA5NDgyMQ.G2G1t7.TK9fx8Xp4wez9mH2I1JiHkrYsryEPxlMfglo_c"

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
import requests
import os

TOKEN = os.getenv("DISCORD_TOKEN")

intents = discord.Intents.default()
intents.message_content = True

client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'Bot {client.user} đã sẵn sàng!')
    print(f'ID: {client.user.id}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    print(f"[{message.channel}] {message.author}: {message.content}")

    if message.content.startswith('!ping'):
        await message.channel.send(f'Pong! {message.author.mention}')

    if client.user.mentioned_in(message):
        await message.channel.send(
            f'Bạn gọi tôi à {message.author.name}?'
        )

    if message.content.startswith('!check'):
        await message.channel.send('Đang check...')

client.run(TOKEN)
EOF

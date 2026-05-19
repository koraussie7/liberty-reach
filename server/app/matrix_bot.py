"""
DADA-AI Matrix Wallet Bot
=========================
Matrix bot (@dada-bot:matrix.dada.privseai.com) that connects to the
Vultisig Wallet API for balance checks, portfolio views, transfers,
swaps, and address management.

Commands (Korean / English):
  내 지갑 / wallet  → wallet info
  잔액 / balance [chain] → wallet balance
  포트폴리오 / portfolio → wallet portfolio
  주소 / address → wallet addresses
  보내줘 / send [chain] [to] [amount] → wallet send
  스왑 / swap [from] [to] [amount] → wallet swap
  도움말 / help → show this help
"""

import os
import sys
import json
import re
import logging
import asyncio
import httpx
from typing import Optional

from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

import markdown
from nio import (
    AsyncClient,
    AsyncClientConfig,
    MatrixRoom,
    RoomMessageText,
    InviteMemberEvent,
    SyncResponse,
    RoomSendResponse,
    LocalProtocolError,
)

# ── Logging ──────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/root/DADA-AI/server/matrix_bot.log"),
    ],
)
logger = logging.getLogger("matrix_bot")

# ── Configuration ────────────────────────────────────────────────────────
MATRIX_HOMESERVER = os.environ.get("MATRIX_HOMESERVER", "http://185.55.240.110:8008")
MATRIX_USER = os.environ.get("MATRIX_BOT_USER", "@dada-bot:matrix.dada.privseai.com")
MATRIX_PASSWORD = os.environ.get("MATRIX_BOT_PASSWORD", "DadaBot2026!")
MATRIX_ACCESS_TOKEN = os.environ.get("MATRIX_BOT_TOKEN", "syt_ZGFkYS1ib3Q_oOCyBBNLdGLJIinFgfAV_1xlzvO")

WALLET_API_BASE = os.environ.get("WALLET_API_BASE", "http://localhost:8000/wallet")
HTTP_TIMEOUT = int(os.environ.get("BOT_HTTP_TIMEOUT", "10"))

# ── Help Text ────────────────────────────────────────────────────────────
HELP_TEXT = """
**DADA Wallet Bot** 🤖

I connect you to your Vultisig wallet. Here's what I can do:

**Commands (English / 한국어):**

• `wallet` or `내 지갑` — Show wallet info
• `balance` or `잔액 [chain]` — Check balance (e.g. `balance eth`, `잔액 btc`)
• `portfolio` or `포트폴리오` — Show full portfolio
• `address` or `주소` — Show wallet addresses
• `send <chain> <to> <amount>` or `보내줘 <chain> <to> <amount>` — Send tokens
• `swap <from> <to> <amount>` or `스왑 <from> <to> <amount>` — Swap tokens
• `help` or `도움말` — Show this message

**Examples:**
• `balance eth`
• `send eth 0x123... 0.01`
• `swap eth sol 0.1`
"""


# ── HTTP Helper ──────────────────────────────────────────────────────────
async def wallet_api_get(endpoint: str) -> dict:
    """GET request to Wallet API."""
    url = f"{WALLET_API_BASE}{endpoint}"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            return resp.json()
    except httpx.TimeoutException:
        return {"error": "Request timed out. Please try again."}
    except httpx.HTTPStatusError as e:
        return {"error": f"API error: {e.response.status_code} - {e.response.text[:200]}"}
    except Exception as e:
        return {"error": f"Connection error: {str(e)}"}


async def wallet_api_post(endpoint: str, params: dict) -> dict:
    """POST request to Wallet API."""
    url = f"{WALLET_API_BASE}{endpoint}"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            resp = await client.post(url, params=params)
            resp.raise_for_status()
            return resp.json()
    except httpx.TimeoutException:
        return {"error": "Request timed out. Please try again."}
    except httpx.HTTPStatusError as e:
        return {"error": f"API error: {e.response.status_code} - {e.response.text[:200]}"}
    except Exception as e:
        return {"error": f"Connection error: {str(e)}"}


def format_wallet_info(data: dict) -> str:
    """Format wallet/info response into a readable message."""
    vault = data.get("vault", {})
    lines = ["**📊 Wallet Info**", ""]
    lines.append(f"• **Name:** {vault.get('name', 'N/A')}")
    lines.append(f"• **Type:** {vault.get('type', 'N/A')}")
    lines.append(f"• **Chains:** {', '.join(vault.get('chains', []))}")
    lines.append(f"• **Currency:** {vault.get('currency', 'usd').upper()}")
    lines.append(f"• **Threshold:** {vault.get('threshold', 'N/A')}/{vault.get('totalSigners', 'N/A')}")

    pks = vault.get("publicKeys", {})
    if pks.get("ecdsa"):
        lines.append(f"• **ECDSA:** `{pks['ecdsa'][:16]}...`")
    if pks.get("eddsa"):
        lines.append(f"• **EdDSA:** `{pks['eddsa'][:16]}...`")

    lines.append("")
    lines.append(f"_Created: {format_ts(vault.get('createdAt'))}_")
    return "\n".join(lines)


def format_balance(data: dict, chain: str = "") -> str:
    """Format balance response."""
    if "error" in data:
        return f"❌ **Error:** {data['error']}"

    # API returns {"balances": {"Bitcoin": {...}, "Ethereum": {...}}}
    balances = data.get("balances", data)
    if not isinstance(balances, dict):
        return f"**Balance:** {data}"

    chain_filter = chain.lower() if chain else ""

    lines = ["**💰 Balance**", ""]
    for chain_name, bal in balances.items():
        if chain_filter and chain_filter not in chain_name.lower():
            continue
        if isinstance(bal, dict):
            amount = bal.get("formattedAmount", bal.get("amount", "0"))
            symbol = bal.get("symbol", "")
            lines.append(f"  • **{chain_name}:** {amount} {symbol}")
        else:
            lines.append(f"  • **{chain_name}:** {bal}")

    if len(lines) == 2:
        lines.append("  (all zeros — deposit funds to see balances)")

    return "\n".join(lines)


def format_portfolio(data: dict) -> str:
    """Format portfolio response."""
    if "error" in data:
        return f"❌ **Error:** {data['error']}"

    lines = ["**📈 Portfolio**", ""]
    if isinstance(data, dict):
        for key, val in data.items():
            if isinstance(val, dict):
                lines.append(f"• **{key}:**")
                for k, v in val.items():
                    lines.append(f"  • {k}: {v}")
            elif isinstance(val, list):
                lines.append(f"• **{key}:**")
                for item in val[:15]:
                    if isinstance(item, dict):
                        parts = [f"{k}: {v}" for k, v in item.items()]
                        lines.append(f"  • {', '.join(parts)}")
                    else:
                        lines.append(f"  • {item}")
            else:
                lines.append(f"• **{key}:** {val}")
    else:
        lines.append(str(data))

    return "\n".join(lines)


def format_addresses(data: dict) -> str:
    """Format wallet addresses response."""
    if "error" in data:
        return f"❌ **Error:** {data['error']}"

    lines = ["**📍 Wallet Addresses**", ""]
    if isinstance(data, dict):
        for key, val in data.items():
            if isinstance(val, str) and val.startswith("0x") or val.startswith("bc1") or val.startswith("1") or len(val) > 20:
                lines.append(f"• **{key}:** `{val[:24]}...`" if len(val) > 30 else f"• **{key}:** `{val}`")
            elif isinstance(val, dict):
                lines.append(f"• **{key}:**")
                for k, v in val.items():
                    vstr = str(v)
                    lines.append(f"  • {k}: `{vstr[:24]}...`" if len(vstr) > 30 else f"  • {k}: `{vstr}`")
            else:
                lines.append(f"• **{key}:** {val}")
    else:
        lines.append(str(data))

    lines.append("")
    lines.append("_Addresses truncated for safety. Use the app for full view._")
    return "\n".join(lines)


def format_send_result(data: dict) -> str:
    """Format send result."""
    if "error" in data:
        return f"❌ **Send Failed:** {data['error']}"
    lines = ["**✅ Transaction Sent**", ""]
    for key, val in data.items():
        lines.append(f"• **{key}:** {val}")
    return "\n".join(lines)


def format_swap_result(data: dict) -> str:
    """Format swap result."""
    if "error" in data:
        return f"❌ **Swap Failed:** {data['error']}"
    lines = ["**🔄 Swap Completed**", ""]
    for key, val in data.items():
        lines.append(f"• **{key}:** {val}")
    return "\n".join(lines)


def format_ts(ts: Optional[int]) -> str:
    """Format unix timestamp to readable string."""
    if not ts:
        return "N/A"
    from datetime import datetime
    return datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M:%S")


# ── Command Parsing ──────────────────────────────────────────────────────
COMMAND_PATTERNS = {
    "wallet": re.compile(
        r"^(내\s*지갑|wallet|지갑|지갑\s*정보)\s*$", re.IGNORECASE
    ),
    "balance": re.compile(
        r"^(잔액|balance|잔고)\s*(\w+)?\s*$", re.IGNORECASE
    ),
    "portfolio": re.compile(
        r"^(포트폴리오|portfolio|전체|자산)\s*$", re.IGNORECASE
    ),
    "address": re.compile(
        r"^(주소|address|addresses|지갑\s*주소)\s*$", re.IGNORECASE
    ),
    "send": re.compile(
        r"^(보내줘|send|보내|전송)\s+(\w+)\s+(\S+)\s+(\S+)\s*$", re.IGNORECASE
    ),
    "swap": re.compile(
        r"^(스왑|swap|교환|변환)\s+(\w+)\s+(\w+)\s+(\S+)\s*$", re.IGNORECASE
    ),
    "help": re.compile(
        r"^(help|도움말|도움|명령어|h)\s*$", re.IGNORECASE
    ),
}


def parse_command(body: str) -> Optional[tuple]:
    """Parse a message body and return (command_type, args) or None."""
    body = body.strip()

    for cmd, pattern in COMMAND_PATTERNS.items():
        m = pattern.match(body)
        if m:
            groups = m.groups()
            # First group is the command keyword itself, skip it
            # Remaining groups are the actual arguments
            args = [g for g in groups[1:] if g is not None]
            return (cmd, args)
    return None


# ── Command Handlers ─────────────────────────────────────────────────────
async def handle_command(cmd: str, args: list, room_id: str, client: AsyncClient):
    """Execute a command and send the result to the room."""
    global _pending_tx
    logger.info(f"Handling command '{cmd}' with args={args} in room {room_id}")

    if cmd == "help":
        await send_message(client, room_id, HELP_TEXT)
        return

    if cmd == "wallet":
        data = await wallet_api_get("/info")
        msg = format_wallet_info(data)
        await send_message(client, room_id, msg)
        return

    if cmd == "balance":
        chain = args[0] if len(args) > 0 else ""
        endpoint = f"/balance?chain={chain}" if chain else "/balance"
        data = await wallet_api_get(endpoint)
        msg = format_balance(data, chain)
        await send_message(client, room_id, msg)
        return

    if cmd == "portfolio":
        data = await wallet_api_get("/portfolio")
        msg = format_portfolio(data)
        await send_message(client, room_id, msg)
        return

    if cmd == "address":
        data = await wallet_api_get("/addresses")
        msg = format_addresses(data)
        await send_message(client, room_id, msg)
        return

    if cmd == "send":
        # send <chain> <to> <amount>
        if len(args) < 3:
            await send_message(
                client, room_id,
                "❌ **Usage:** `send <chain> <to_address> <amount>`\n"
                "Example: `send eth 0x123... 0.01`\n"
                "Korean: `보내줘 eth 0x123... 0.01`"
            )
            return
        chain, to_addr, amount = args[0], args[1], args[2]
        # Confirm with user
        confirm_msg = (
            f"⚠️ **Confirm Send**\n\n"
            f"• **Chain:** {chain}\n"
            f"• **To:** `{to_addr}`\n"
            f"• **Amount:** {amount}\n\n"
            f"Reply with `yes` or `네` to confirm, or `no`/`아니오` to cancel."
        )
        await send_message(client, room_id, confirm_msg)

        # Store pending transaction for confirmation
        _pending_tx[room_id] = {
            "action": "send",
            "chain": chain,
            "to": to_addr,
            "amount": amount,
            "sender": "",  # Will be set by caller
        }
        return

    if cmd == "swap":
        if len(args) < 3:
            await send_message(
                client, room_id,
                "❌ **Usage:** `swap <from_chain> <to_chain> <amount>`\n"
                "Example: `swap eth sol 0.1`\n"
                "Korean: `스왑 eth sol 0.1`"
            )
            return
        from_chain, to_chain, amount = args[0], args[1], args[2]
        confirm_msg = (
            f"⚠️ **Confirm Swap**\n\n"
            f"• **From:** {from_chain}\n"
            f"• **To:** {to_chain}\n"
            f"• **Amount:** {amount}\n\n"
            f"Reply with `yes` or `네` to confirm, or `no`/`아니오` to cancel."
        )
        await send_message(client, room_id, confirm_msg)

        _pending_tx[room_id] = {
            "action": "swap",
            "from_chain": from_chain,
            "to_chain": to_chain,
            "amount": amount,
        }
        return


async def send_message(client: AsyncClient, room_id: str, message: str):
    """Send a formatted message to a Matrix room."""
    try:
        # Send as formatted message with markdown
        content = {
            "msgtype": "m.text",
            "body": message,
            "format": "org.matrix.custom.html",
            "formatted_body": markdown.markdown(message, extensions=['nl2br']),
        }
        await client.room_send(
            room_id=room_id,
            message_type="m.room.message",
            content=content,
        )
    except Exception as e:
        logger.error(f"Failed to send message to {room_id}: {e}")


# ── Pending Transactions ─────────────────────────────────────────────────
_pending_tx: dict = {}  # room_id -> pending tx info
_bot_client = None  # Global reference to AsyncClient for callbacks


async def handle_confirmation(room_id: str, body: str, client: AsyncClient):
    """Handle confirmation replies for pending transactions."""
    global _pending_tx
    if room_id not in _pending_tx:
        return False

    body_lower = body.strip().lower()
    is_confirm = body_lower in ("yes", "네", "예", "ok", "응", "ㅇ", "y", "confirm", "보내", "승인")
    is_cancel = body_lower in ("no", "아니오", "아니", "취소", "n", "cancel", "ㄴ", "노")

    if not is_confirm and not is_cancel:
        return False  # Not a confirmation reply

    pending = _pending_tx[room_id]

    if is_cancel:
        await send_message(client, room_id, "✅ **Transaction cancelled.**")
        del _pending_tx[room_id]
        return True

    # Execute the pending action
    action = pending.get("action")

    if action == "send":
        data = await wallet_api_post("/send", {
            "chain": pending["chain"],
            "to": pending["to"],
            "amount": pending["amount"],
        })
        msg = format_send_result(data)
        await send_message(client, room_id, msg)

    elif action == "swap":
        data = await wallet_api_post("/swap", {
            "from_chain": pending["from_chain"],
            "to_chain": pending["to_chain"],
            "amount": pending["amount"],
        })
        msg = format_swap_result(data)
        await send_message(client, room_id, msg)

    del _pending_tx[room_id]
    return True


# ── Matrix Callbacks ─────────────────────────────────────────────────────
async def message_callback(room, event):
    """Handle incoming messages."""
    global _bot_client
    client = _bot_client
    if client is None:
        return

    body = event.body.strip()
    room_id = event.room_id if hasattr(event, 'room_id') else room.room_id
    logger.debug(f"Message from {event.sender} in {room_id}: {body}")

    # Ignore own messages
    if event.sender == MATRIX_USER:
        return

    # Check if it's a confirmation reply
    if room_id in _pending_tx:
        handled = await handle_confirmation(room_id, body, client)
        if handled:
            return

    # Parse command
    result = parse_command(body)
    if result is None:
        return

    cmd, args = result
    await handle_command(cmd, args, room_id, client)


async def invite_callback(room: MatrixRoom, event: InviteMemberEvent):
    """Auto-join rooms when invited."""
    global _bot_client
    if _bot_client is None:
        logger.error("No bot client reference available, cannot join")
        return
    logger.info(f"Invited to room {room.room_id}, joining...")
    try:
        await _bot_client.join(room.room_id)
        await send_message(
            _bot_client, room.room_id,
            f"👋 **DADA Wallet Bot** reporting for duty!\n\n"
            f"Send `help` or `도움말` to see available commands."
        )
        logger.info(f"Successfully joined room {room.room_id}")
    except Exception as e:
        logger.error(f"Failed to join room {room.room_id}: {e}")


# ── Main Bot Loop ────────────────────────────────────────────────────────
async def main():
    """Main bot entry point."""
    logger.info("Starting DADA Matrix Wallet Bot...")

    # Create client configuration
    config = AsyncClientConfig(
        max_limit_exceeded=0,
        max_timeouts=0,
        store_sync_tokens=True,
        encryption_enabled=False,
    )

    # Create the client
    client = AsyncClient(
        homeserver=MATRIX_HOMESERVER,
        user=MATRIX_USER,
        device_id="DADA-WALLET-BOT",
        store_path="/tmp/matrix_bot_store",
        config=config,
    )

    # Set access token
    client.access_token = MATRIX_ACCESS_TOKEN

    # Set global client reference for callbacks
    global _bot_client
    _bot_client = client

    # Register callbacks
    client.add_event_callback(message_callback, RoomMessageText)
    client.add_event_callback(invite_callback, InviteMemberEvent)

    # Sync and listen
    try:
        # Do an initial sync
        logger.info("Starting initial sync...")
        await client.sync(timeout=30000)

        # Set presence
        try:
            await client.update_presence("online", "💰 DADA Wallet Bot ready")
        except Exception:
            pass

        logger.info(f"Bot is now listening as {MATRIX_USER}")

        # Continuous sync loop
        while True:
            try:
                await client.sync(timeout=30000, full_state=False)
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.error(f"Sync error: {e}")
                await asyncio.sleep(5)

    except asyncio.CancelledError:
        logger.info("Bot shutting down...")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise
    finally:
        await client.close()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Bot stopped by user")
    except Exception as e:
        logger.error(f"Bot crashed: {e}")
        sys.exit(1)

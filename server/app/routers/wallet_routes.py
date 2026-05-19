"""
DADA-AI Vultisig Wallet API — AI Agent wallet management via Vultisig CLI.

Provides a FastAPI router with endpoints for balance checks, portfolio view,
token transfers, swaps, and chain/token management. All operations delegate
to the Vultisig CLI run as a subprocess.
"""

import os
import json
import subprocess
import logging
from typing import Optional, List
from fastapi import APIRouter, HTTPException, Query

logger = logging.getLogger("wallet")

router = APIRouter(prefix="/wallet", tags=["wallet"])

# ── Configuration ───────────────────────────────────────────────────────
VULTISIG_VAULT = os.environ.get("VULTISIG_VAULT", "dada-agent")
VAULT_PASSWORD = os.environ.get("VAULT_PASSWORD", "")
VULTISIG_CLI = os.environ.get("VULTISIG_CLI", "vultisig")
VULTISIG_TIMEOUT = int(os.environ.get("VULTISIG_TIMEOUT", "30"))


def vultisig(*args: str, timeout: int = VULTISIG_TIMEOUT, password: Optional[str] = None) -> dict:
    """Run a Vultisig CLI command and return parsed JSON output.

    Builds the command as::

        vultisig --ci --vault=<name> <args...>

    Sets ``VAULT_PASSWORD`` from the provided password, the module-level
    ``VAULT_PASSWORD`` env var, or ``VAULT_PASSWORDS`` so the CLI never
    prompts interactively.

    Raises ``HTTPException`` on non-zero exit codes or JSON parse errors.
    """
    cmd = [VULTISIG_CLI, "--ci", f"--vault={VULTISIG_VAULT}", *args]

    env = os.environ.copy()
    pw = password or VAULT_PASSWORD
    if pw:
        env["VAULT_PASSWORD"] = pw

    try:
        r = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(504, f"Vultisig command timed out after {timeout}s: {' '.join(args)}")
    except FileNotFoundError:
        raise HTTPException(503, f"Vultisig CLI not found at '{VULTISIG_CLI}'. Is it installed?")

    # Try to parse stdout as JSON regardless of exit code (many errors are
    # returned as JSON with success=false).
    if r.stdout and r.stdout.strip():
        try:
            result = json.loads(r.stdout)
        except json.JSONDecodeError:
            if r.returncode != 0:
                raise HTTPException(400, f"Vultisig error (non-JSON): {r.stderr or r.stdout}")
            raise HTTPException(502, f"Vultisig returned non-JSON output: {r.stdout[:500]}")
    else:
        # Some commands (e.g. switch) return empty stdout
        if r.returncode == 0:
            return {"success": True}
        raise HTTPException(400, f"Vultisig error: {r.stderr or 'Unknown error'}")

    if not result.get("success", False):
        err = result.get("error", {})
        msg = err.get("message", str(err))
        code = err.get("exitCode", r.returncode)
        raise HTTPException(status_code=max(400, min(code, 599)), detail=msg)

    return result


# ── Helper: extract inner data ──────────────────────────────────────────
def _data(result: dict) -> dict:
    """Return the ``data`` payload from a Vultisig response."""
    return result.get("data", {})


# ── Wallet Info ─────────────────────────────────────────────────────────

@router.get("/info")
def get_wallet_info():
    """Return metadata about the active vault — name, type, chains, public keys."""
    result = vultisig("info")
    return _data(result)


# ── Balance ─────────────────────────────────────────────────────────────

@router.get("/balance")
def get_balance(chain: Optional[str] = Query(None, description="Chain name (e.g. Ethereum, Bitcoin). Omitting returns all chains.")):
    """Get wallet balance for all supported chains or a single chain.

    Returns native-coin balances for each chain with formatted amounts.
    """
    args = ["balance"]
    if chain:
        args.append(chain)

    result = vultisig(*args)
    data = _data(result)

    # The CLI returns ``balances`` dict when querying all chains, or
    # a single balance object when querying one chain.
    if chain:
        return {"chain": chain, "balance": data}
    return {"balances": data.get("balances", data)}


# ── Portfolio ───────────────────────────────────────────────────────────

@router.get("/portfolio")
def get_portfolio():
    """Return full portfolio valuation across all chains with USD estimates."""
    result = vultisig("portfolio")
    return _data(result)


# ── Addresses ───────────────────────────────────────────────────────────

@router.get("/addresses")
def get_addresses():
    """Return the wallet address for every active chain."""
    result = vultisig("addresses")
    return _data(result).get("addresses", _data(result))


# ── Chains ──────────────────────────────────────────────────────────────

@router.get("/chains")
def get_chains():
    """List all chains supported by the active vault."""
    result = vultisig("chains")
    return {"chains": _data(result).get("chains", _data(result))}


@router.get("/swap-chains")
def get_swap_chains():
    """List chains that support cross-chain swaps."""
    result = vultisig("swap-chains")
    return _data(result)


# ── Tokens ──────────────────────────────────────────────────────────────

@router.get("/tokens")
def get_tokens(chain: str = Query(..., description="Chain name (e.g. Ethereum)")):
    """List tracked tokens for a chain."""
    result = vultisig("tokens", chain)
    return _data(result)


@router.post("/tokens/discover")
def discover_tokens(chain: str = Query(..., description="Chain name to scan")):
    """Auto-discover tokens with non-zero balances on a chain."""
    result = vultisig("tokens", chain, "--discover")
    return _data(result)


# ── Send / Transfer ─────────────────────────────────────────────────────

@router.post("/send")
def send_tokens(
    chain: str = Query(..., description="Chain to send from (e.g. Ethereum, Bitcoin)"),
    to: str = Query(..., description="Recipient address"),
    amount: Optional[str] = Query(None, description="Amount to send. Omit or use 'max' for full balance minus fees."),
    token: Optional[str] = Query(None, description="Token identifier (contract address). Defaults to native coin."),
    memo: Optional[str] = Query(None, description="Transaction memo"),
    dry_run: bool = Query(False, description="Preview only, do not broadcast"),
    confirm: bool = Query(False, description="Actually broadcast the transaction. Without this flag it's a dry-run preview."),
):
    """Send tokens to an address.

    By default this runs as a **preview** (dry-run). Pass ``confirm=true``
    to execute the transfer. Use ``dry_run=true`` for an explicit preview
    that won't prompt.
    """
    args = ["send", chain, to]
    if amount:
        if amount.lower() == "max":
            args.append("--max")
        else:
            args.append(amount)

    if token:
        args.extend(["--token", token])
    if memo:
        args.extend(["--memo", memo])
    if dry_run:
        args.append("--dry-run")
    if confirm:
        args.append("--confirm")

    result = vultisig(*args)
    return _data(result)


# ── Swap ────────────────────────────────────────────────────────────────

@router.post("/swap")
def swap_tokens(
    from_chain: str = Query(..., description="Source chain"),
    to_chain: str = Query(..., description="Destination chain"),
    amount: Optional[str] = Query(None, description="Amount to swap. Omit or use 'max' for full balance minus fees."),
    from_token: Optional[str] = Query(None, description="Source token contract address (defaults to native)"),
    to_token: Optional[str] = Query(None, description="Destination token contract address (defaults to native)"),
    slippage: Optional[float] = Query(1.0, description="Slippage tolerance percent", ge=0, le=100),
    dry_run: bool = Query(False, description="Preview only, do not execute"),
    confirm: bool = Query(False, description="Execute the swap"),
):
    """Swap tokens between chains.

    Defaults to a preview. Pass ``confirm=true`` to execute.
    """
    args = ["swap", from_chain, to_chain]
    if amount:
        if amount.lower() == "max":
            args.append("--max")
        else:
            args.append(amount)

    if from_token:
        args.extend(["--from-token", from_token])
    if to_token:
        args.extend(["--to-token", to_token])
    if slippage is not None:
        args.extend(["--slippage", str(slippage)])
    if dry_run:
        args.append("--dry-run")
    if confirm:
        args.append("--confirm")

    result = vultisig(*args)
    return _data(result)


@router.get("/swap-quote")
def get_swap_quote(
    from_chain: str = Query(..., description="Source chain"),
    to_chain: str = Query(..., description="Destination chain"),
    amount: str = Query(..., description="Amount to swap"),
    from_token: Optional[str] = Query(None, description="Source token contract address"),
    to_token: Optional[str] = Query(None, description="Destination token contract address"),
    slippage: Optional[float] = Query(1.0, description="Slippage tolerance percent", ge=0, le=100),
):
    """Get a swap quote without executing — shows estimated output, fees, and provider."""
    args = ["swap-quote", from_chain, to_chain, amount]
    if from_token:
        args.extend(["--from-token", from_token])
    if to_token:
        args.extend(["--to-token", to_token])
    if slippage is not None:
        args.extend(["--slippage", str(slippage)])

    result = vultisig(*args)
    return _data(result)


# ── Transaction Status ──────────────────────────────────────────────────

@router.get("/tx-status")
def get_tx_status(
    chain: str = Query(..., description="Chain where the tx was broadcast"),
    tx_id: str = Query(..., description="Transaction hash / ID"),
):
    """Check the status of a transaction (polls until confirmed)."""
    result = vultisig("tx-status", chain, tx_id)
    return _data(result)


# ── Vault Management ────────────────────────────────────────────────────

@router.get("/vaults")
def list_vaults():
    """List all stored vaults."""
    result = vultisig("vaults")
    return _data(result)


@router.post("/vaults/switch")
def switch_vault(vault_id: str = Query(..., description="Vault ID to switch to")):
    """Switch the active vault."""
    result = vultisig("switch", vault_id)
    return {"success": True, "activeVaultId": vault_id}
